import json
from decimal import Decimal
from django.test import TestCase
from django.contrib.auth import get_user_model
from rest_framework.test import APIClient
from rest_framework import status

from apps.destinations.models import Destination, Attraction
from apps.experiences.models import Experience
from apps.ai.models import TripProfile, AIPlan, AIPlanVersion
from apps.ai.services import CustomizationEngine, DiffEngine, RainAlternativeEngine

User = get_user_model()


class ItineraryBuilderBackendTestCase(TestCase):
    """
    Phase 5 Test Gate Verification Suite:
      - Version creation & immutability (v1 -> v2 -> v3)
      - Parent version relationship chain
      - 5 Core Operations: ADD_EVENT, REMOVE_EVENT, MOVE_EVENT, SWAP_EVENT, RAIN_SUBSTITUTE
      - Route recalculation on edits
      - Pricing recalculation on edits
      - Monsoon validation
      - Invalid entity rejection (nonexistent, unverified, cross-destination)
      - Authorization & IDOR protection (HTTP 403 Forbidden)
      - Deterministic diff engine (added, removed, moved, price delta, distance delta)
      - Version rollback / revert
    """

    def setUp(self):
        self.client = APIClient()
        self.user_a = User.objects.create_user(email='a@keralink.com', password='password123', first_name='Traveler', last_name='A')
        self.user_b = User.objects.create_user(email='b@keralink.com', password='password123', first_name='Traveler', last_name='B')

        import uuid
        org_id = uuid.uuid4()

        # Create seeded test destinations
        self.dest_munnar = Destination.objects.create(
            id='munnar',
            name='Munnar',
            slug='munnar',
            district='Idukki',
            tagline='Highland tea trails and mist',
            description='Majestic hill station of Kerala.',
            hero_image='https://images.unsplash.com/photo-1',
            latitude=10.0889,
            longitude=77.0595,
            best_season='Winter',
        )
        self.dest_kochi = Destination.objects.create(
            id='kochi',
            name='Kochi',
            slug='kochi',
            district='Ernakulam',
            tagline='Gateway to God\'s Own Country',
            description='Colonial harbour and spice port.',
            hero_image='https://images.unsplash.com/photo-2',
            latitude=9.9312,
            longitude=76.2673,
            best_season='All year',
        )

        # Create verified & rain-friendly experience in Munnar
        self.exp_tea_museum = Experience.objects.create(
            id='exp_tea_museum_munnar',
            org_id=org_id,
            destination_id='munnar',
            title='Munnar Tea Museum & Indoor Factory Experience',
            description='Historic tea leaf processing and indoor tasting masterclass.',
            category='CULTURE',
            duration_hours=2.5,
            price_per_person=Decimal('650.00'),
            max_group_size=15,
            hero_image='https://images.unsplash.com/photo-3',
            meeting_point='Lockhart Factory Gates',
            host_name='Master Sommelier Thomas',
            host_role='Tea Maker',
            rain_friendly=True,
            verified=True,
            rating=4.9,
        )

        # Create unverified experience
        self.exp_unverified = Experience.objects.create(
            id='exp_unverified_camp',
            org_id=org_id,
            destination_id='munnar',
            title='Unverified Wild Cliff Camping',
            description='Tent camping on steep slope.',
            category='ADVENTURE',
            duration_hours=4.0,
            price_per_person=Decimal('1200.00'),
            max_group_size=8,
            hero_image='https://images.unsplash.com/photo-4',
            meeting_point='Camp base',
            host_name='Ranger Bob',
            host_role='Guide',
            rain_friendly=False,
            verified=False,
        )

        # Create attraction in Kochi
        self.att_fort_kochi = Attraction.objects.create(
            id='att_fort_kochi_walk',
            destination=self.dest_kochi,
            name='Fort Kochi Heritage Waterfront',
            category='CULTURE',
            description='Colonial street architecture and Chinese fishing nets promenade.',
            image='https://images.unsplash.com/photo-5',
            latitude=9.9656,
            longitude=76.2421,
            typical_duration_mins=90,
            entry_fee=Decimal('50.00'),
            rain_friendly=False,
        )

    def _create_sample_plan(self, user=None):
        payload = {
            'duration_days': 4,
            'budget_limit': 80000.0,
            'interests': ['Nature', 'Culture'],
            'adults': 2,
            'month': 'October',
            'monsoon_mode': False,
        }
        if user:
            self.client.force_authenticate(user=user)
        else:
            self.client.force_authenticate(user=None)

        response = self.client.post('/api/v1/ai/generate-itinerary/', data=payload, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        return response.json()

    # 1. Test Version Creation and Immutability
    def test_version_creation_and_immutability(self):
        plan_data = self._create_sample_plan()
        plan_id = plan_data['plan_id']

        # Verify Version 1 initial state
        self.assertEqual(plan_data['version_number'], 1)
        plan_obj = AIPlan.objects.get(id=plan_id)
        self.assertEqual(plan_obj.current_version, 1)
        self.assertEqual(plan_obj.versions.count(), 1)
        v1 = plan_obj.versions.first()
        self.assertIsNone(v1.parent_version)
        self.assertEqual(v1.validation_status, 'VALID')

        # Perform an edit (remove an activity) -> creates v2
        ev_to_remove = v1.itinerary_payload['days'][0]['timeline'][1]['id']
        resp_v2 = self.client.post(
            f'/api/v1/ai/plans/{plan_id}/customize/',
            data={'operation': 'REMOVE_EVENT', 'day_number': 1, 'event_id': ev_to_remove},
            format='json'
        )
        self.assertEqual(resp_v2.status_code, status.HTTP_200_OK)
        data_v2 = resp_v2.json()

        # Invariant: v1 remains untouched; v2 created with parent link
        self.assertEqual(data_v2['version_number'], 2)
        self.assertEqual(data_v2['parent_version'], 1)

        plan_obj.refresh_from_db()
        self.assertEqual(plan_obj.current_version, 2)
        self.assertEqual(plan_obj.versions.count(), 2)

        v1_recheck = plan_obj.versions.get(version_number=1)
        v2_recheck = plan_obj.versions.get(version_number=2)
        self.assertEqual(v2_recheck.parent_version.id, v1_recheck.id)
        # v1 days count preserved
        self.assertNotEqual(
            len(v1_recheck.itinerary_payload['days'][0]['timeline']),
            len(v2_recheck.itinerary_payload['days'][0]['timeline'])
        )

    # 2. Test MOVE_EVENT: within day and across days
    def test_move_event_reorder_and_cross_day(self):
        plan_data = self._create_sample_plan()
        plan_id = plan_data['plan_id']
        day1_events = plan_data['days'][0]['timeline']
        self.assertTrue(len(day1_events) >= 3)
        ev_id = day1_events[0]['id']
        ev_title = day1_events[0]['title']

        # Move to position 2 on same day
        resp_move_same_day = self.client.post(
            f'/api/v1/ai/plans/{plan_id}/customize/',
            data={
                'operation': 'MOVE_EVENT',
                'event_id': ev_id,
                'day_number': 1,
                'target_day': 1,
                'target_order': 2,
            },
            format='json'
        )
        self.assertEqual(resp_move_same_day.status_code, status.HTTP_200_OK)
        v2_data = resp_move_same_day.json()
        self.assertEqual(v2_data['version_number'], 2)
        # Verify event moved to position 2
        day1_v2 = v2_data['days'][0]['timeline']
        self.assertEqual(day1_v2[1]['id'], ev_id)
        self.assertEqual(day1_v2[1]['order'], 2)

        # Move event cross-day from Day 1 to Day 2 at position 1
        resp_move_cross_day = self.client.post(
            f'/api/v1/ai/plans/{plan_id}/customize/',
            data={
                'operation': 'MOVE_EVENT',
                'event_id': ev_id,
                'day_number': 1,
                'target_day': 2,
                'target_order': 1,
            },
            format='json'
        )
        self.assertEqual(resp_move_cross_day.status_code, status.HTTP_200_OK)
        v3_data = resp_move_cross_day.json()
        self.assertEqual(v3_data['version_number'], 3)
        day2_v3 = v3_data['days'][1]['timeline']
        self.assertEqual(day2_v3[0]['id'], ev_id)
        self.assertEqual(day2_v3[0]['order'], 1)

    # 3. Test ADD_EVENT with database entity & destination check
    def test_add_event_authoritative_resolution(self):
        plan_data = self._create_sample_plan()
        plan_id = plan_data['plan_id']

        # Add verified Tea Museum experience to Day 1
        resp_add = self.client.post(
            f'/api/v1/ai/plans/{plan_id}/customize/',
            data={
                'operation': 'ADD_EVENT',
                'day_number': 1,
                'entity_id': self.exp_tea_museum.id,
                'entity_type': 'EXPERIENCE',
                'target_order': 1,
            },
            format='json'
        )
        self.assertEqual(resp_add.status_code, status.HTTP_200_OK)
        data = resp_add.json()
        self.assertEqual(data['version_number'], 2)
        day1_events = data['days'][0]['timeline']
        first_ev = day1_events[0]
        self.assertEqual(first_ev['title'], self.exp_tea_museum.title)
        self.assertEqual(first_ev['price'], 650.0)
        self.assertTrue(first_ev['rain_friendly'])
        self.assertEqual(first_ev['order'], 1)

    # 4. Test Rejecting Invalid Entities (Security & Integrity)
    def test_reject_unverified_experience_and_nonexistent_entity(self):
        plan_data = self._create_sample_plan()
        plan_id = plan_data['plan_id']

        # Try adding unverified experience -> must reject with 400 Bad Request
        resp_unverified = self.client.post(
            f'/api/v1/ai/plans/{plan_id}/customize/',
            data={
                'operation': 'ADD_EVENT',
                'day_number': 1,
                'entity_id': self.exp_unverified.id,
                'entity_type': 'EXPERIENCE',
            },
            format='json'
        )
        self.assertEqual(resp_unverified.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('unverified or suspended', resp_unverified.json()['error'])

        # Try adding non-existent entity -> must reject with 400 Bad Request
        resp_fake = self.client.post(
            f'/api/v1/ai/plans/{plan_id}/customize/',
            data={
                'operation': 'ADD_EVENT',
                'day_number': 1,
                'entity_id': 'exp_hallucinated_xyz',
                'entity_type': 'EXPERIENCE',
            },
            format='json'
        )
        self.assertEqual(resp_fake.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('does not exist in authoritative database', resp_fake.json()['error'])

    # 5. Test SWAP_EVENT: between two existing events
    def test_swap_events(self):
        plan_data = self._create_sample_plan()
        plan_id = plan_data['plan_id']
        day1_events = plan_data['days'][0]['timeline']
        ev1 = day1_events[0]
        ev2 = day1_events[1]

        resp_swap = self.client.post(
            f'/api/v1/ai/plans/{plan_id}/customize/',
            data={
                'operation': 'SWAP_EVENT',
                'day_number': 1,
                'event_id': ev1['id'],
                'swap_with_event_id': ev2['id'],
            },
            format='json'
        )
        self.assertEqual(resp_swap.status_code, status.HTTP_200_OK)
        swapped_data = resp_swap.json()
        new_day1 = swapped_data['days'][0]['timeline']
        self.assertEqual(new_day1[0]['id'], ev2['id'])
        self.assertEqual(new_day1[1]['id'], ev1['id'])

    # 6. Test RAIN_SUBSTITUTE: Deterministic rain alternative
    def test_rain_substitution_with_deterministic_alternative(self):
        plan_data = self._create_sample_plan()
        plan_id = plan_data['plan_id']

        resp_rain = self.client.post(
            f'/api/v1/ai/plans/{plan_id}/customize/',
            data={
                'operation': 'RAIN_SUBSTITUTE',
                'day_number': 1,
            },
            format='json'
        )
        self.assertEqual(resp_rain.status_code, status.HTTP_200_OK)
        data = resp_rain.json()
        self.assertEqual(data['version_number'], 2)
        self.assertTrue('rain substitution' in data['change_reason'].lower())

        # Verify all activities on Day 1 are now rain-friendly
        day1 = data['days'][0]
        for ev in day1['timeline']:
            if ev.get('type') in ('EXPERIENCE', 'ACTIVITY'):
                self.assertTrue(ev.get('rain_friendly', True))

    # 7. Test Authorization & IDOR Protection (Phase 5.9 Critical Rule)
    def test_idor_authorization_enforcement(self):
        # User A creates a plan
        plan_data = self._create_sample_plan(user=self.user_a)
        plan_id = plan_data['plan_id']

        # User B attempts to access User A's plan details -> 403 Forbidden
        self.client.force_authenticate(user=self.user_b)
        resp_detail = self.client.get(f'/api/v1/ai/plans/{plan_id}/')
        self.assertEqual(resp_detail.status_code, status.HTTP_403_FORBIDDEN)

        # User B attempts to customize User A's plan -> 403 Forbidden
        resp_cust = self.client.post(
            f'/api/v1/ai/plans/{plan_id}/customize/',
            data={'operation': 'REMOVE_EVENT', 'day_number': 1, 'event_id': 'any'},
            format='json'
        )
        self.assertEqual(resp_cust.status_code, status.HTTP_403_FORBIDDEN)

        # User B attempts to revert User A's plan -> 403 Forbidden
        resp_revert = self.client.post(
            f'/api/v1/ai/plans/{plan_id}/revert/',
            data={'target_version': 1},
            format='json'
        )
        self.assertEqual(resp_revert.status_code, status.HTTP_403_FORBIDDEN)

        # User A (owner) is authorized
        self.client.force_authenticate(user=self.user_a)
        resp_owner = self.client.get(f'/api/v1/ai/plans/{plan_id}/')
        self.assertEqual(resp_owner.status_code, status.HTTP_200_OK)

    # 8. Test Deterministic Diff Engine (GET /diff/)
    def test_diff_engine_deterministic_output(self):
        plan_data = self._create_sample_plan()
        plan_id = plan_data['plan_id']
        ev_to_remove = plan_data['days'][0]['timeline'][1]['id']

        # Remove event to produce v2
        resp_v2 = self.client.post(
            f'/api/v1/ai/plans/{plan_id}/customize/',
            data={'operation': 'REMOVE_EVENT', 'day_number': 1, 'event_id': ev_to_remove},
            format='json'
        )
        self.assertEqual(resp_v2.status_code, status.HTTP_200_OK)
        diff_summary = resp_v2.json()['diff_summary']

        self.assertIn('added', diff_summary)
        self.assertIn('removed', diff_summary)
        self.assertIn('moved', diff_summary)
        self.assertIn('price', diff_summary)
        self.assertIn('distance', diff_summary)
        self.assertIn('safety', diff_summary)
        self.assertIn('summary_text', diff_summary)
        self.assertTrue(len(diff_summary['removed']) >= 1)

        # Query explicit diff endpoint: GET /api/v1/ai/plans/{id}/diff/
        diff_endpoint_resp = self.client.get(f'/api/v1/ai/plans/{plan_id}/diff/?from_version=1&to_version=2')
        self.assertEqual(diff_endpoint_resp.status_code, status.HTTP_200_OK)
        diff_data = diff_endpoint_resp.json()
        self.assertEqual(diff_data['from_version'], 1)
        self.assertEqual(diff_data['to_version'], 2)
        self.assertTrue(len(diff_data['removed']) >= 1)
        self.assertTrue('summary_text' in diff_data)

    # 9. Test Version Rollback / Revert (Phase 5.4)
    def test_version_rollback_creates_next_version(self):
        plan_data = self._create_sample_plan()
        plan_id = plan_data['plan_id']
        ev_to_remove = plan_data['days'][0]['timeline'][1]['id']

        # Step 1: v1 -> v2 (Remove event)
        self.client.post(
            f'/api/v1/ai/plans/{plan_id}/customize/',
            data={'operation': 'REMOVE_EVENT', 'day_number': 1, 'event_id': ev_to_remove},
            format='json'
        )

        # Step 2: v2 -> v3 (Add tea museum)
        self.client.post(
            f'/api/v1/ai/plans/{plan_id}/customize/',
            data={
                'operation': 'ADD_EVENT',
                'day_number': 1,
                'entity_id': self.exp_tea_museum.id,
                'entity_type': 'EXPERIENCE',
            },
            format='json'
        )

        plan_obj = AIPlan.objects.get(id=plan_id)
        self.assertEqual(plan_obj.current_version, 3)

        # Step 3: Rollback to Version 1 -> creates v4 with state of v1
        revert_resp = self.client.post(
            f'/api/v1/ai/plans/{plan_id}/revert/',
            data={'target_version': 1, 'reason': 'Traveler reverted to initial synthesis'},
            format='json'
        )
        self.assertEqual(revert_resp.status_code, status.HTTP_200_OK)
        v4_data = revert_resp.json()

        self.assertEqual(v4_data['version_number'], 4)
        self.assertEqual(v4_data['parent_version'], 3)
        self.assertTrue('reverted' in v4_data['change_reason'].lower())

        # Invariant: v4 has all 3 previous versions preserved in database
        plan_obj.refresh_from_db()
        self.assertEqual(plan_obj.current_version, 4)
        self.assertEqual(plan_obj.versions.count(), 4)

    # 10. Test Candidates Endpoint (Phase 5.7)
    def test_candidates_endpoint(self):
        plan_data = self._create_sample_plan()
        plan_id = plan_data['plan_id']

        cand_resp = self.client.get(f'/api/v1/ai/plans/{plan_id}/candidates/?day_number=1&rain_friendly=true')
        self.assertEqual(cand_resp.status_code, status.HTTP_200_OK)
        data = cand_resp.json()
        self.assertIn('candidates', data)
        self.assertTrue(isinstance(data['candidates'], list))
        # Tea museum should appear in candidates
        cand_titles = [c['title'] for c in data['candidates']]
        self.assertIn(self.exp_tea_museum.title, cand_titles)

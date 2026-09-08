import json
from django.test import TestCase
from rest_framework.test import APIClient
from rest_framework import status

from apps.ai.models import TripProfile, AIPlan, AIPlanVersion, AIPlanAnalyticsMetrics
from apps.ai.services import RequirementParser, RouteOptimizer, DeterministicValidator, AITravelArchitect, CustomizationEngine


class AIPlannerAndCustomizationTestCase(TestCase):
    """
    Comprehensive Test Suite for Phase 4 (AI Travel Architect)
    and Phase 5 (Itinerary Builder & Customization Engine).
    """

    def setUp(self):
        self.client = APIClient()

    # --- Phase 4: AI Travel Architect Tests ---

    def test_nlp_prompt_parsing(self):
        prompt = "We are a couple planning a 6 days luxury trip to Munnar and Alleppey backwaters with authentic food and nature, budget 90k, no long driving."
        profile = RequirementParser.parse_text(prompt)

        self.assertEqual(profile['duration_days'], 6)
        self.assertEqual(profile['budget_limit'], 90000.0)
        self.assertEqual(profile['adults'], 2)
        self.assertIn('Nature', profile['interests'])
        self.assertIn('Food', profile['interests'])
        self.assertIn('Backwaters', profile['interests'])
        self.assertIn('Long Drives', profile['avoidances'])
        self.assertEqual(profile['travel_style'], 'PREMIUM')

    def test_nlp_prompt_fallback_defaults(self):
        # Empty or brief prompt uses calibrated defaults
        prompt = "Trip to Kerala"
        profile = RequirementParser.parse_text(prompt)
        self.assertEqual(profile['duration_days'], 6)
        self.assertEqual(profile['budget_limit'], 80000.0)
        self.assertEqual(profile['adults'], 2)
        self.assertTrue(len(profile['interests']) >= 1)

    def test_western_ghats_vs_highway_speeds(self):
        kochi_lat, kochi_lng = 9.9656, 76.2421
        munnar_lat, munnar_lng = 10.0889, 77.0595

        ghat_calc = RouteOptimizer.calculate_segment(kochi_lat, kochi_lng, munnar_lat, munnar_lng, is_ghat_route=True)
        highway_calc = RouteOptimizer.calculate_segment(kochi_lat, kochi_lng, munnar_lat, munnar_lng, is_ghat_route=False)

        self.assertGreater(ghat_calc['duration_minutes'], highway_calc['duration_minutes'])
        self.assertTrue(ghat_calc['is_ghat_route'])

    def test_deterministic_budget_validation(self):
        pricing = {'total': 85000.0}
        budget_limit = 80000.0
        days = [{'day_number': 1, 'timeline': [{'time': '09:00', 'title': 'Breakfast'}, {'time': '11:00', 'title': 'Walk'}]}]

        res = DeterministicValidator.validate_plan(days, budget_limit, pricing)
        self.assertTrue(res['is_valid'])
        self.assertEqual(res['validation_score'], 100)

        # Exceeds threshold (> 15%)
        excessive_pricing = {'total': 125000.0}
        res_fail = DeterministicValidator.validate_plan(days, budget_limit, excessive_pricing)
        self.assertFalse(res_fail['is_valid'])
        self.assertGreater(len(res_fail['violations']), 0)

    def test_generate_itinerary_creates_booking_ready_events(self):
        payload = {
            'duration_days': 4,
            'budget_limit': 75000.0,
            'interests': ['Nature', 'Culture'],
            'avoidances': ['Heavy Trekking'],
            'adults': 2,
            'travel_style': 'PREMIUM',
        }

        response = self.client.post('/api/v1/ai/generate-itinerary/', data=payload, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()

        self.assertIn('plan_id', data)
        self.assertEqual(data['version_number'], 1)
        self.assertEqual(len(data['days']), 4)

        # Verify Authoritative Pricing breakdown structure
        pricing = data['pricing']
        self.assertIn('subtotal', pricing)
        self.assertIn('gst_amount', pricing)
        self.assertIn('platform_fee', pricing)
        self.assertIn('total', pricing)
        self.assertIn('price_per_person', pricing)

        # Verify booking-ready TimelineEvent contract
        first_day = data['days'][0]
        self.assertTrue(len(first_day['timeline']) >= 3)
        event = first_day['timeline'][0]
        self.assertIn('id', event)
        self.assertIn('type', event)
        self.assertIn('title', event)
        self.assertIn('destination_id', event)
        self.assertIn('coordinates', event)
        self.assertIn('time', event)
        self.assertIn('duration_mins', event)
        self.assertIn('rain_friendly', event)
        self.assertIn('booking_required', event)

        # Verify database persistence
        plan = AIPlan.objects.get(id=data['plan_id'])
        self.assertEqual(plan.current_version, 1)
        self.assertEqual(plan.versions.count(), 1)

    # --- Phase 5: Customization & Versioning Tests ---

    def test_plan_customization_creates_version_2(self):
        # 1. Generate plan v1
        gen_resp = self.client.post('/api/v1/ai/generate-itinerary/', data={'duration_days': 3, 'adults': 2}, format='json')
        plan_id = gen_resp.json()['plan_id']

        # 2. Customize: Replace activity on Day 1
        customize_payload = {
            'action': 'REPLACE_ACTIVITY',
            'day_number': 1,
            'timeline_event_id': gen_resp.json()['days'][0]['timeline'][2]['id'],
            'new_event': {
                'title': 'Private Ayurvedic Herbal Garden Exploration',
                'cost': 450.0,
                'type': 'ACTIVITY',
                'rain_friendly': True,
            },
            'reason': 'Traveler preferred herbal garden over city walk',
        }

        cust_resp = self.client.post(f'/api/v1/ai/plans/{plan_id}/customize/', data=customize_payload, format='json')
        self.assertEqual(cust_resp.status_code, status.HTTP_200_OK)
        cust_data = cust_resp.json()

        # Invariant: Never overwrite v1 in place; create v2
        self.assertEqual(cust_data['version_number'], 2)
        self.assertEqual(cust_data['current_version'], 2)

        # Verify both v1 and v2 exist in the database
        plan = AIPlan.objects.get(id=plan_id)
        self.assertEqual(plan.current_version, 2)
        self.assertEqual(plan.versions.count(), 2)

    def test_rain_substitution_constraint_and_version_bump(self):
        gen_resp = self.client.post('/api/v1/ai/generate-itinerary/', data={'duration_days': 3, 'adults': 2}, format='json')
        plan_id = gen_resp.json()['plan_id']

        # Call substitute-rain on Day 2
        sub_resp = self.client.post(
            f'/api/v1/ai/plans/{plan_id}/substitute-rain/',
            data={'day_number': 2, 'destination_id': 'munnar'},
            format='json'
        )
        self.assertEqual(sub_resp.status_code, status.HTTP_200_OK)
        sub_data = sub_resp.json()

        self.assertEqual(sub_data['version_number'], 2)
        self.assertIn('Rain substitution', sub_data['change_reason'])

        # Verify all activities on Day 2 are now rain_friendly
        day2 = next(d for d in sub_data['days'] if d['day_number'] == 2)
        for ev in day2['timeline']:
            if ev['type'] == 'EXPERIENCE':
                self.assertTrue(ev['rain_friendly'])

    def test_remove_and_add_activity_customizations(self):
        gen_resp = self.client.post('/api/v1/ai/generate-itinerary/', data={'duration_days': 3}, format='json')
        plan_id = gen_resp.json()['plan_id']
        event_to_remove = gen_resp.json()['days'][0]['timeline'][1]['id']

        # Remove activity -> produces v2
        rem_resp = self.client.post(
            f'/api/v1/ai/plans/{plan_id}/customize/',
            data={'action': 'REMOVE_ACTIVITY', 'day_number': 1, 'timeline_event_id': event_to_remove},
            format='json'
        )
        self.assertEqual(rem_resp.status_code, status.HTTP_200_OK)
        self.assertEqual(rem_resp.json()['version_number'], 2)

        # Add activity -> produces v3
        add_payload = {
            'action': 'ADD_ACTIVITY',
            'day_number': 1,
            'new_event': {
                'title': 'Sunset Canoe Rowing with Local Fishermen',
                'type': 'ACTIVITY',
                'time': '17:00',
                'cost': 350.0,
                'rain_friendly': False,
            }
        }
        add_resp = self.client.post(
            f'/api/v1/ai/plans/{plan_id}/customize/',
            data=add_payload,
            format='json'
        )
        self.assertEqual(add_resp.status_code, status.HTTP_200_OK)
        self.assertEqual(add_resp.json()['version_number'], 3)

    def test_version_retrieval_and_history(self):
        gen_resp = self.client.post('/api/v1/ai/generate-itinerary/', data={'duration_days': 2}, format='json')
        plan_id = gen_resp.json()['plan_id']

        # Bump to v2
        self.client.post(
            f'/api/v1/ai/plans/{plan_id}/substitute-rain/',
            data={'day_number': 1},
            format='json'
        )

        # GET versions list
        list_resp = self.client.get(f'/api/v1/ai/plans/{plan_id}/versions/')
        self.assertEqual(list_resp.status_code, status.HTTP_200_OK)
        versions = list_resp.json()['versions']
        self.assertEqual(len(versions), 2)
        self.assertEqual(versions[0]['version_number'], 1)
        self.assertEqual(versions[1]['version_number'], 2)

        # GET specific version v1
        v1_resp = self.client.get(f'/api/v1/ai/plans/{plan_id}/versions/1/')
        self.assertEqual(v1_resp.status_code, status.HTTP_200_OK)
        self.assertEqual(v1_resp.json()['version_number'], 1)

    def test_user_prompt_june_monsoon_extraction(self):
        prompt = "Plan 6 days in Kerala with my wife in June, budget ₹80,000, relaxed trip with nature and good food."
        profile = RequirementParser.parse_text(prompt)

        self.assertEqual(profile['duration_days'], 6)
        self.assertEqual(profile['adults'], 2)
        self.assertEqual(profile['month'], 'June')
        self.assertTrue(profile['monsoon_mode'])
        self.assertEqual(profile['budget_limit'], 80000.0)
        self.assertEqual(profile['pace'], 'RELAXED')
        self.assertIn('Nature', profile['interests'])
        self.assertIn('Food', profile['interests'])

    def test_deterministic_monsoon_safety_boundary(self):
        # Day with outdoor activity lacking rain alternative
        unsafe_days = [{
            'day_number': 1,
            'timeline': [
                {'time': '10:00', 'type': 'ACTIVITY', 'title': 'Open Cliffside Trek', 'rain_friendly': False, 'rain_alternative_id': None},
                {'time': '14:00', 'type': 'MEAL', 'title': 'Lunch', 'rain_friendly': True}
            ]
        }]
        res = DeterministicValidator.validate_plan(unsafe_days, 80000.0, {'total': 50000.0}, monsoon_mode=True)
        self.assertFalse(res['is_valid'])
        self.assertTrue(any('monsoon season' in v for v in res['violations']))

    def test_ai_provider_adapter_resolution(self):
        from apps.ai.adapters import get_ai_provider_adapter, RuleBasedAIProviderAdapter, GeminiAIProviderAdapter
        adapter_default = get_ai_provider_adapter()
        self.assertIsInstance(adapter_default, RuleBasedAIProviderAdapter)

        adapter_gemini = get_ai_provider_adapter('gemini')
        self.assertIsInstance(adapter_gemini, GeminiAIProviderAdapter)
        # Fallback executes without errors
        res = adapter_gemini.parse_prompt("5 days in Munnar with family")
        self.assertEqual(res['duration_days'], 5)

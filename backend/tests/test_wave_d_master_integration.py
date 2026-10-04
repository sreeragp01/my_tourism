import datetime
from django.test import TestCase
from django.contrib.auth import get_user_model
from django.utils import timezone
from rest_framework.test import APIClient
from rest_framework import status

from apps.bookings.models import Booking, BookingItem
from apps.safety.models import TripShareToken, SafetyAlert
from apps.safety.services import SafetyService
from apps.notifications.models import Notification, NotificationPreference, ProximityEvent
from apps.notifications.services import NotificationService, ProximityEngine
from apps.location.models import TravelerLocation
from apps.weather.services import MonsoonRiskEngine, TravelWeatherValidator, WeatherService
from apps.companion.services import AICompanionOrchestrator

User = get_user_model()


class WaveDMasterIntegrationTestCase(TestCase):
    """
    Wave D Master Integration Test Suite: Live Trip Experience Engine.
    Executes end-to-end integration tests across Phases 10-14 and validates:
    - Shared Trip Context API
    - Location Ingestion & Routing
    - Weather & Monsoon Intelligence
    - AI Companion Gated Execution Layer
    - Safety, Emergency SOS & Sanitized Public Trip Sharing
    - Proximity Engine with 30-min Cooldown & Notification Preferences
    """

    def setUp(self):
        self.client = APIClient()

        # Primary traveler (User A)
        self.user_a = User.objects.create_user(
            email='traveler.a@keralink.org',
            password='TestPassword123!',
            first_name='Sreerag',
            last_name='P'
        )

        # Other traveler (User B) for multi-tenant isolation tests
        self.user_b = User.objects.create_user(
            email='traveler.b@keralink.org',
            password='TestPassword123!',
            first_name='Unauthorized',
            last_name='Guest'
        )

        # Primary confirmed booking for User A
        self.booking_a = Booking.objects.create(
            user=self.user_a,
            booking_reference='KL2609071234',
            trip_title='6 Days Romantic Munnar & Backwater Odyssey',
            status='CONFIRMED',
            start_date=datetime.date(2026, 10, 15),
            end_date=datetime.date(2026, 10, 20),
            primary_guest_name='Sreerag P',
            primary_guest_email='traveler.a@keralink.org',
            primary_guest_phone='+91 98470 54321',
            travelers_count=2,
            subtotal=17500.0,
            tax=875.0,
            platform_fee=350.0,
            total_amount=18725.0,
            currency='INR',
            green_trip_score=92,
            idempotency_key='test-idemp-key-wave-d-1'
        )

        self.item_a1 = BookingItem.objects.create(
            booking=self.booking_a,
            item_type='EXPERIENCE',
            title='Lockhart Tea Tasting & Cupping Masterclass',
            date=datetime.date(2026, 10, 16),
            quantity=2,
            unit_price=1200.0,
            subtotal=2400.0,
            total_price=2400.0,
        )

    # =========================================================================
    # 1. SHARED TRIP CONTEXT & MULTI-TENANT ISOLATION
    # =========================================================================
    def test_shared_trip_context_aggregation(self):
        """Validates that GET /api/v1/trips/<ref>/context/ aggregates all authoritative live state."""
        self.client.force_authenticate(user=self.user_a)
        url = f"/api/v1/trips/{self.booking_a.booking_reference}/context/"
        response = self.client.get(url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.data

        # Booking details
        self.assertEqual(data['booking']['reference'], 'KL2609071234')
        self.assertEqual(data['booking']['status'], 'CONFIRMED')
        self.assertEqual(data['booking']['green_trip_score'], 92)

        # Location fallback or live coordinates
        self.assertIn('latitude', data['current_location'])
        self.assertIn('longitude', data['current_location'])
        self.assertIn('landmark', data['current_location'])

        # Meteorological intelligence
        self.assertIn('current_weather', data)
        self.assertIn('temperature_celsius', data['current_weather'])
        self.assertIn('risk', data['current_weather'])

        # Next milestone
        self.assertEqual(data['next_event']['title'], 'Lockhart Tea Tasting & Cupping Masterclass')

        # Driver details
        self.assertEqual(data['driver']['driver_name'], 'Rajesh Kumar')
        self.assertIn('phone', data['driver'])

        # Emergency directory
        self.assertTrue(len(data['safety']['emergency_numbers']) >= 2)

        # Deterministic cache hash
        self.assertIn('offline_cache_hash', data)
        self.assertEqual(len(data['offline_cache_hash']), 64)

    def test_shared_trip_context_multi_tenant_security(self):
        """User B cannot view User A's live trip context."""
        self.client.force_authenticate(user=self.user_b)
        url = f"/api/v1/trips/{self.booking_a.booking_reference}/context/"
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    # =========================================================================
    # 2. PHASE 10: LOCATION & MAPS
    # =========================================================================
    def test_location_update_ingestion(self):
        """Traveler GPS coordinates are ingested, validated, and stored."""
        self.client.force_authenticate(user=self.user_a)
        url = "/api/v1/location/update/"
        payload = {
            'latitude': 10.0889,
            'longitude': 77.0595,
            'accuracy': 8.5,
            'speed': 32.0,
            'heading': 180.0,
            'booking_reference': self.booking_a.booking_reference
        }
        response = self.client.post(url, payload, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['latitude'], 10.0889)

        loc_count = TravelerLocation.objects.filter(user=self.user_a).count()
        self.assertEqual(loc_count, 1)

    def test_route_calculation_with_ghat_advisories(self):
        """Route calculation to Munnar triggers Ghat mountain fog and speed advisories."""
        url = "/api/v1/maps/route/"
        params = {
            'start_lat': 10.1518,
            'start_lon': 76.3930,
            'end_lat': 10.0889,
            'end_lon': 77.0595
        }
        response = self.client.get(url, params)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.data['is_ghat_road'])
        self.assertTrue(len(response.data['advisories']) >= 1)
        self.assertIn("30 km/h", response.data['advisories'][0])

    def test_nearby_experiences_search(self):
        """Nearby search returns verified spots ordered by distance."""
        url = "/api/v1/maps/nearby/"
        params = {
            'lat': 10.0889,
            'lon': 77.0595,
            'radius_km': 40.0
        }
        response = self.client.get(url, params)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('results', response.data)
        self.assertTrue(isinstance(response.data['results'], list))

    # =========================================================================
    # 3. PHASE 11: WEATHER & MONSOON INTELLIGENCE
    # =========================================================================
    def test_monsoon_risk_engine_ghat_vs_coastal(self):
        """Monsoon risk evaluates highland ghat roads more critically than coastal terrain."""
        ghat_risk = MonsoonRiskEngine.evaluate_risk(
            destination='munnar',
            rain_probability=80,
            is_ghat=True
        )
        self.assertEqual(ghat_risk['risk_level'], 'UNSAFE')
        self.assertEqual(ghat_risk['badge_color'], '#EF4444')
        self.assertTrue(ghat_risk['is_ghat_corridor'])

        coastal_risk = MonsoonRiskEngine.evaluate_risk(
            destination='kochi',
            rain_probability=30,
            is_ghat=False
        )
        self.assertEqual(coastal_risk['risk_level'], 'SAFE')
        self.assertEqual(coastal_risk['badge_color'], '#10B981')

    def test_activity_weather_validation_substitute(self):
        """Outdoor activities with high rain risk are automatically substituted with verified indoor activities."""
        val = TravelWeatherValidator.validate_activity(
            activity_type='TREKKING',
            destination_slug='munnar',
            rain_probability=75
        )
        self.assertEqual(val['status'], 'UNSAFE')
        self.assertTrue(val['requires_substitution'])
        self.assertIsNotNone(val['substitute'])
        self.assertTrue(val['substitute']['rain_friendly'])
        self.assertEqual(val['substitute']['category'], 'CULTURE')

    # =========================================================================
    # 4. PHASE 12: AI TRAVEL COMPANION GATED TOOL EXECUTION
    # =========================================================================
    def test_companion_tool_execution_pipeline(self):
        """Traveler queries execute strictly gated tools with zero hallucinated mutations."""
        # Query 1: Weather intent
        reply_weather = AICompanionOrchestrator.process_query(
            "What's the weather and rain status in Munnar?",
            destination_slug='munnar',
            user=self.user_a
        )
        self.assertEqual(reply_weather['tool_invoked'], 'get_weather')
        self.assertIn('19°C', reply_weather['content'])

        # Query 2: Driver intent
        reply_driver = AICompanionOrchestrator.process_query(
            "Can I have my driver contact and car status?",
            user=self.user_a
        )
        self.assertEqual(reply_driver['tool_invoked'], 'request_driver_contact')
        self.assertEqual(reply_driver['tool_result']['driver_name'], 'Rajesh Kumar')

        # Query 3: Emergency intent
        reply_sos = AICompanionOrchestrator.process_query(
            "Help! Need emergency police assistance immediately",
            user=self.user_a
        )
        self.assertEqual(reply_sos['tool_invoked'], 'emergency_safety_net')
        self.assertIn('1800-425-4747', reply_sos['content'])
        self.assertIn('112', reply_sos['content'])

    # =========================================================================
    # 5. PHASE 13: SAFETY & EMERGENCY SOS + PRIVACY-SAFE SHARING
    # =========================================================================
    def test_emergency_sos_dispatch(self):
        """Triggering SOS records a SafetyAlert and dispatches an immediate domain event."""
        self.client.force_authenticate(user=self.user_a)
        url = "/api/v1/safety/sos/"
        payload = {
            'booking_reference': self.booking_a.booking_reference,
            'latitude': 10.0889,
            'longitude': 77.0595,
            'location_name': 'Lockhart Tea Valley, Munnar',
            'alert_type': 'SOS_112',
            'notes': 'Traveler requested urgent medical response.'
        }
        response = self.client.post(url, payload, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['status'], 'TRIGGERED')

        alert_count = SafetyAlert.objects.filter(user=self.user_a, alert_type='SOS_112').count()
        self.assertEqual(alert_count, 1)

    def test_trip_share_token_lifecycle_and_sanitization(self):
        """Temporary trip share link is time-bound, revocable, and strictly scrubs traveler PII."""
        self.client.force_authenticate(user=self.user_a)

        # 1. Create Share Token
        create_url = "/api/v1/safety/share/"
        create_res = self.client.post(create_url, {
            'booking_reference': self.booking_a.booking_reference,
            'expiry_hours': 24
        }, format='json')
        self.assertEqual(create_res.status_code, status.HTTP_201_CREATED)
        token = create_res.data['token']

        # 2. Public view access without authentication
        public_client = APIClient()
        public_url = f"/api/v1/safety/shared/{token}/"
        public_res = public_client.get(public_url)
        self.assertEqual(public_res.status_code, status.HTTP_200_OK)

        data = public_res.data
        self.assertTrue(data['valid'])
        self.assertEqual(data['trip_title'], '6 Days Romantic Munnar & Backwater Odyssey')
        self.assertEqual(data['masked_reference'], 'KL***1234')

        # Verify strict privacy scrubbing (no PII, no email, no payment info)
        self.assertNotIn('traveler.a@keralink.org', str(data))
        self.assertNotIn('+91 98470 54321', str(data))
        self.assertNotIn('total_amount', data)
        self.assertNotIn('test-idemp-key', str(data))

        # 3. Revoke Share Token
        revoke_url = f"/api/v1/safety/share/{token}/revoke/"
        revoke_res = self.client.post(revoke_url, {}, format='json')
        self.assertEqual(revoke_res.status_code, status.HTTP_200_OK)
        self.assertTrue(revoke_res.data['revoked'])

        # 4. Public access after revocation returns 404 / invalid
        revoked_check_res = public_client.get(public_url)
        self.assertEqual(revoked_check_res.status_code, status.HTTP_404_NOT_FOUND)
        self.assertFalse(revoked_check_res.data['valid'])

    # =========================================================================
    # 6. PHASE 14: PROXIMITY ENGINE & NOTIFICATION PREFERENCES
    # =========================================================================
    def test_proximity_triggers_and_30min_cooldown(self):
        """Proximity engine triggers arrival (<=200m) and approach (<=500m) with 30-min deduplication."""
        # Setup waypoint exactly at (10.0889, 77.0595)
        waypoints = [
            {
                'id': 'wp_tea_factory',
                'name': 'Lockhart Tea Factory Gate',
                'latitude': 10.0889,
                'longitude': 77.0595
            }
        ]

        # 1. Traveler is 100 meters away -> triggers ARRIVAL_200M
        res1 = ProximityEngine.evaluate_proximity(
            user=self.user_a,
            current_lat=10.0895,
            current_lon=77.0595,
            waypoints=waypoints
        )
        self.assertEqual(len(res1['triggered_events']), 1)
        self.assertEqual(res1['triggered_events'][0]['event_type'], 'ARRIVAL_200M')

        # Verify Notification was created
        notif_count = Notification.objects.filter(user=self.user_a, notification_type='PROXIMITY').count()
        self.assertEqual(notif_count, 1)

        # 2. Immediate re-evaluation (within 30 mins) -> Cooldown prevents second alert
        res2 = ProximityEngine.evaluate_proximity(
            user=self.user_a,
            current_lat=10.0895,
            current_lon=77.0595,
            waypoints=waypoints
        )
        self.assertEqual(len(res2['triggered_events']), 0)
        notif_count_after = Notification.objects.filter(user=self.user_a, notification_type='PROXIMITY').count()
        self.assertEqual(notif_count_after, 1)

    def test_notification_preferences_suppression(self):
        """Disabling proximity notifications in preferences suppresses notifications."""
        prefs, _ = NotificationPreference.objects.get_or_create(user=self.user_a)
        prefs.proximity_enabled = False
        prefs.save()

        notif = NotificationService.send_notification(
            user=self.user_a,
            title='Suppressed Arrival',
            message='Should not be created because proximity is disabled',
            notification_type='PROXIMITY'
        )
        self.assertIsNone(notif)

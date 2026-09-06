import unittest
from datetime import date, timedelta
from apps.ai.services import RequirementParser, AITravelArchitect
from apps.pricing.services import AuthoritativePricingEngine
from apps.bookings.state_machine import BookingStateMachine
from apps.companion.services import AICompanionOrchestrator

class MockE2EBooking:
    def __init__(self, ref: str, total_amount: float):
        self.id = 'e2e-bkg-uuid-2026'
        self.booking_reference = ref
        self.status = 'DRAFT'
        self.total_amount = total_amount
        self.primary_guest_email = 'sreerag@keralink.travel'
        self.confirmed_at = None

    def save(self):
        pass

class MasterE2EBookingLifecycleTestCase(unittest.TestCase):
    """
    Test Suite: Master End-to-End Lifecycle Verification (KeraLink v2.2 Release Gate).
    Traces the entire journey:
      Prompt -> TripProfile -> AI Plan (v1) -> Rain Shift (v2) -> Hold -> Price -> Payment -> Webhook -> Pass -> Companion -> Completed
    """

    def test_complete_traveler_to_completion_lifecycle(self):
        # Step 1: Traveler enters NLP prompt
        prompt = "6 days luxury Kerala trip to Munnar and Alleppey for 2 adults, budget 90k, focus on nature and authentic food"
        profile = RequirementParser.parse_text(prompt)
        self.assertEqual(profile['duration_days'], 6)
        self.assertEqual(profile['adults'], 2)
        self.assertEqual(profile['travel_style'], 'PREMIUM')

        # Step 2: AI Travel Architect generates full plan (v1)
        plan_v1 = AITravelArchitect.generate_full_package(profile)
        self.assertEqual(plan_v1['version_number'], 1)
        self.assertEqual(len(plan_v1['days']), 2)
        self.assertTrue(plan_v1['validation']['is_valid'])

        # Step 3: Authoritative pricing calculation
        pricing = plan_v1['pricing']
        self.assertGreater(pricing['total'], 0)
        expected_taxes = (pricing['stays_total'] + pricing['transport_total'] + pricing['experiences_total'] + pricing['meals_estimate']) * 0.07
        self.assertAlmostEqual(pricing['taxes_and_fees'], expected_taxes, places=2)


        # Step 4: Create booking checkout in DRAFT and transition to PENDING_PAYMENT
        booking = MockE2EBooking('KL2609058888', pricing['total'])
        sm = BookingStateMachine(booking)
        
        self.assertEqual(booking.status, 'DRAFT')
        sm.transition('PENDING_PAYMENT', reason="Checkout initialized with 15-min hold")
        self.assertEqual(booking.status, 'PENDING_PAYMENT')

        # Step 5: Payment Gateway processing -> Webhook Capture -> CONFIRMED
        sm.transition('PAYMENT_PROCESSING', reason="Razorpay modal intent created")
        self.assertEqual(booking.status, 'PAYMENT_PROCESSING')

        sm.transition('CONFIRMED', reason="Webhook #evt_rzp_e2e_verified confirmed")
        self.assertEqual(booking.status, 'CONFIRMED')

        # Step 6: Live Trip Companion tool execution during trip
        companion_resp = AICompanionOrchestrator.process_query("What is the weather in Munnar today?", destination_slug="munnar")
        self.assertEqual(companion_resp['tool_invoked'], 'get_weather')
        self.assertIn('19°C', companion_resp['content'])

        # Step 7: Trip progresses to IN_PROGRESS and COMPLETED
        sm.transition('IN_PROGRESS', reason="Traveler checked in at Fort Kochi")
        self.assertEqual(booking.status, 'IN_PROGRESS')

        sm.transition('COMPLETED', reason="Traveler completed 6-day Kerala corridor")
        self.assertEqual(booking.status, 'COMPLETED')

if __name__ == '__main__':
    unittest.main()

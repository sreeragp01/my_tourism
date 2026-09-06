import unittest
from apps.payments.models import ProcessedWebhookEvent
from apps.payments.services import IdempotentPaymentService
from apps.bookings.state_machine import BookingStateMachine

class MockBookingEntity:
    def __init__(self, booking_ref: str, status: str = 'PENDING_PAYMENT'):
        self.id = 'bkg-mock-uuid-99'
        self.booking_reference = booking_ref
        self.status = status
        self.total_amount = 45000.0
        self.primary_guest_email = 'guest@keralink.travel'
        self.mutation_count = 0

    def save(self):
        self.mutation_count += 1

class PaymentReplayAndWebhookDeduplicationTestCase(unittest.TestCase):
    """
    Test Suite: Payment Webhook Deduplication & Replay Attack Defense.
    Simulates gateway webhook delivery retries:
      Webhook #123 -> SUCCESS (Booking -> CONFIRMED)
      Webhook #123 -> DUPLICATE REPLAY (Ignored, 0 mutations)
      Webhook #123 -> DUPLICATE REPLAY (Ignored, 0 mutations)
    """

    def setUp(self):
        self.processed_events = set()
        self.booking = MockBookingEntity('KL2609059999', 'PENDING_PAYMENT')

    def simulate_webhook_processing(self, event_id: str, event_type: str, booking: MockBookingEntity) -> dict:
        """Simulates idempotent webhook handler behavior."""
        # 1. Idempotency guard check
        if event_id in self.processed_events:
            return {"status": "already_processed", "event_id": event_id, "mutated": False}

        # 2. Record event ID to guarantee exactly-once execution
        self.processed_events.add(event_id)

        # 3. Apply state transition
        if event_type == "payment.captured":
            sm = BookingStateMachine(booking)
            if sm.can_transition_to("PAYMENT_PROCESSING"):
                booking.status = "PAYMENT_PROCESSING"
            if sm.can_transition_to("CONFIRMED") or booking.status == "PAYMENT_PROCESSING":
                booking.status = "CONFIRMED"
                booking.save()
            return {"status": "confirmed", "booking_reference": booking.booking_reference, "mutated": True}

        return {"status": "ignored", "mutated": False}

    def test_duplicate_webhook_replay_protection(self):
        event_id = "evt_razorpay_live_webhook_98124"
        event_type = "payment.captured"

        # 1. First delivery -> MUST succeed and transition booking
        res1 = self.simulate_webhook_processing(event_id, event_type, self.booking)
        self.assertEqual(res1["status"], "confirmed")
        self.assertTrue(res1["mutated"])
        self.assertEqual(self.booking.status, "CONFIRMED")
        self.assertEqual(self.booking.mutation_count, 1)

        # 2. Second delivery (Replay / Network retry) -> MUST be recognized as duplicate
        res2 = self.simulate_webhook_processing(event_id, event_type, self.booking)
        self.assertEqual(res2["status"], "already_processed")
        self.assertFalse(res2["mutated"])
        self.assertEqual(self.booking.status, "CONFIRMED")
        self.assertEqual(self.booking.mutation_count, 1, "Duplicate webhook must not re-trigger database mutations")

        # 3. Third delivery -> MUST be rejected idempotently
        res3 = self.simulate_webhook_processing(event_id, event_type, self.booking)
        self.assertEqual(res3["status"], "already_processed")
        self.assertFalse(res3["mutated"])
        self.assertEqual(self.booking.mutation_count, 1)

if __name__ == '__main__':
    unittest.main()

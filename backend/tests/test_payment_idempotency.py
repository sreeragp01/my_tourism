from django.test import TestCase
from django.contrib.auth import get_user_model
from django.utils import timezone
from apps.bookings.models import Booking
from apps.payments.models import ProcessedWebhookEvent, Payment
from apps.payments.services import IdempotentPaymentService

User = get_user_model()

class WebhookIdempotencyTestCase(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email="traveler_idem@keralink.travel",
            password="Password123!",
            first_name="Traveler",
            last_name="Idem",
        )
        self.booking = Booking.objects.create(
            booking_reference="KL2609071111",
            user=self.user,
            trip_title="Munnar Tea Retreat",
            start_date=timezone.now().date(),
            end_date=timezone.now().date(),
            travelers_count=2,
            primary_guest_name="Traveler One",
            primary_guest_phone="+91 98470 11111",
            primary_guest_email="traveler_idem@keralink.travel",
            status="PAYMENT_PROCESSING",
            subtotal=8000.00,
            tax=400.00,
            platform_fee=160.00,
            total_amount=8560.00,
            currency="INR",
            idempotency_key="bkg_idem_1",
        )
        self.service = IdempotentPaymentService()

    def test_duplicate_webhook_deduplication(self):
        event_id = "evt_rzp_unique_999888"
        payload = {
            "order_id": "order_idem_123",
            "payment_id": "pay_idem_456",
            "booking_id": str(self.booking.id),
        }

        # First arrival: processes and confirms booking
        res1 = self.service.process_webhook_event(
            event_id=event_id,
            event_type="payment.captured",
            payload=payload,
            signature="",
        )
        self.assertEqual(res1["status"], "confirmed")
        self.assertEqual(res1["booking_reference"], self.booking.booking_reference)

        # Booking is now CONFIRMED
        self.booking.refresh_from_db()
        self.assertEqual(self.booking.status, "CONFIRMED")
        self.assertIsNotNone(self.booking.confirmed_at)
        self.assertIsNotNone(self.booking.digital_pass_token)

        # ProcessedWebhookEvent recorded
        self.assertTrue(ProcessedWebhookEvent.objects.filter(event_id=event_id).exists())
        initial_events_count = ProcessedWebhookEvent.objects.count()

        # Second arrival: identical webhook event_id
        res2 = self.service.process_webhook_event(
            event_id=event_id,
            event_type="payment.captured",
            payload=payload,
            signature="",
        )
        # Must return already_processed safely without duplicating side-effects
        self.assertEqual(res2["status"], "already_processed")
        self.assertEqual(res2["event_id"], event_id)
        self.assertEqual(ProcessedWebhookEvent.objects.count(), initial_events_count)

    def test_payment_failed_webhook_handling(self):
        event_id = "evt_rzp_fail_111"
        payload = {
            "order_id": "order_fail_123",
            "payment_id": "pay_fail_456",
            "booking_id": str(self.booking.id),
        }

        res = self.service.process_webhook_event(
            event_id=event_id,
            event_type="payment.failed",
            payload=payload,
            signature="",
        )
        self.assertEqual(res["status"], "payment_failed")

        self.booking.refresh_from_db()
        self.assertEqual(self.booking.status, "PAYMENT_FAILED")

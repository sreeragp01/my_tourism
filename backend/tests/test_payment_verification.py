import json
import uuid
import hmac
import hashlib
from decimal import Decimal
from django.test import TestCase, override_settings
from django.utils import timezone
from django.contrib.auth import get_user_model
from rest_framework.test import APIClient
from rest_framework import status

from integrations.payments.payment_gateway import RazorpayAdapter, PaymentGateway
from apps.payments.services import IdempotentPaymentService, PaymentVerificationError
from apps.payments.models import Payment, ProcessedWebhookEvent
from apps.bookings.models import Booking

User = get_user_model()


class PaymentVerificationTestCase(TestCase):
    """
    Authoritative test suite for Razorpay payment verification:
      1. HMAC-SHA256 checkout signature validation & tamper rejection.
      2. Raw byte body webhook signature validation (X-Razorpay-Signature).
      3. Exact amount integrity (paise vs booking total amount) to prevent underpayment attacks.
      4. Webhook endpoint verification with valid signatures, invalid signatures, and tampered amounts.
    """

    def setUp(self):
        self.client = APIClient()
        self.key_id = "rzp_test_keralink_2026"
        self.key_secret = "secret_keralink_test_key_999"
        self.webhook_secret = "webhook_secret_keralink_secure_2026"
        self.adapter = RazorpayAdapter(key_id=self.key_id, key_secret=self.key_secret)

        self.user = User.objects.create_user(
            email="traveler_pay@example.com",
            phone="+919447000111",
            password="SecurePassword123!"
        )

        self.booking = Booking.objects.create(
            user=self.user,
            booking_reference=f"KL-PAY-{uuid.uuid4().hex[:6].upper()}",
            trip_title="Alleppey Backwater Voyage",
            start_date=timezone.now().date(),
            end_date=timezone.now().date(),
            travelers_count=2,
            primary_guest_name="Traveler Pay",
            primary_guest_phone="+91 94470 00111",
            primary_guest_email="traveler_pay@example.com",
            status="PAYMENT_PROCESSING",
            subtotal=Decimal("4500.00"),
            tax=Decimal("450.00"),
            platform_fee=Decimal("50.00"),
            total_amount=Decimal("5000.00"),
            currency="INR",
            idempotency_key=f"idem_pay_{uuid.uuid4().hex[:8]}"
        )

    # -------------------------------------------------------------
    # ADAPTER CHECKOUT SIGNATURE TESTS
    # -------------------------------------------------------------
    def test_valid_hmac_signature_verification(self):
        order_id = "order_KL260907_1234"
        payment_id = "pay_KL260907_5678"
        msg = f"{order_id}|{payment_id}".encode('utf-8')
        valid_signature = hmac.new(self.key_secret.encode('utf-8'), msg, hashlib.sha256).hexdigest()

        self.assertTrue(self.adapter.verify_payment_signature(order_id, payment_id, valid_signature))

    def test_tampered_order_id_rejection(self):
        order_id = "order_KL260907_1234"
        payment_id = "pay_KL260907_5678"
        msg = f"{order_id}|{payment_id}".encode('utf-8')
        valid_signature = hmac.new(self.key_secret.encode('utf-8'), msg, hashlib.sha256).hexdigest()

        tampered_order = "order_KL260907_9999"
        self.assertFalse(self.adapter.verify_payment_signature(tampered_order, payment_id, valid_signature))

    def test_tampered_payment_id_rejection(self):
        order_id = "order_KL260907_1234"
        payment_id = "pay_KL260907_5678"
        msg = f"{order_id}|{payment_id}".encode('utf-8')
        valid_signature = hmac.new(self.key_secret.encode('utf-8'), msg, hashlib.sha256).hexdigest()

        tampered_payment = "pay_KL260907_0000"
        self.assertFalse(self.adapter.verify_payment_signature(order_id, tampered_payment, valid_signature))

    def test_forged_signature_rejection(self):
        order_id = "order_KL260907_1234"
        payment_id = "pay_KL260907_5678"
        forged_signature = "badf00d" * 8
        self.assertFalse(self.adapter.verify_payment_signature(order_id, payment_id, forged_signature))

    # -------------------------------------------------------------
    # RAW-BODY WEBHOOK SIGNATURE TESTS
    # -------------------------------------------------------------
    def test_webhook_signature_verification_success(self):
        raw_body = json.dumps({"event": "payment.captured", "id": "evt_test_1"}).encode('utf-8')
        valid_signature = hmac.new(self.webhook_secret.encode('utf-8'), raw_body, hashlib.sha256).hexdigest()

        self.assertTrue(
            PaymentGateway.verify_webhook_signature(raw_body, valid_signature, self.webhook_secret)
        )

    def test_webhook_signature_tampered_body_rejection(self):
        original_body = json.dumps({"event": "payment.captured", "amount": 500000}).encode('utf-8')
        valid_signature = hmac.new(self.webhook_secret.encode('utf-8'), original_body, hashlib.sha256).hexdigest()

        # Attacker modifies amount in raw payload to 100 paise
        tampered_body = json.dumps({"event": "payment.captured", "amount": 100}).encode('utf-8')
        self.assertFalse(
            PaymentGateway.verify_webhook_signature(tampered_body, valid_signature, self.webhook_secret)
        )

    def test_webhook_signature_wrong_secret_rejection(self):
        raw_body = json.dumps({"event": "payment.captured"}).encode('utf-8')
        valid_signature = hmac.new("attacker_secret".encode('utf-8'), raw_body, hashlib.sha256).hexdigest()

        self.assertFalse(
            PaymentGateway.verify_webhook_signature(raw_body, valid_signature, self.webhook_secret)
        )

    # -------------------------------------------------------------
    # AMOUNT INTEGRITY & ORDER RECORD TESTS
    # -------------------------------------------------------------
    def test_service_verify_and_confirm_tampered_amount_fails(self):
        order_id = "order_rzp_amount_test"
        payment_id = "pay_rzp_amount_test"
        msg = f"{order_id}|{payment_id}".encode('utf-8')
        valid_signature = hmac.new(self.key_secret.encode('utf-8'), msg, hashlib.sha256).hexdigest()

        # Create payment record with tampered/underpaid amount (e.g., Rs. 50 instead of Rs. 5000)
        Payment.objects.create(
            booking=self.booking,
            amount=Decimal("50.00"),
            currency="INR",
            gateway="RAZORPAY",
            gateway_order_id=order_id,
            idempotency_key="pay_tamper_test_1"
        )

        service = IdempotentPaymentService(gateway_adapter=self.adapter)
        with self.assertRaises(PaymentVerificationError) as ctx:
            service.verify_and_confirm_payment(
                booking_id=self.booking.id,
                gateway_order_id=order_id,
                gateway_payment_id=payment_id,
                gateway_signature=valid_signature,
                user=self.user,
            )
        self.assertIn("Payment amount mismatch", str(ctx.exception))

    def test_service_verify_and_confirm_uninitiated_order_fails(self):
        order_id = "order_uninitiated_999"
        payment_id = "pay_test_999"
        msg = f"{order_id}|{payment_id}".encode('utf-8')
        valid_signature = hmac.new(self.key_secret.encode('utf-8'), msg, hashlib.sha256).hexdigest()

        service = IdempotentPaymentService(gateway_adapter=self.adapter)
        with self.assertRaises(PaymentVerificationError) as ctx:
            service.verify_and_confirm_payment(
                booking_id=self.booking.id,
                gateway_order_id=order_id,
                gateway_payment_id=payment_id,
                gateway_signature=valid_signature,
                user=self.user,
            )
        self.assertIn("No payment order matching", str(ctx.exception))

    # -------------------------------------------------------------
    # WEBHOOK VIEW INTEGRATION TESTS
    # -------------------------------------------------------------
    @override_settings(
        PAYMENTS_ENABLED=True,
        ALLOW_PAYMENT_SIMULATOR=False,
        RAZORPAY_WEBHOOK_SECRET="webhook_secret_keralink_secure_2026"
    )
    def test_webhook_view_with_valid_signature_and_matching_amount_confirms_booking(self):
        Payment.objects.create(
            booking=self.booking,
            amount=Decimal("5000.00"),
            currency="INR",
            gateway="RAZORPAY",
            gateway_order_id="order_wh_valid",
            idempotency_key="wh_valid_key"
        )

        # 5000 INR = 500000 paise
        payload_dict = {
            "entity": "event",
            "account_id": "acc_keralink",
            "event": "payment.captured",
            "id": f"evt_wh_{uuid.uuid4().hex[:12]}",
            "payload": {
                "payment": {
                    "entity": {
                        "id": "pay_wh_valid_123",
                        "amount": 500000,
                        "currency": "INR",
                        "order_id": "order_wh_valid",
                        "notes": {
                            "booking_id": str(self.booking.id)
                        }
                    }
                }
            }
        }
        raw_body = json.dumps(payload_dict).encode('utf-8')
        signature = hmac.new(
            b"webhook_secret_keralink_secure_2026",
            raw_body,
            hashlib.sha256
        ).hexdigest()

        response = self.client.post(
            '/api/v1/payments/webhook/',
            data=raw_body,
            content_type='application/json',
            HTTP_X_RAZORPAY_SIGNATURE=signature
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data.get('status'), 'confirmed')

        self.booking.refresh_from_db()
        self.assertEqual(self.booking.status, 'CONFIRMED')
        self.assertIsNotNone(self.booking.confirmed_at)
        self.assertIsNotNone(self.booking.digital_pass_token)

    @override_settings(
        PAYMENTS_ENABLED=True,
        ALLOW_PAYMENT_SIMULATOR=False,
        RAZORPAY_WEBHOOK_SECRET="webhook_secret_keralink_secure_2026"
    )
    def test_webhook_view_with_invalid_signature_returns_400(self):
        payload_dict = {
            "event": "payment.captured",
            "payload": {
                "booking_id": str(self.booking.id),
                "amount": 500000
            }
        }
        raw_body = json.dumps(payload_dict).encode('utf-8')

        response = self.client.post(
            '/api/v1/payments/webhook/',
            data=raw_body,
            content_type='application/json',
            HTTP_X_RAZORPAY_SIGNATURE="forged_signature_hex"
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(response.data.get('code'), 'INVALID_SIGNATURE')

    @override_settings(
        PAYMENTS_ENABLED=True,
        ALLOW_PAYMENT_SIMULATOR=False,
        RAZORPAY_WEBHOOK_SECRET="webhook_secret_keralink_secure_2026"
    )
    def test_webhook_view_with_tampered_amount_returns_400(self):
        Payment.objects.create(
            booking=self.booking,
            amount=Decimal("5000.00"),
            currency="INR",
            gateway="RAZORPAY",
            gateway_order_id="order_wh_tamper",
            idempotency_key="wh_tamper_key"
        )

        # Attacker sends paid amount as 100 paise (Rs. 1) instead of 500000 paise (Rs. 5000)
        payload_dict = {
            "event": "payment.captured",
            "id": f"evt_tamper_{uuid.uuid4().hex[:8]}",
            "payload": {
                "booking_id": str(self.booking.id),
                "payment": {
                    "id": "pay_tampered_1",
                    "amount": 100,
                }
            }
        }
        raw_body = json.dumps(payload_dict).encode('utf-8')
        signature = hmac.new(
            b"webhook_secret_keralink_secure_2026",
            raw_body,
            hashlib.sha256
        ).hexdigest()

        response = self.client.post(
            '/api/v1/payments/webhook/',
            data=raw_body,
            content_type='application/json',
            HTTP_X_RAZORPAY_SIGNATURE=signature
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(response.data.get('status'), 'amount_mismatch')

        # Booking must NOT transition to CONFIRMED
        self.booking.refresh_from_db()
        self.assertNotEqual(self.booking.status, 'CONFIRMED')

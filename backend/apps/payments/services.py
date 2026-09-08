import uuid
from decimal import Decimal
from django.db import transaction
from django.utils import timezone
from .models import Payment, ProcessedWebhookEvent
from apps.bookings.models import Booking
from apps.bookings.state_machine import BookingStateMachine
from apps.inventory.services import InventoryService
from integrations.payments.payment_gateway import RazorpayAdapter, PaymentSimulator

class PaymentVerificationError(Exception):
    pass

class IdempotentPaymentService:
    """
    Handles payment order creation, direct signature verification, and webhook ingestion
    with strict idempotency and authoritative PostgreSQL inventory hold consumption.
    """

    def __init__(self, gateway_adapter=None):
        self.gateway = gateway_adapter or PaymentSimulator()

    @transaction.atomic
    def create_order(self, booking: Booking, user, idempotency_key: str, gateway: str = 'RAZORPAY') -> dict:
        """
        Creates an authoritative payment intent order.
        Validates booking status and verifies that all linked inventory holds are still active.
        """
        if booking.user != user and not user.is_staff:
            raise PermissionError("Unauthorized to initiate payment for this booking.")

        # Check existing payment order with this idempotency key
        existing = Payment.objects.filter(idempotency_key=idempotency_key).first()
        if existing:
            return {
                "payment_id": str(existing.id),
                "gateway_order_id": existing.gateway_order_id,
                "amount": float(existing.amount),
                "currency": existing.currency,
                "razorpay_key_id": getattr(self.gateway, 'key_id', 'rzp_test_keralink2026'),
                "booking_reference": booking.booking_reference,
            }

        if booking.status not in ['PENDING_PAYMENT', 'PAYMENT_PROCESSING', 'DRAFT']:
            raise ValueError(f"Cannot create payment order for booking in status '{booking.status}'.")

        # Eagerly verify that linked inventory holds have not expired
        for item in booking.items.select_related('inventory_hold').all():
            if item.inventory_hold:
                if item.inventory_hold.is_expired() or item.inventory_hold.status == 'EXPIRED':
                    item.inventory_hold.status = 'EXPIRED'
                    item.inventory_hold.save(update_fields=['status'])
                    booking.status = 'EXPIRED'
                    booking.save(update_fields=['status'])
                    raise ValueError(f"Inventory hold for '{item.title}' has expired. Please re-check availability.")

        # Create gateway order
        order = self.gateway.create_order(
            amount_inr=float(booking.total_amount),
            currency=booking.currency,
            receipt=booking.booking_reference,
            notes={'booking_id': str(booking.id), 'booking_reference': booking.booking_reference},
        )
        gateway_order_id = order.get('id', f"order_{uuid.uuid4().hex[:14]}")

        payment = Payment.objects.create(
            booking=booking,
            amount=booking.total_amount,
            currency=booking.currency,
            gateway=gateway,
            gateway_order_id=gateway_order_id,
            idempotency_key=idempotency_key,
            status='INITIATED',
        )

        sm = BookingStateMachine(booking)
        if sm.can_transition_to('PAYMENT_PROCESSING'):
            sm.transition('PAYMENT_PROCESSING', user=user, reason="Payment order initiated via gateway")

        return {
            "payment_id": str(payment.id),
            "gateway_order_id": gateway_order_id,
            "amount": float(payment.amount),
            "currency": payment.currency,
            "razorpay_key_id": getattr(self.gateway, 'key_id', 'rzp_test_keralink2026'),
            "booking_reference": booking.booking_reference,
        }

    @transaction.atomic
    def verify_and_confirm_payment(
        self,
        booking_id,
        gateway_order_id: str,
        gateway_payment_id: str,
        gateway_signature: str,
        user=None,
    ) -> dict:
        """
        Authoritatively verifies Razorpay HMAC signature and confirms the booking.
        Atomically transfers inventory holds from 'held' to 'booked' in PostgreSQL.
        """
        try:
            booking = Booking.objects.select_for_update().get(id=booking_id)
        except Booking.DoesNotExist:
            raise ValueError(f"Booking {booking_id} not found.")

        if user and booking.user != user and not user.is_staff:
            raise PermissionError("Unauthorized: You do not have permission to verify payment for this booking.")

        # If already confirmed, return success idempotently
        if booking.status == 'CONFIRMED':
            return {
                "status": "confirmed",
                "booking_reference": booking.booking_reference,
                "digital_pass_token": booking.digital_pass_token,
                "confirmed_at": booking.confirmed_at.isoformat() if booking.confirmed_at else None,
            }

        # Verify cryptographic signature
        valid = self.gateway.verify_payment_signature(
            order_id=gateway_order_id,
            payment_id=gateway_payment_id,
            signature=gateway_signature,
        )
        if not valid:
            raise PaymentVerificationError("Invalid Razorpay payment signature. Payment verification failed.")

        # Update Payment record
        payment = Payment.objects.filter(booking=booking, gateway_order_id=gateway_order_id).first()
        if payment:
            payment.status = 'SUCCESS'
            payment.gateway_payment_id = gateway_payment_id
            payment.save(update_fields=['status', 'gateway_payment_id'])

        # Atomically consume all linked inventory holds
        self._consume_booking_holds(booking)

        # Transition booking to CONFIRMED
        sm = BookingStateMachine(booking)
        if sm.can_transition_to('CONFIRMED'):
            sm.transition('CONFIRMED', user=user, reason=f"Payment verified ({gateway_payment_id})")

        now = timezone.now()
        booking.confirmed_at = now
        if not booking.digital_pass_token:
            booking.digital_pass_token = f"KL-PASS-{booking.booking_reference}-{uuid.uuid4().hex[:8].upper()}"
        booking.save(update_fields=['status', 'confirmed_at', 'digital_pass_token'])

        return {
            "status": "confirmed",
            "booking_reference": booking.booking_reference,
            "digital_pass_token": booking.digital_pass_token,
            "confirmed_at": now.isoformat(),
        }

    @transaction.atomic
    def process_webhook_event(self, event_id: str, event_type: str, payload: dict, signature: str = "") -> dict:
        """
        Idempotently processes incoming gateway webhook events.
        Duplicate events are safely recognized and skipped without duplicate mutations.
        """
        if ProcessedWebhookEvent.objects.filter(event_id=event_id).exists():
            return {"status": "already_processed", "event_id": event_id}

        # Record webhook event to guarantee exactly-once processing
        ProcessedWebhookEvent.objects.create(
            event_id=event_id,
            event_type=event_type,
            raw_payload=payload,
            processed_at=timezone.now(),
        )

        booking_id = payload.get("booking_id")
        if not booking_id and "payment" in payload:
            booking_id = payload["payment"].get("notes", {}).get("booking_id")

        if not booking_id:
            return {"status": "ignored", "reason": "No booking_id found in webhook payload"}

        try:
            booking = Booking.objects.select_for_update().get(id=booking_id)
        except Booking.DoesNotExist:
            return {"status": "ignored", "reason": f"Booking {booking_id} not found"}

        if event_type in ["payment.captured", "order.paid"]:
            if booking.status != 'CONFIRMED':
                # Atomically consume all linked inventory holds
                self._consume_booking_holds(booking)

                sm = BookingStateMachine(booking)
                if sm.can_transition_to("CONFIRMED"):
                    sm.transition("CONFIRMED", reason=f"Webhook {event_id} captured")

                now = timezone.now()
                booking.confirmed_at = now
                if not booking.digital_pass_token:
                    booking.digital_pass_token = f"KL-PASS-{booking.booking_reference}-{uuid.uuid4().hex[:8].upper()}"
                booking.save(update_fields=['status', 'confirmed_at', 'digital_pass_token'])

            payment_id = payload.get("payment_id") or payload.get("payment", {}).get("id")
            payment = Payment.objects.filter(booking=booking).first()
            if payment:
                payment.status = 'SUCCESS'
                if payment_id:
                    payment.gateway_payment_id = payment_id
                payment.save(update_fields=['status', 'gateway_payment_id'])

            return {
                "status": "confirmed",
                "booking_reference": booking.booking_reference,
                "digital_pass_token": booking.digital_pass_token,
            }

        elif event_type == "payment.failed":
            sm = BookingStateMachine(booking)
            if sm.can_transition_to("PAYMENT_FAILED"):
                sm.transition("PAYMENT_FAILED", reason=f"Webhook {event_id} reported failure")

            payment = Payment.objects.filter(booking=booking).first()
            if payment:
                payment.status = 'FAILED'
                payment.save(update_fields=['status'])

            return {"status": "payment_failed", "booking_reference": booking.booking_reference}

        return {"status": "ignored", "event_type": event_type}

    def _consume_booking_holds(self, booking: Booking):
        """
        Consumes all active holds attached to this booking, transferring capacity
        from 'held' to 'booked' in PostgreSQL.
        """
        for item in booking.items.select_related('inventory_hold').all():
            if item.inventory_hold and item.inventory_hold.status == 'ACTIVE':
                try:
                    InventoryService.confirm_hold(item.inventory_hold.id, booking_id=booking.id)
                except Exception:
                    # If already confirmed or handled
                    pass

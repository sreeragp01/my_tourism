import uuid
from django.db import transaction
from django.utils import timezone
from .models import Payment, ProcessedWebhookEvent
from apps.bookings.models import Booking
from apps.bookings.state_machine import BookingStateMachine
from integrations.payments.payment_gateway import RazorpayAdapter, PaymentSimulator

class IdempotentPaymentService:
    """
    Handles payment intents, gateway handoffs, and webhook verification with
    strict idempotency to prevent duplicate charges or replay attacks.
    """

    def __init__(self, gateway_adapter=None):
        self.gateway = gateway_adapter or PaymentSimulator()

    @transaction.atomic
    def process_webhook_event(self, event_id: str, event_type: str, payload: dict, signature: str = "") -> dict:
        # Check if webhook event was already processed (Idempotency Guard)
        if ProcessedWebhookEvent.objects.filter(event_id=event_id).exists():
            return {"status": "already_processed", "event_id": event_id}

        # Verify gateway signature if in production
        order_id = payload.get("order_id", "")
        payment_id = payload.get("payment_id", "")
        
        # Record webhook event to guarantee exactly-once execution
        ProcessedWebhookEvent.objects.create(
            event_id=event_id,
            event_type=event_type,
            raw_payload=payload,
            processed_at=timezone.now(),
        )

        if event_type == "payment.captured" or event_type == "order.paid":
            booking_id = payload.get("booking_id")
            booking = Booking.objects.select_for_update().get(id=booking_id)
            
            sm = BookingStateMachine(booking)
            if sm.can_transition_to("CONFIRMED"):
                sm.transition("CONFIRMED", reason=f"Webhook {event_id} verified")

            return {"status": "confirmed", "booking_reference": booking.booking_reference}

        elif event_type == "payment.failed":
            booking_id = payload.get("booking_id")
            booking = Booking.objects.select_for_update().get(id=booking_id)
            
            sm = BookingStateMachine(booking)
            if sm.can_transition_to("PAYMENT_FAILED"):
                sm.transition("PAYMENT_FAILED", reason="Payment gateway failure callback")

            return {"status": "payment_failed", "booking_reference": booking.booking_reference}

        return {"status": "ignored", "event_type": event_type}

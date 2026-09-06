import uuid
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions
from .models import Payment
from .serializers import PaymentSerializer, CreatePaymentOrderSerializer, WebhookPayloadSerializer
from .services import IdempotentPaymentService
from apps.bookings.models import Booking
from apps.bookings.state_machine import BookingStateMachine

class CreatePaymentOrderView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = CreatePaymentOrderSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        booking = Booking.objects.filter(id=data['booking_id']).first()
        if not booking:
            return Response({"error": "Booking not found"}, status=status.HTTP_404_NOT_FOUND)

        # Check idempotency
        payment = Payment.objects.filter(idempotency_key=data['idempotency_key']).first()
        if payment:
            return Response(PaymentSerializer(payment).data, status=status.HTTP_200_OK)

        # Create Razorpay order simulation / API
        order_id = f"order_{uuid.uuid4().hex[:14]}"
        payment = Payment.objects.create(
            booking=booking,
            amount=data['amount'],
            currency='INR',
            gateway=data['gateway'],
            gateway_order_id=order_id,
            idempotency_key=data['idempotency_key'],
            status='INITIATED'
        )

        sm = BookingStateMachine(booking)
        if sm.can_transition_to('PAYMENT_PROCESSING'):
            sm.transition('PAYMENT_PROCESSING', user=request.user, reason="Payment order initiated")

        return Response({
            "payment_id": str(payment.id),
            "gateway_order_id": order_id,
            "amount": float(payment.amount),
            "currency": payment.currency,
            "razorpay_key_id": "rzp_live_keralink_tourism_2026",
            "booking_reference": booking.booking_reference
        }, status=status.HTTP_201_CREATED)

class PaymentWebhookView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = WebhookPayloadSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        service = IdempotentPaymentService()
        result = service.process_webhook_event(
            event_id=data['event_id'],
            event_type=data['event_type'],
            payload=data['payload'],
            signature=data.get('signature', '')
        )
        return Response(result, status=status.HTTP_200_OK)

class DirectPaymentVerifyView(APIView):
    """
    Direct client verification fallback after Razorpay modal completes.
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        booking_id = request.data.get('booking_id')
        payment_id = request.data.get('payment_id')
        
        booking = Booking.objects.filter(id=booking_id).first()
        if not booking:
            return Response({"error": "Booking not found"}, status=status.HTTP_404_NOT_FOUND)

        sm = BookingStateMachine(booking)
        if sm.can_transition_to('CONFIRMED'):
            sm.transition('CONFIRMED', user=request.user, reason=f"Direct verification payment {payment_id}")
            return Response({"status": "confirmed", "booking_reference": booking.booking_reference}, status=status.HTTP_200_OK)

        return Response({"status": booking.status, "booking_reference": booking.booking_reference}, status=status.HTTP_200_OK)

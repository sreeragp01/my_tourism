import uuid
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions
from .serializers import (
    CreatePaymentOrderSerializer,
    VerifyPaymentSerializer,
    WebhookPayloadSerializer,
)
from .services import IdempotentPaymentService, PaymentVerificationError
from apps.bookings.models import Booking

class CreatePaymentOrderView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = CreatePaymentOrderSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        booking = Booking.objects.filter(id=data['booking_id']).first()
        if not booking:
            return Response({"error": "Booking not found"}, status=status.HTTP_404_NOT_FOUND)

        service = IdempotentPaymentService()
        try:
            order_data = service.create_order(
                booking=booking,
                user=request.user,
                idempotency_key=data['idempotency_key'],
                gateway=data.get('gateway', 'RAZORPAY'),
            )
            return Response(order_data, status=status.HTTP_201_CREATED)
        except PermissionError as e:
            return Response({"error": str(e), "code": "UNAUTHORIZED"}, status=status.HTTP_403_FORBIDDEN)
        except ValueError as e:
            return Response({"error": str(e), "code": "PAYMENT_ORDER_ERROR"}, status=status.HTTP_400_BAD_REQUEST)


class DirectPaymentVerifyView(APIView):
    """
    Authoritative payment signature verification endpoint.
    Only confirms booking and consumes holds if cryptographic signature is valid.
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = VerifyPaymentSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        service = IdempotentPaymentService()
        try:
            result = service.verify_and_confirm_payment(
                booking_id=data['booking_id'],
                gateway_order_id=data['gateway_order_id'],
                gateway_payment_id=data['gateway_payment_id'],
                gateway_signature=data['gateway_signature'],
                user=request.user,
            )
            return Response(result, status=status.HTTP_200_OK)
        except PaymentVerificationError as e:
            return Response({"error": str(e), "code": "INVALID_SIGNATURE"}, status=status.HTTP_400_BAD_REQUEST)
        except PermissionError as e:
            return Response({"error": str(e), "code": "UNAUTHORIZED"}, status=status.HTTP_403_FORBIDDEN)
        except ValueError as e:
            return Response({"error": str(e), "code": "BOOKING_NOT_FOUND"}, status=status.HTTP_404_NOT_FOUND)


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
            signature=data.get('signature', ''),
        )
        return Response(result, status=status.HTTP_200_OK)

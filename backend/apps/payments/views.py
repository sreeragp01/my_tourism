import uuid
from django.conf import settings
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
from integrations.payments.payment_gateway import PaymentGateway

class CreatePaymentOrderView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        if not getattr(settings, 'PAYMENTS_ENABLED', False):
            return Response({
                'success': False,
                'code': 'PAYMENTS_DISABLED',
                'message': 'Payment processing is temporarily suspended for security verification.'
            }, status=status.HTTP_503_SERVICE_UNAVAILABLE)

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
        if not getattr(settings, 'PAYMENTS_ENABLED', False):
            return Response({
                'success': False,
                'code': 'PAYMENTS_DISABLED',
                'message': 'Live payment verification is temporarily suspended for security verification.'
            }, status=status.HTTP_503_SERVICE_UNAVAILABLE)

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
        if not getattr(settings, 'PAYMENTS_ENABLED', False):
            return Response({
                'success': False,
                'code': 'PAYMENTS_DISABLED',
                'message': 'Payment webhooks are temporarily suspended.'
            }, status=status.HTTP_503_SERVICE_UNAVAILABLE)

        # 1. Authoritative Webhook Cryptographic Signature Verification
        webhook_secret = getattr(settings, 'RAZORPAY_WEBHOOK_SECRET', '')
        received_signature = (
            request.headers.get('X-Razorpay-Signature')
            or request.META.get('HTTP_X_RAZORPAY_SIGNATURE')
            or (request.data.get('signature') if isinstance(request.data, dict) else None)
        )

        is_test_env = getattr(settings, 'ALLOW_PAYMENT_SIMULATOR', False)

        # In production (ALLOW_PAYMENT_SIMULATOR=False), webhook_secret and valid signature are strictly mandatory.
        # In test simulation mode, if signature is omitted it proceeds; if signature is passed, it is strictly validated.
        if webhook_secret and not (is_test_env and not received_signature):
            if not received_signature:
                return Response(
                    {"error": "Missing X-Razorpay-Signature header.", "code": "SIGNATURE_REQUIRED"},
                    status=status.HTTP_400_BAD_REQUEST
                )
            is_valid = PaymentGateway.verify_webhook_signature(
                raw_body=request.body,
                signature=received_signature,
                webhook_secret=webhook_secret
            )
            if not is_valid:
                return Response(
                    {"error": "Invalid webhook cryptographic signature.", "code": "INVALID_SIGNATURE"},
                    status=status.HTTP_400_BAD_REQUEST
                )
        elif not is_test_env:
            return Response(
                {"error": "RAZORPAY_WEBHOOK_SECRET is not configured on server.", "code": "CONFIGURATION_ERROR"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

        # 2. Extract event parameters (supports standard Razorpay JSON and custom payload)
        raw_data = request.data
        if not isinstance(raw_data, dict):
            return Response({"error": "Invalid JSON body", "code": "INVALID_BODY"}, status=status.HTTP_400_BAD_REQUEST)

        if 'event' in raw_data and 'payload' in raw_data:
            event_id = raw_data.get('id') or request.headers.get('X-Razorpay-Event-Id') or f"evt_{uuid.uuid4().hex[:16]}"
            event_type = raw_data.get('event')
            payload_data = raw_data.get('payload', {})
        elif 'event_type' in raw_data and 'payload' in raw_data:
            event_id = raw_data.get('event_id') or f"evt_{uuid.uuid4().hex[:16]}"
            event_type = raw_data.get('event_type')
            payload_data = raw_data.get('payload', {})
        else:
            return Response(
                {"error": "Unsupported webhook payload structure.", "code": "INVALID_PAYLOAD"},
                status=status.HTTP_400_BAD_REQUEST
            )

        service = IdempotentPaymentService()
        result = service.process_webhook_event(
            event_id=event_id,
            event_type=event_type,
            payload=payload_data,
            signature=received_signature or '',
        )

        if result.get('status') == 'amount_mismatch':
            return Response(result, status=status.HTTP_400_BAD_REQUEST)

        return Response(result, status=status.HTTP_200_OK)


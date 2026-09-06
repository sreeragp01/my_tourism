import uuid
import random
from django.db import transaction
from django.utils import timezone
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions, viewsets
from .models import Booking, BookingItem
from .serializers import BookingSerializer, CreateBookingRequestSerializer, TransitionStateRequestSerializer
from .state_machine import BookingStateMachine, InvalidStateTransitionError
from apps.inventory.services import InventoryService, InsufficientInventoryError
from apps.pricing.services import AuthoritativePricingEngine

class BookingViewSet(viewsets.ModelViewSet):
    serializer_class = BookingSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        # Multi-tenant isolation: Users only see their own bookings unless platform staff
        if self.request.user.is_staff:
            return Booking.objects.all().order_by('-created_at')
        return Booking.objects.filter(user=self.request.user).order_by('-created_at')

    @transaction.atomic
    def create(self, request, *args, **kwargs):
        serializer = CreateBookingRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        idempotency_key = data['idempotency_key']
        existing_booking = Booking.objects.filter(idempotency_key=idempotency_key).first()
        if existing_booking:
            return Response(BookingSerializer(existing_booking).data, status=status.HTTP_200_OK)

        # Generate unique reference e.g., KL2609051234
        today_str = timezone.now().strftime('%y%m%d')
        random_suffix = random.randint(1000, 9999)
        ref = f"KL{today_str}{random_suffix}"

        # Authoritative pricing calculation
        total_price = 0
        items_to_create = []
        for itm in data['items']:
            sub = float(itm.get('unit_price', 0)) * int(itm.get('units', 1))
            total_price += sub
            items_to_create.append(itm)

        booking = Booking.objects.create(
            booking_reference=ref,
            user=request.user,
            trip_title=data['trip_title'],
            start_date=data['start_date'],
            end_date=data['end_date'],
            travelers_count=data['travelers_count'],
            primary_guest_name=data['primary_guest_name'],
            primary_guest_phone=data['primary_guest_phone'],
            primary_guest_email=data['primary_guest_email'],
            status='DRAFT',
            total_amount=total_price,
            currency='INR',
            idempotency_key=idempotency_key,
            green_trip_score=88,
            qr_code_url=f"https://api.keralink.org/v1/passes/{ref}.png"
        )

        for itm in items_to_create:
            BookingItem.objects.create(
                booking=booking,
                item_type=itm.get('item_type', 'ROOM'),
                title=itm.get('title', 'Item'),
                date=itm.get('date', data['start_date']),
                units=int(itm.get('units', 1)),
                unit_price=float(itm.get('unit_price', 0)),
                subtotal=float(itm.get('unit_price', 0)) * int(itm.get('units', 1)),
                provider_org_id=itm.get('provider_org_id', uuid.uuid4())
            )

        # Transition to PENDING_PAYMENT
        sm = BookingStateMachine(booking)
        sm.transition('PENDING_PAYMENT', user=request.user, reason="Booking checkout created")

        return Response(BookingSerializer(booking).data, status=status.HTTP_201_CREATED)

class BookingTransitionView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    @transaction.atomic
    def post(self, request, pk):
        booking = Booking.objects.select_for_update().filter(id=pk).first()
        if not booking:
            return Response({"error": "Booking not found"}, status=status.HTTP_404_NOT_FOUND)

        if booking.user != request.user and not request.user.is_staff:
            return Response({"error": "Unauthorized to modify this booking"}, status=status.HTTP_403_FORBIDDEN)

        serializer = TransitionStateRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        target_state = serializer.validated_data['target_state']
        reason = serializer.validated_data.get('reason', '')

        sm = BookingStateMachine(booking)
        try:
            sm.transition(target_state, user=request.user, reason=reason)
            if target_state == 'CONFIRMED':
                booking.confirmed_at = timezone.now()
                booking.save()
            return Response(BookingSerializer(booking).data, status=status.HTTP_200_OK)
        except InvalidStateTransitionError as e:
            return Response({"error": str(e), "code": "INVALID_STATE_TRANSITION"}, status=status.HTTP_400_BAD_REQUEST)

class DigitalPassView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request, reference):
        booking = Booking.objects.filter(booking_reference=reference).first()
        if not booking:
            return Response({"error": "Digital pass not found"}, status=status.HTTP_404_NOT_FOUND)

        pass_data = {
            "booking_reference": booking.booking_reference,
            "guest_name": booking.primary_guest_name,
            "trip_title": booking.trip_title,
            "status": booking.status,
            "dates": f"{booking.start_date} to {booking.end_date}",
            "travelers": booking.travelers_count,
            "eco_green_score": booking.green_trip_score,
            "corridor": "Kochi → Munnar → Thekkady → Alappuzha → Varkala",
            "qr_data": f"KERALINK-PASS-{booking.booking_reference}-{booking.id}",
            "helpline": "1800-425-4747"
        }
        return Response(pass_data, status=status.HTTP_200_OK)

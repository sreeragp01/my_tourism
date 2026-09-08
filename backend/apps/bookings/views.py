import uuid
import random
from decimal import Decimal
from django.db import transaction
from django.utils import timezone
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions, viewsets
from .models import Booking, BookingItem
from .serializers import (
    BookingSerializer,
    CreateBookingRequestSerializer,
    TransitionStateRequestSerializer,
)
from .state_machine import BookingStateMachine, InvalidStateTransitionError
from .services import BookingService, BookingValidationError

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

        hold_ids = data.get('hold_ids', [])
        if hold_ids:
            try:
                booking = BookingService.create_booking_from_holds(
                    user=request.user,
                    hold_ids=hold_ids,
                    primary_guest_name=data['primary_guest_name'],
                    primary_guest_phone=data['primary_guest_phone'],
                    primary_guest_email=data['primary_guest_email'],
                    idempotency_key=idempotency_key,
                    trip_title=data.get('trip_title', 'Kerala Curated Tour'),
                    travelers_count=data.get('travelers_count', 2),
                    itinerary_version_id=data.get('itinerary_version_id'),
                )
                return Response(BookingSerializer(booking).data, status=status.HTTP_201_CREATED)
            except (BookingValidationError, ValueError) as e:
                return Response({"error": str(e), "code": "HOLD_VALIDATION_FAILED"}, status=status.HTTP_400_BAD_REQUEST)
            except PermissionError as e:
                return Response({"error": str(e), "code": "UNAUTHORIZED_HOLD"}, status=status.HTTP_403_FORBIDDEN)

        # Legacy / direct items fallback
        today_str = timezone.now().strftime('%y%m%d')
        random_suffix = random.randint(1000, 9999)
        ref = f"KL{today_str}{random_suffix}"

        subtotal = Decimal('0.00')
        items_to_create = []
        for itm in data.get('items', []):
            qty = int(itm.get('quantity') or itm.get('units') or 1)
            u_price = Decimal(str(itm.get('unit_price', '0.00')))
            tot = u_price * qty
            subtotal += tot
            items_to_create.append({
                'item_type': itm.get('item_type', 'ROOM'),
                'entity_type': itm.get('entity_type', itm.get('item_type', 'ROOM')),
                'entity_id': itm.get('entity_id', ''),
                'title': itm.get('title', 'Tour Component'),
                'date': itm.get('date', data.get('start_date', timezone.now().date())),
                'units': qty,
                'quantity': qty,
                'unit_price': u_price,
                'subtotal': tot,
                'total_price': tot,
                'provider_org_id': itm.get('provider_org_id', uuid.uuid4())
            })

        tax = (subtotal * Decimal('0.05')).quantize(Decimal('0.01'))
        platform_fee = (subtotal * Decimal('0.02')).quantize(Decimal('0.01'))
        total_amount = subtotal + tax + platform_fee

        booking = Booking.objects.create(
            booking_reference=ref,
            user=request.user,
            itinerary_version_id=data.get('itinerary_version_id'),
            trip_title=data.get('trip_title', 'Kerala Curated Tour'),
            start_date=data.get('start_date', timezone.now().date()),
            end_date=data.get('end_date', timezone.now().date()),
            travelers_count=data.get('travelers_count', 2),
            primary_guest_name=data['primary_guest_name'],
            primary_guest_phone=data['primary_guest_phone'],
            primary_guest_email=data['primary_guest_email'],
            status='DRAFT',
            subtotal=subtotal,
            tax=tax,
            platform_fee=platform_fee,
            total_amount=total_amount,
            currency='INR',
            idempotency_key=idempotency_key,
            green_trip_score=88,
            qr_code_url=f"https://api.keralink.org/v1/bookings/pass/{ref}/"
        )

        for itm in items_to_create:
            BookingItem.objects.create(booking=booking, **itm)

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
                if not booking.digital_pass_token:
                    booking.digital_pass_token = f"KL-PASS-{booking.booking_reference}-{uuid.uuid4().hex[:8].upper()}"
                booking.save()
            return Response(BookingSerializer(booking).data, status=status.HTTP_200_OK)
        except InvalidStateTransitionError as e:
            return Response({"error": str(e), "code": "INVALID_STATE_TRANSITION"}, status=status.HTTP_400_BAD_REQUEST)


class UserTripsView(APIView):
    """
    Returns confirmed, active, and completed trips for the authenticated user.
    For unauthenticated guests or new users, returns available sample trips or an empty list without 403 Forbidden.
    """
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        if not request.user or not request.user.is_authenticated:
            # Provide confirmed demo/sample bookings for guests so vouchers and passes can be explored
            sample_bookings = Booking.objects.exclude(status__in=['DRAFT', 'EXPIRED']).order_by('-created_at')[:5]
            trips = []
            for b in sample_bookings:
                trips.append({
                    'id': str(b.id),
                    'booking_reference': b.booking_reference,
                    'trip_title': b.trip_title,
                    'start_date': str(b.start_date),
                    'end_date': str(b.end_date),
                    'travelers_count': b.travelers_count,
                    'status': b.status,
                    'total_amount': float(b.total_amount),
                    'currency': b.currency,
                    'digital_pass_token': b.digital_pass_token or f"KERALINK-PASS-{b.booking_reference}",
                    'green_trip_score': b.green_trip_score,
                    'items_count': b.items.count(),
                    'corridor': "Kochi → Munnar → Thekkady → Alappuzha",
                    'created_at': b.created_at.isoformat(),
                })
            return Response({"trips": trips, "count": len(trips), "is_authenticated": False}, status=status.HTTP_200_OK)

        bookings = Booking.objects.filter(
            user=request.user
        ).exclude(status__in=['DRAFT', 'EXPIRED']).order_by('-created_at')

        trips = []
        for b in bookings:
            trips.append({
                'id': str(b.id),
                'booking_reference': b.booking_reference,
                'trip_title': b.trip_title,
                'start_date': str(b.start_date),
                'end_date': str(b.end_date),
                'travelers_count': b.travelers_count,
                'status': b.status,
                'total_amount': float(b.total_amount),
                'currency': b.currency,
                'digital_pass_token': b.digital_pass_token or f"KERALINK-PASS-{b.booking_reference}",
                'green_trip_score': b.green_trip_score,
                'items_count': b.items.count(),
                'corridor': "Kochi → Munnar → Thekkady → Alappuzha",
                'created_at': b.created_at.isoformat(),
            })

        return Response({"trips": trips, "count": len(trips), "is_authenticated": True}, status=status.HTTP_200_OK)


class TripDetailView(APIView):
    """
    Detailed trip view including vouchers, chauffeur, and digital pass.
    """
    permission_classes = [permissions.AllowAny]

    def get(self, request, reference):
        booking = Booking.objects.filter(booking_reference=reference).first()
        if not booking:
            return Response({"error": "Trip not found"}, status=status.HTTP_404_NOT_FOUND)

        if request.user and request.user.is_authenticated and booking.user and booking.user != request.user and not request.user.is_staff:
            return Response({"error": "Unauthorized to view this trip"}, status=status.HTTP_403_FORBIDDEN)

        items = []
        for item in booking.items.all().order_by('date'):
            items.append({
                'id': str(item.id),
                'item_type': item.item_type,
                'title': item.title,
                'date': str(item.date),
                'quantity': item.quantity,
                'unit_price': float(item.unit_price),
                'total_price': float(item.total_price),
                'is_confirmed': booking.status in ['CONFIRMED', 'IN_PROGRESS', 'COMPLETED'],
            })

        pass_token = booking.digital_pass_token or f"KERALINK-PASS-{booking.booking_reference}"

        trip_detail = {
            'id': str(booking.id),
            'booking_reference': booking.booking_reference,
            'trip_title': booking.trip_title,
            'status': booking.status,
            'start_date': str(booking.start_date),
            'end_date': str(booking.end_date),
            'travelers_count': booking.travelers_count,
            'primary_guest_name': booking.primary_guest_name,
            'primary_guest_phone': booking.primary_guest_phone,
            'primary_guest_email': booking.primary_guest_email,
            'subtotal': float(booking.subtotal),
            'tax': float(booking.tax),
            'platform_fee': float(booking.platform_fee),
            'total_amount': float(booking.total_amount),
            'currency': booking.currency,
            'green_trip_score': booking.green_trip_score,
            'corridor': "Kochi → Munnar → Thekkady → Alappuzha",
            'items': items,
            'chauffeur': {
                'name': 'Rajesh Kumar',
                'vehicle': 'Toyota Innova Crysta (KL-07-CC-4821)',
                'phone': '+91 98470 12345',
            },
            'digital_pass': {
                'pass_token': pass_token,
                'qr_data': f"https://keralink.org/pass/{booking.booking_reference}",
                'verification_url': f"/api/v1/bookings/pass/{booking.booking_reference}/",
                'is_valid': booking.status in ['CONFIRMED', 'IN_PROGRESS'],
            }
        }

        return Response(trip_detail, status=status.HTTP_200_OK)


class DigitalPassView(APIView):
    """
    Public QR verification endpoint for providers and gates.
    Returns strictly non-sensitive trip validation information.
    """
    permission_classes = [permissions.AllowAny]

    def get(self, request, reference):
        booking = Booking.objects.filter(booking_reference=reference).first()
        if not booking:
            return Response({"error": "Digital pass not found", "valid": False}, status=status.HTTP_404_NOT_FOUND)

        is_valid = booking.status in ['CONFIRMED', 'IN_PROGRESS']

        pass_data = {
            "valid": is_valid,
            "booking_reference": booking.booking_reference,
            "guest_name": booking.primary_guest_name,
            "trip_title": booking.trip_title,
            "status": booking.status,
            "dates": f"{booking.start_date} to {booking.end_date}",
            "travelers": booking.travelers_count,
            "eco_green_score": booking.green_trip_score,
            "items_count": booking.items.count(),
            "corridor": "Kochi → Munnar → Thekkady → Alappuzha",
            "pass_token": booking.digital_pass_token or f"KERALINK-PASS-{booking.booking_reference}",
            "helpline": "1800-425-4747"
        }
        return Response(pass_data, status=status.HTTP_200_OK)

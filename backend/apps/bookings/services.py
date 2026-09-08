import uuid
import random
import datetime
from decimal import Decimal
from django.db import transaction
from django.utils import timezone
from .models import Booking, BookingItem
from .state_machine import BookingStateMachine
from apps.inventory.models import InventoryHold
from apps.accommodations.models import RoomInventory
from apps.experiences.models import ExperienceSlot

class BookingValidationError(Exception):
    pass

class BookingService:
    @classmethod
    @transaction.atomic
    def create_booking_from_holds(
        cls,
        user,
        hold_ids: list,
        primary_guest_name: str,
        primary_guest_phone: str,
        primary_guest_email: str,
        idempotency_key: str,
        trip_title: str = "Kerala Curated Tour",
        travelers_count: int = 2,
        itinerary_version_id: str = None,
    ) -> Booking:
        """
        Atomically creates a Booking in PENDING_PAYMENT state linked to verified active InventoryHolds.
        Locks each hold with select_for_update() and enforces:
          - ownership (hold.user == user)
          - active status (hold.status == 'ACTIVE')
          - non-expired window (not hold.is_expired())
        Rolls back entirely if any validation check fails.
        """
        if not hold_ids:
            raise BookingValidationError("At least one active inventory hold is required to create a booking.")

        # Idempotency check
        existing = Booking.objects.filter(idempotency_key=idempotency_key).first()
        if existing:
            return existing

        verified_holds = []
        hold_dates = []

        # Lock and validate every requested hold
        for h_id in hold_ids:
            try:
                hold = InventoryHold.objects.select_for_update().get(id=h_id)
            except InventoryHold.DoesNotExist:
                raise BookingValidationError(f"Inventory hold {h_id} does not exist.")

            if hold.user and hold.user != user:
                raise PermissionError(f"Unauthorized: inventory hold {h_id} belongs to another traveler.")

            if hold.status != 'ACTIVE':
                raise BookingValidationError(f"Inventory hold {h_id} is not active (current status: {hold.status}).")

            if hold.is_expired():
                hold.status = 'EXPIRED'
                hold.save(update_fields=['status'])
                raise BookingValidationError(f"Inventory hold {h_id} has expired.")

            verified_holds.append(hold)
            if hold.date:
                hold_dates.append(hold.date)

        # Dates computation
        today = timezone.now().date()
        start_date = min(hold_dates) if hold_dates else today
        end_date = max(hold_dates) if hold_dates else (start_date + datetime.timedelta(days=2))

        # Itemize and compute authoritative financial breakdown
        items_data = []
        subtotal = Decimal('0.00')

        for hold in verified_holds:
            unit_price = Decimal('2500.00')
            title = f"{hold.inventory_type.title()} Booking"
            provider_org_id = None
            item_date = hold.date or start_date

            if hold.inventory_type == 'ROOM':
                inv = RoomInventory.objects.select_related('room_type__accommodation').filter(id=hold.inventory_id).first()
                if inv and inv.room_type:
                    unit_price = Decimal(str(inv.room_type.price_per_night))
                    title = f"{inv.room_type.name} ({inv.room_type.accommodation.name})"
                    provider_org_id = inv.room_type.accommodation.org_id
                    item_date = inv.date

            elif hold.inventory_type == 'EXPERIENCE':
                slot = ExperienceSlot.objects.select_related('experience').filter(id=hold.inventory_id).first()
                if slot and slot.experience:
                    unit_price = Decimal(str(slot.experience.price_per_person))
                    title = slot.experience.title
                    provider_org_id = slot.experience.org_id
                    item_date = slot.date

            item_total = unit_price * hold.quantity
            subtotal += item_total
            items_data.append({
                'hold': hold,
                'item_type': 'ROOM' if hold.inventory_type == 'ROOM' else 'EXPERIENCE',
                'entity_type': hold.inventory_type,
                'entity_id': hold.inventory_id,
                'title': title,
                'date': item_date,
                'quantity': hold.quantity,
                'unit_price': unit_price,
                'total_price': item_total,
                'provider_org_id': provider_org_id,
            })

        # GST 5% & Platform Fee 2%
        tax = (subtotal * Decimal('0.05')).quantize(Decimal('0.01'))
        platform_fee = (subtotal * Decimal('0.02')).quantize(Decimal('0.01'))
        total_amount = subtotal + tax + platform_fee

        # Generate unique reference
        today_str = timezone.now().strftime('%y%m%d')
        ref = f"KL{today_str}{random.randint(1000, 9999)}"

        booking = Booking.objects.create(
            booking_reference=ref,
            user=user,
            itinerary_version_id=itinerary_version_id,
            trip_title=trip_title,
            start_date=start_date,
            end_date=end_date,
            travelers_count=travelers_count,
            primary_guest_name=primary_guest_name,
            primary_guest_phone=primary_guest_phone,
            primary_guest_email=primary_guest_email,
            status='DRAFT',
            subtotal=subtotal,
            tax=tax,
            platform_fee=platform_fee,
            total_amount=total_amount,
            currency='INR',
            idempotency_key=idempotency_key,
            green_trip_score=88,
            qr_code_url=f"https://api.keralink.org/v1/bookings/pass/{ref}/",
        )

        for itm in items_data:
            BookingItem.objects.create(
                booking=booking,
                inventory_hold=itm['hold'],
                item_type=itm['item_type'],
                entity_type=itm['entity_type'],
                entity_id=itm['entity_id'],
                title=itm['title'],
                date=itm['date'],
                units=itm['quantity'],
                quantity=itm['quantity'],
                unit_price=itm['unit_price'],
                subtotal=itm['total_price'],
                total_price=itm['total_price'],
                provider_org_id=itm['provider_org_id'],
            )
            # Link hold back to booking
            itm['hold'].booking_id = booking.id
            itm['hold'].save(update_fields=['booking_id'])

        # Transition to PENDING_PAYMENT
        sm = BookingStateMachine(booking)
        sm.transition('PENDING_PAYMENT', user=user, reason="Booking initialized from active holds")

        return booking

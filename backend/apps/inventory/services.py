import uuid
from datetime import timedelta
import logging
from django.db import transaction
from django.utils import timezone
from .models import InventoryHold
from apps.accommodations.models import RoomInventory, RoomType
from apps.experiences.models import ExperienceSlot, Experience

logger = logging.getLogger(__name__)


def _is_uuid(val) -> bool:
    if isinstance(val, uuid.UUID):
        return True
    try:
        uuid.UUID(str(val))
        return True
    except (ValueError, AttributeError, TypeError):
        return False


class InsufficientInventoryError(Exception):
    def __init__(self, message: str, details: dict = None):
        super().__init__(message)
        self.message = message
        self.details = details or {}


class InventoryNotFoundError(Exception):
    pass


class HoldNotFoundError(Exception):
    pass


class HoldExpiredError(Exception):
    pass


class InventoryService:
    @classmethod
    def _clean_expired_holds_for_target(cls, inv_type: str, inv_id: str):
        """Lazily releases capacity for expired holds on a specific inventory unit."""
        now = timezone.now()
        expired = InventoryHold.objects.select_for_update().filter(
            inventory_type=inv_type,
            inventory_id=str(inv_id),
            status='ACTIVE',
            expires_at__lt=now,
        )
        for h in expired:
            cls._expire_single_hold(h)

    @classmethod
    def _expire_single_hold(cls, hold: InventoryHold):
        """Atomically transitions an expired hold to EXPIRED and restores capacity."""
        if hold.inventory_type == 'ROOM':
            inv = RoomInventory.objects.select_for_update().filter(id=hold.inventory_id).first()
            if inv:
                inv.held_rooms = max(0, inv.held_rooms - hold.quantity)
                inv.save(update_fields=['held_rooms'])
        elif hold.inventory_type == 'EXPERIENCE':
            slot = ExperienceSlot.objects.select_for_update().filter(id=hold.inventory_id).first()
            if slot:
                slot.held_capacity = max(0, slot.held_capacity - hold.quantity)
                slot.save(update_fields=['held_capacity'])

        hold.status = 'EXPIRED'
        hold.save(update_fields=['status'])

    @classmethod
    @transaction.atomic
    def check_availability(
        cls,
        inventory_type: str,
        inventory_id,
        date=None,
        quantity: int = 1,
    ) -> dict:
        """
        Queries PostgreSQL authoritative capacity for a room type or experience slot.
        Lazily cleans expired holds to guarantee accuracy.
        """
        inv_type = inventory_type.upper()

        if inv_type == 'ROOM':
            inv = None
            if _is_uuid(inventory_id):
                inv = RoomInventory.objects.select_for_update().filter(id=inventory_id).first()
            if not inv and date:
                inv = RoomInventory.objects.select_for_update().filter(
                    room_type_id=inventory_id,
                    date=date,
                ).first()

            if not inv:
                raise InventoryNotFoundError(f"No room inventory record found for {inventory_id} on {date}")

            cls._clean_expired_holds_for_target('ROOM', str(inv.id))
            inv.refresh_from_db()

            available = inv.available_rooms
            return {
                'inventory_type': 'ROOM',
                'inventory_id': str(inv.id),
                'room_type_id': str(inv.room_type_id),
                'date': str(inv.date),
                'total_capacity': inv.total_rooms,
                'booked_capacity': inv.booked_rooms,
                'held_capacity': inv.held_rooms,
                'available_capacity': available,
                'is_available': available >= quantity,
            }

        elif inv_type == 'EXPERIENCE':
            slot = None
            if _is_uuid(inventory_id):
                slot = ExperienceSlot.objects.select_for_update().filter(id=inventory_id).first()
            if not slot and date:
                slot = ExperienceSlot.objects.select_for_update().filter(
                    experience_id=inventory_id,
                    date=date,
                ).first()

            if not slot:
                raise InventoryNotFoundError(f"No experience slot found for {inventory_id} on {date}")

            cls._clean_expired_holds_for_target('EXPERIENCE', str(slot.id))
            slot.refresh_from_db()

            available = slot.available_capacity
            return {
                'inventory_type': 'EXPERIENCE',
                'inventory_id': str(slot.id),
                'experience_id': str(slot.experience_id),
                'date': str(slot.date),
                'start_time': slot.start_time,
                'end_time': slot.end_time,
                'total_capacity': slot.total_capacity,
                'booked_capacity': slot.booked_capacity,
                'held_capacity': slot.held_capacity,
                'available_capacity': available,
                'is_available': available >= quantity,
            }

        else:
            raise ValueError(f"Unsupported inventory type: {inventory_type}")

    @classmethod
    @transaction.atomic
    def create_hold(
        cls,
        user=None,
        inventory_type: str = 'ROOM',
        inventory_id = None,
        date = None,
        quantity: int = 1,
        itinerary_version_id = None,
        booking_id = None,
        duration_mins: int = 15,
    ) -> InventoryHold:
        """
        Row-level locked hold creation in PostgreSQL.
        Enforces: booked + held <= total at all times.
        """
        inv_type = inventory_type.upper()

        if inv_type == 'ROOM':
            inv = None
            if _is_uuid(inventory_id):
                inv = RoomInventory.objects.select_for_update().filter(id=inventory_id).first()
            if not inv and date:
                inv = RoomInventory.objects.select_for_update().filter(
                    room_type_id=inventory_id,
                    date=date,
                ).first()

            if not inv:
                raise InventoryNotFoundError(f"No room inventory found for {inventory_id} on {date}")

            cls._clean_expired_holds_for_target('ROOM', str(inv.id))
            inv.refresh_from_db()

            if inv.available_rooms < quantity:
                raise InsufficientInventoryError(
                    f"Room type {inv.room_type_id} is sold out on {inv.date}. Only {inv.available_rooms} left.",
                    details={'available': inv.available_rooms, 'requested': quantity, 'date': str(inv.date)},
                )

            inv.held_rooms += quantity
            inv.save(update_fields=['held_rooms'])

            return InventoryHold.create_hold(
                inv_type='ROOM',
                inv_id=str(inv.id),
                quantity=quantity,
                duration_mins=duration_mins,
                user=user,
                booking_id=booking_id,
                itinerary_version_id=itinerary_version_id,
                date=inv.date,
            )

        elif inv_type == 'EXPERIENCE':
            slot = None
            if _is_uuid(inventory_id):
                slot = ExperienceSlot.objects.select_for_update().filter(id=inventory_id).first()
            if not slot and date:
                slot = ExperienceSlot.objects.select_for_update().filter(
                    experience_id=inventory_id,
                    date=date,
                ).first()

            if not slot:
                raise InventoryNotFoundError(f"No experience slot found for {inventory_id} on {date}")

            cls._clean_expired_holds_for_target('EXPERIENCE', str(slot.id))
            slot.refresh_from_db()

            if slot.available_capacity < quantity:
                raise InsufficientInventoryError(
                    f"Experience slot {slot.id} has insufficient capacity. Only {slot.available_capacity} left.",
                    details={'available': slot.available_capacity, 'requested': quantity, 'date': str(slot.date)},
                )

            slot.held_capacity += quantity
            slot.save(update_fields=['held_capacity'])

            return InventoryHold.create_hold(
                inv_type='EXPERIENCE',
                inv_id=str(slot.id),
                quantity=quantity,
                duration_mins=duration_mins,
                user=user,
                booking_id=booking_id,
                itinerary_version_id=itinerary_version_id,
                date=slot.date,
            )

        else:
            raise ValueError(f"Invalid inventory type: {inventory_type}")

    @classmethod
    @transaction.atomic
    def hold_room_inventory(cls, booking_id, room_type_id, dates: list, quantity: int = 1, user=None) -> list:
        """Legacy / helper method for multi-night room holds."""
        holds = []
        for date_val in dates:
            hold = cls.create_hold(
                user=user,
                inventory_type='ROOM',
                inventory_id=room_type_id,
                date=date_val,
                quantity=quantity,
                booking_id=booking_id,
            )
            holds.append(hold)
        return holds

    @classmethod
    @transaction.atomic
    def hold_experience_slot(cls, booking_id, slot_id, quantity: int = 1, user=None) -> InventoryHold:
        """Legacy / helper method for single experience slot hold."""
        return cls.create_hold(
            user=user,
            inventory_type='EXPERIENCE',
            inventory_id=slot_id,
            quantity=quantity,
            booking_id=booking_id,
        )

    @classmethod
    @transaction.atomic
    def get_hold(cls, hold_id, user=None) -> InventoryHold:
        """
        Retrieves hold and verifies user authorization.
        Eagerly checks expiration and transitions state if expired.
        """
        try:
            hold = InventoryHold.objects.select_for_update().get(id=hold_id)
        except InventoryHold.DoesNotExist:
            raise HoldNotFoundError(f"Inventory hold {hold_id} not found")

        if user and hold.user and hold.user != user:
            raise PermissionError("Unauthorized: You do not have permission to access this inventory hold.")

        if hold.status == 'ACTIVE' and hold.is_expired():
            cls._expire_single_hold(hold)
            hold.refresh_from_db()

        return hold

    @classmethod
    @transaction.atomic
    def release_hold(cls, hold_id, user=None) -> InventoryHold:
        """
        Releases an active hold, immediately restoring available capacity in PostgreSQL.
        """
        hold = cls.get_hold(hold_id, user=user)

        if hold.status == 'ACTIVE':
            if hold.inventory_type == 'ROOM':
                inv = RoomInventory.objects.select_for_update().filter(id=hold.inventory_id).first()
                if inv:
                    inv.held_rooms = max(0, inv.held_rooms - hold.quantity)
                    inv.save(update_fields=['held_rooms'])
            elif hold.inventory_type == 'EXPERIENCE':
                slot = ExperienceSlot.objects.select_for_update().filter(id=hold.inventory_id).first()
                if slot:
                    slot.held_capacity = max(0, slot.held_capacity - hold.quantity)
                    slot.save(update_fields=['held_capacity'])

            hold.status = 'RELEASED'
            hold.save(update_fields=['status'])

        return hold

    @classmethod
    @transaction.atomic
    def extend_hold(cls, hold_id, user=None, extra_minutes: int = 10) -> InventoryHold:
        """
        Extends the 15-minute hold window if the hold is still active.
        """
        hold = cls.get_hold(hold_id, user=user)

        if hold.status == 'EXPIRED' or hold.is_expired():
            cls._expire_single_hold(hold)
            raise HoldExpiredError("Cannot extend an expired hold.")

        if hold.status != 'ACTIVE':
            raise ValueError(f"Cannot extend hold with status '{hold.status}'.")

        hold.extend_hold(minutes=extra_minutes)
        return hold

    @classmethod
    @transaction.atomic
    def confirm_hold(cls, hold_id, booking_id=None) -> InventoryHold:
        """
        Transitions hold to CONFIRMED and transfers capacity from 'held' to 'booked'.
        Used by Phase 7 Booking flow.
        """
        try:
            hold = InventoryHold.objects.select_for_update().get(id=hold_id)
        except InventoryHold.DoesNotExist:
            raise HoldNotFoundError(f"Inventory hold {hold_id} not found")

        if hold.status == 'EXPIRED' or hold.is_expired():
            cls._expire_single_hold(hold)
            raise HoldExpiredError("Cannot confirm an expired hold.")

        if hold.status != 'ACTIVE':
            raise ValueError(f"Cannot confirm hold with status '{hold.status}'.")

        if hold.inventory_type == 'ROOM':
            inv = RoomInventory.objects.select_for_update().get(id=hold.inventory_id)
            inv.held_rooms = max(0, inv.held_rooms - hold.quantity)
            inv.booked_rooms += hold.quantity
            inv.save(update_fields=['held_rooms', 'booked_rooms'])
        elif hold.inventory_type == 'EXPERIENCE':
            slot = ExperienceSlot.objects.select_for_update().get(id=hold.inventory_id)
            slot.held_capacity = max(0, slot.held_capacity - hold.quantity)
            slot.booked_capacity += hold.quantity
            slot.save(update_fields=['held_capacity', 'booked_capacity'])

        hold.status = 'CONFIRMED'
        if booking_id:
            hold.booking_id = booking_id
            hold.save(update_fields=['status', 'booking_id'])
        else:
            hold.save(update_fields=['status'])

        return hold

    @classmethod
    @transaction.atomic
    def hold_itinerary(
        cls,
        user=None,
        components: list = None,
        itinerary_version_id=None,
        booking_id=None,
        duration_mins: int = 15,
    ) -> list:
        """
        Atomic batch hold of all components in an itinerary requiring inventory.
        Rolls back entirely if any single component cannot be held.
        """
        if not components:
            return []

        holds = []
        for comp in components:
            inv_type = comp.get('inventory_type')
            inv_id = comp.get('inventory_id')
            qty = comp.get('quantity', 1)
            comp_date = comp.get('date')

            hold = cls.create_hold(
                user=user,
                inventory_type=inv_type,
                inventory_id=inv_id,
                date=comp_date,
                quantity=qty,
                itinerary_version_id=itinerary_version_id,
                booking_id=booking_id,
                duration_mins=duration_mins,
            )
            holds.append(hold)

        return holds

    @classmethod
    @transaction.atomic
    def release_expired_holds(cls) -> int:
        """
        Periodic worker sweep that releases all expired holds.
        """
        now = timezone.now()
        expired_holds = InventoryHold.objects.select_for_update().filter(
            status='ACTIVE',
            expires_at__lt=now,
        )

        count = 0
        for hold in expired_holds:
            cls._expire_single_hold(hold)
            count += 1

        logger.info(f"Released {count} expired inventory holds.")
        return count

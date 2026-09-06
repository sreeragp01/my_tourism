from django.db import transaction
from django.utils import timezone
from .models import InventoryHold
from apps.accommodations.models import RoomInventory
from apps.experiences.models import ExperienceSlot

class InsufficientInventoryError(Exception):
    pass

class InventoryService:
    @classmethod
    @transaction.atomic
    def hold_room_inventory(cls, booking_id, room_type_id, dates: list, quantity: int = 1) -> list:
        holds = []
        for date_val in dates:
            # PostgreSQL Row-Level Lock
            inv = RoomInventory.objects.select_for_update().get(room_type_id=room_type_id, date=date_val)
            if inv.available_rooms < quantity:
                raise InsufficientInventoryError(f"Room type {room_type_id} is sold out on {date_val}")

            inv.held_rooms += quantity
            inv.save()

            hold = InventoryHold.create_hold(
                booking_id=booking_id,
                inv_type='ROOM',
                inv_id=str(inv.id),
                quantity=quantity,
                duration_mins=15,
            )
            holds.append(hold)
        return holds

    @classmethod
    @transaction.atomic
    def hold_experience_slot(cls, booking_id, slot_id, quantity: int = 1) -> InventoryHold:
        # PostgreSQL Row-Level Lock
        slot = ExperienceSlot.objects.select_for_update().get(id=slot_id)
        if slot.available_capacity < quantity:
            raise InsufficientInventoryError(f"Experience slot {slot_id} does not have {quantity} seats available")

        slot.held_capacity += quantity
        slot.save()

        return InventoryHold.create_hold(
            booking_id=booking_id,
            inv_type='EXPERIENCE',
            inv_id=str(slot.id),
            quantity=quantity,
            duration_mins=15,
        )

    @classmethod
    @transaction.atomic
    def release_expired_holds(cls):
        now = timezone.now()
        expired_holds = InventoryHold.objects.select_for_update().filter(status='ACTIVE', expires_at__lt=now)

        for hold in expired_holds:
            if hold.inventory_type == 'ROOM':
                inv = RoomInventory.objects.select_for_update().get(id=hold.inventory_id)
                inv.held_rooms = max(0, inv.held_rooms - hold.quantity)
                inv.save()
            elif hold.inventory_type == 'EXPERIENCE':
                slot = ExperienceSlot.objects.select_for_update().get(id=hold.inventory_id)
                slot.held_capacity = max(0, slot.held_capacity - hold.quantity)
                slot.save()

            hold.status = 'EXPIRED'
            hold.save()

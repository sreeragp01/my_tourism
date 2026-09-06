import uuid
from django.db import models
from django.utils import timezone
from datetime import timedelta

class InventoryHold(models.Model):
    STATUS_CHOICES = [
        ('ACTIVE', 'Active'),
        ('CONSUMED', 'Consumed / Booked'),
        ('EXPIRED', 'Expired'),
        ('RELEASED', 'Released'),
    ]

    TYPE_CHOICES = [
        ('ROOM', 'Room Inventory'),
        ('EXPERIENCE', 'Experience Slot'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    booking_id = models.UUIDField(db_index=True)
    inventory_type = models.CharField(max_length=20, choices=TYPE_CHOICES)
    inventory_id = models.CharField(max_length=128, db_index=True)
    quantity = models.PositiveIntegerField(default=1)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='ACTIVE')
    expires_at = models.DateTimeField(db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)

    @classmethod
    def create_hold(cls, booking_id, inv_type, inv_id, quantity=1, duration_mins=15):
        expires = timezone.now() + timedelta(minutes=duration_mins)
        return cls.objects.create(
            booking_id=booking_id,
            inventory_type=inv_type,
            inventory_id=inv_id,
            quantity=quantity,
            expires_at=expires,
            status='ACTIVE',
        )

    def is_valid(self):
        return self.status == 'ACTIVE' and timezone.now() < self.expires_at

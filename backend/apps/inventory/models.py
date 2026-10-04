import uuid
from datetime import timedelta
from django.conf import settings
from django.db import models
from django.utils import timezone


class InventoryHold(models.Model):
    STATUS_CHOICES = [
        ('ACTIVE', 'Active'),
        ('CONFIRMED', 'Confirmed / Booked'),
        ('CONSUMED', 'Consumed / Booked'),
        ('EXPIRED', 'Expired'),
        ('RELEASED', 'Released'),
        ('CANCELLED', 'Cancelled'),
    ]

    TYPE_CHOICES = [
        ('ROOM', 'Room Inventory'),
        ('EXPERIENCE', 'Experience Slot'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name='inventory_holds',
    )
    booking_id = models.UUIDField(null=True, blank=True, db_index=True)
    itinerary_version_id = models.CharField(max_length=128, null=True, blank=True, db_index=True)
    date = models.DateField(null=True, blank=True, db_index=True)
    inventory_type = models.CharField(max_length=20, choices=TYPE_CHOICES)
    inventory_id = models.CharField(max_length=128, db_index=True)
    quantity = models.PositiveIntegerField(default=1)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='ACTIVE')
    expires_at = models.DateTimeField(db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    @classmethod
    def create_hold(
        cls,
        inv_type: str,
        inv_id,
        quantity: int = 1,
        duration_mins: int = 15,
        user=None,
        booking_id=None,
        itinerary_version_id=None,
        date=None,
    ):
        expires = timezone.now() + timedelta(minutes=duration_mins)
        return cls.objects.create(
            user=user,
            booking_id=booking_id,
            itinerary_version_id=itinerary_version_id,
            date=date,
            inventory_type=inv_type,
            inventory_id=str(inv_id),
            quantity=quantity,
            expires_at=expires,
            status='ACTIVE',
        )

    def is_valid(self) -> bool:
        return self.status == 'ACTIVE' and not self.is_expired()

    def is_expired(self) -> bool:
        return timezone.now() >= self.expires_at

    @property
    def remaining_seconds(self) -> int:
        if self.status != 'ACTIVE' or self.is_expired():
            return 0
        diff = (self.expires_at - timezone.now()).total_seconds()
        return max(0, int(diff))

    def extend_hold(self, minutes: int = 10) -> bool:
        if self.status == 'ACTIVE' and not self.is_expired():
            self.expires_at = self.expires_at + timedelta(minutes=minutes)
            self.save(update_fields=['expires_at'])
            return True
        return False

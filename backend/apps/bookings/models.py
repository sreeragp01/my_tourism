import uuid
from django.db import models
from django.conf import settings

class Booking(models.Model):
    STATUS_CHOICES = [
        ('DRAFT', 'Draft'),
        ('PENDING_PAYMENT', 'Pending Payment'),
        ('PAYMENT_PROCESSING', 'Payment Processing'),
        ('PAYMENT_FAILED', 'Payment Failed'),
        ('CONFIRMED', 'Confirmed'),
        ('CANCEL_REQUESTED', 'Cancel Requested'),
        ('CANCELLED', 'Cancelled'),
        ('REFUND_PENDING', 'Refund Pending'),
        ('REFUNDED', 'Refunded'),
        ('IN_PROGRESS', 'In Progress'),
        ('COMPLETED', 'Completed'),
        ('EXPIRED', 'Expired'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    booking_reference = models.CharField(max_length=32, unique=True, db_index=True)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT, related_name='bookings')
    itinerary_version_id = models.CharField(max_length=64, blank=True, null=True, db_index=True)
    trip_title = models.CharField(max_length=255)
    start_date = models.DateField()
    end_date = models.DateField()
    travelers_count = models.PositiveIntegerField(default=2)
    primary_guest_name = models.CharField(max_length=150)
    primary_guest_phone = models.CharField(max_length=20)
    primary_guest_email = models.EmailField()
    status = models.CharField(max_length=32, choices=STATUS_CHOICES, default='DRAFT', db_index=True)
    subtotal = models.DecimalField(max_digits=12, decimal_places=2, default=0.00)
    tax = models.DecimalField(max_digits=12, decimal_places=2, default=0.00)
    platform_fee = models.DecimalField(max_digits=12, decimal_places=2, default=0.00)
    total_amount = models.DecimalField(max_digits=12, decimal_places=2)
    currency = models.CharField(max_length=3, default='INR')
    idempotency_key = models.CharField(max_length=128, unique=True, db_index=True)
    green_trip_score = models.PositiveIntegerField(default=85)
    digital_pass_token = models.CharField(max_length=128, blank=True, null=True, unique=True, db_index=True)
    qr_code_url = models.URLField(blank=True, null=True)
    confirmed_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.booking_reference} ({self.status}) - ₹{self.total_amount}"


class BookingItem(models.Model):
    TYPE_CHOICES = [
        ('ROOM', 'Room Stay'),
        ('EXPERIENCE', 'Local Experience'),
        ('TRANSPORT', 'Chauffeur Transport'),
        ('PACKAGE', 'Curated Package'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    booking = models.ForeignKey(Booking, on_delete=models.CASCADE, related_name='items')
    inventory_hold = models.ForeignKey(
        'inventory.InventoryHold',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='booking_items',
    )
    item_type = models.CharField(max_length=20, choices=TYPE_CHOICES)
    entity_type = models.CharField(max_length=50, blank=True, default='')
    entity_id = models.CharField(max_length=100, blank=True, default='')
    title = models.CharField(max_length=255)
    date = models.DateField()
    units = models.PositiveIntegerField(default=1)
    quantity = models.PositiveIntegerField(default=1)
    unit_price = models.DecimalField(max_digits=10, decimal_places=2)
    subtotal = models.DecimalField(max_digits=10, decimal_places=2)
    total_price = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    provider_org_id = models.UUIDField(null=True, blank=True, db_index=True)

    def save(self, *args, **kwargs):
        # Synchronize quantity/units and total_price/subtotal
        if self.units and not self.quantity:
            self.quantity = self.units
        elif self.quantity and not self.units:
            self.units = self.quantity
        if not self.total_price and self.subtotal:
            self.total_price = self.subtotal
        elif not self.subtotal and self.total_price:
            self.subtotal = self.total_price
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.title} x{self.quantity} (₹{self.total_price})"

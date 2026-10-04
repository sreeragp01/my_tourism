import uuid
from django.db import models
from apps.bookings.models import Booking

class Payment(models.Model):
    STATUS_CHOICES = [
        ('INITIATED', 'Initiated'),
        ('SUCCESS', 'Success'),
        ('FAILED', 'Failed'),
        ('REFUNDED', 'Refunded'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    booking = models.ForeignKey(Booking, on_delete=models.PROTECT, related_name='payments')
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    currency = models.CharField(max_length=3, default='INR')
    gateway = models.CharField(max_length=50, default='RAZORPAY')
    gateway_order_id = models.CharField(max_length=128, blank=True, null=True, db_index=True)
    gateway_payment_id = models.CharField(max_length=128, blank=True, null=True, db_index=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='INITIATED')
    idempotency_key = models.CharField(max_length=128, unique=True, db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)

class ProcessedWebhookEvent(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    event_id = models.CharField(max_length=128, unique=True, db_index=True)
    event_type = models.CharField(max_length=100)
    raw_payload = models.JSONField()
    processed_at = models.DateTimeField(auto_now_add=True)

import uuid
from django.db import models

class OutboxEvent(models.Model):
    """
    Transactional Outbox Pattern entity. Commits within the same PostgreSQL
    transaction as the business operation, guaranteeing zero event loss.
    Polled/dispatched asynchronously by Celery workers to downstream consumers.
    """
    STATUS_CHOICES = [
        ('PENDING', 'Pending Dispatch'),
        ('PROCESSING', 'Processing'),
        ('PROCESSED', 'Processed / Dispatched'),
        ('FAILED', 'Failed / Retrying'),
        ('DEAD_LETTER', 'Dead Letter / Max Retries Exceeded'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    event_type = models.CharField(max_length=128, db_index=True)  # e.g. BookingConfirmed, InventoryHeld, SAFETY_SOS_TRIGGERED
    aggregate_type = models.CharField(max_length=64, db_index=True) # Booking, Payment, AIPlan, SafetyAlert
    aggregate_id = models.CharField(max_length=128, db_index=True)
    payload = models.JSONField()
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='PENDING', db_index=True)
    retry_count = models.PositiveIntegerField(default=0)
    next_retry_at = models.DateTimeField(null=True, blank=True, db_index=True)
    error_message = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    processed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ['created_at']

    def __str__(self):
        return f"{self.event_type} ({self.status}) - {self.id}"


class ProcessedEvent(models.Model):
    """
    Consumer-side idempotency record to ensure events are never handled twice.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    event_id = models.UUIDField(unique=True, db_index=True)
    consumer_name = models.CharField(max_length=128, db_index=True)
    processed_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.consumer_name}:{self.event_id}"

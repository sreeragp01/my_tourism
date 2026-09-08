import uuid
import secrets
from django.db import models
from django.conf import settings
from django.utils import timezone


def generate_share_token_string():
    return secrets.token_urlsafe(32)


class TripShareToken(models.Model):
    """
    Cryptographic temporary trip share token.
    Allows family/friends to view sanitized live trip itinerary and location
    without accessing PII, payment info, or authentication credentials.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    booking = models.ForeignKey(
        'bookings.Booking',
        on_delete=models.CASCADE,
        related_name='share_tokens'
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='created_share_tokens'
    )
    token = models.CharField(
        max_length=64,
        unique=True,
        default=generate_share_token_string,
        db_index=True
    )
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField(db_index=True)
    is_revoked = models.BooleanField(default=False)

    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['token', 'is_revoked', 'expires_at']),
        ]

    @property
    def is_valid(self) -> bool:
        return (not self.is_revoked) and (timezone.now() < self.expires_at)

    def revoke(self):
        self.is_revoked = True
        self.save(update_fields=['is_revoked'])

    def __str__(self):
        status = "Active" if self.is_valid else "Expired/Revoked"
        return f"ShareToken({self.token[:8]}... - {status})"


class SafetyAlert(models.Model):
    """
    Emergency SOS and safety alert logs triggered by travelers or background monitor.
    Directly connected to Kerala Tourist Police (1800-425-4747) and National 112 services.
    """
    ALERT_TYPES = [
        ('SOS_112', 'National Emergency SOS 112'),
        ('TOURIST_POLICE', 'Kerala Tourist Police 1800-425-4747'),
        ('MEDICAL', 'Medical Assistance 108'),
        ('WOMEN_SAFETY', 'Women Safety Mitra 181'),
        ('HIGHWAY_PATROL', 'Highway Police Control'),
        ('CUSTOM', 'Custom Safety Assistance'),
    ]

    STATUS_CHOICES = [
        ('TRIGGERED', 'Triggered'),
        ('ACKNOWLEDGED', 'Acknowledged'),
        ('RESOLVED', 'Resolved'),
        ('FALSE_ALARM', 'False Alarm'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='safety_alerts'
    )
    booking = models.ForeignKey(
        'bookings.Booking',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='safety_alerts'
    )
    alert_type = models.CharField(max_length=30, choices=ALERT_TYPES, default='SOS_112')
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)
    location_name = models.CharField(max_length=255, blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='TRIGGERED')
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    resolved_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"SafetyAlert({self.alert_type} by {self.user.email} - {self.status})"

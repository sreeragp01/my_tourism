import uuid
from django.db import models
from django.conf import settings


class Notification(models.Model):
    NOTIFICATION_TYPES = [
        ('PROXIMITY', 'Proximity Waypoint Trigger'),
        ('WEATHER_ALERT', 'Weather & Monsoon Advisory'),
        ('SCHEDULE_UPDATE', 'Itinerary Schedule Update'),
        ('SAFETY_ALERT', 'Safety & Emergency Alert'),
        ('TRIP_MILESTONE', 'Trip Milestone & Check-in'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='notifications'
    )
    title = models.CharField(max_length=255)
    message = models.TextField()
    notification_type = models.CharField(max_length=50, choices=NOTIFICATION_TYPES, default='SCHEDULE_UPDATE')
    data = models.JSONField(default=dict, blank=True)
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user', 'is_read', '-created_at']),
        ]

    def __str__(self):
        return f"Notification({self.user.email} - {self.notification_type}: {self.title})"


class DeviceToken(models.Model):
    PLATFORM_CHOICES = [
        ('ANDROID', 'Android'),
        ('IOS', 'iOS'),
        ('WEB', 'Web Browser'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='device_tokens'
    )
    token = models.CharField(max_length=255, unique=True)
    platform = models.CharField(max_length=20, choices=PLATFORM_CHOICES, default='ANDROID')
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-updated_at']

    def __str__(self):
        return f"DeviceToken({self.user.email} - {self.platform})"


class NotificationPreference(models.Model):
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='notification_preferences'
    )
    proximity_enabled = models.BooleanField(default=True)
    weather_alerts_enabled = models.BooleanField(default=True)
    schedule_updates_enabled = models.BooleanField(default=True)
    safety_alerts_enabled = models.BooleanField(default=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Preferences({self.user.email})"


class ProximityEvent(models.Model):
    """
    Deduplication and cooldown ledger for proximity triggers.
    Prevents repeated popups when a traveler hovers near a waypoint.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='proximity_events'
    )
    waypoint_id = models.CharField(max_length=120, db_index=True)
    event_type = models.CharField(max_length=40)  # APPROACH_500M, ARRIVAL_200M
    triggered_at = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        ordering = ['-triggered_at']
        indexes = [
            models.Index(fields=['user', 'waypoint_id', 'event_type', '-triggered_at']),
        ]

    def __str__(self):
        return f"ProximityEvent({self.user.email} - {self.waypoint_id}: {self.event_type})"

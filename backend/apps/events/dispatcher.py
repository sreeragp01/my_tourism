import logging
from datetime import timedelta
from typing import Dict, Any
from django.utils import timezone
from django.db import transaction, connection
from django.conf import settings
from django.core.mail import send_mail
from .models import OutboxEvent, ProcessedEvent

logger = logging.getLogger(__name__)

class EventDispatcher:
    """
    Handles reliable, fault-tolerant asynchronous dispatch of OutboxEvents
    (Transactional Outbox Pattern with exponential backoff and dead-letter queue).
    """

    @classmethod
    def dispatch_pending_events(cls, batch_size: int = 100):
        # 1. Crash Recovery: Reset stuck events (>5 minutes in PROCESSING state)
        stuck_threshold = timezone.now() - timedelta(minutes=5)
        stuck_events = OutboxEvent.objects.filter(
            status='PROCESSING',
            processed_at__isnull=True,
            created_at__lt=stuck_threshold
        )
        for stuck in stuck_events:
            if stuck.retry_count >= 5:
                stuck.status = 'DEAD_LETTER'
                stuck.error_message = "Stuck in processing; max retries exceeded."
                stuck.save(update_fields=['status', 'error_message'])
            else:
                stuck.status = 'PENDING'
                stuck.retry_count += 1
                stuck.save(update_fields=['status', 'retry_count'])

        # 2. Select eligible events: PENDING or FAILED with reached next_retry_at
        now = timezone.now()
        eligible_filter = (
            (OutboxEvent.objects.filter(status='PENDING', next_retry_at__isnull=True)) |
            (OutboxEvent.objects.filter(status__in=['PENDING', 'FAILED'], next_retry_at__lte=now))
        )

        with transaction.atomic():
            # Safe concurrency row-locking
            if connection.vendor == 'postgresql':
                events = list(eligible_filter.select_for_update(skip_locked=True).order_by('created_at')[:batch_size])
            else:
                events = list(eligible_filter.order_by('created_at')[:batch_size])

            for event in events:
                try:
                    event.status = 'PROCESSING'
                    event.save(update_fields=['status'])

                    # Route and handle event
                    cls._handle_event(event)

                    event.status = 'PROCESSED'
                    event.processed_at = timezone.now()
                    event.error_message = None
                    event.save(update_fields=['status', 'processed_at', 'error_message'])
                    logger.info(f"Successfully processed OutboxEvent {event.id} ({event.event_type})")
                except Exception as e:
                    logger.exception(f"Error dispatching OutboxEvent {event.id}: {e}")
                    event.retry_count += 1
                    event.error_message = str(e)
                    if event.retry_count >= 5:
                        event.status = 'DEAD_LETTER'
                        event.next_retry_at = None
                        logger.error(f"OutboxEvent {event.id} moved to DEAD_LETTER after 5 failed retries.")
                    else:
                        event.status = 'FAILED'
                        backoff_seconds = 30 * (2 ** (event.retry_count - 1))
                        event.next_retry_at = timezone.now() + timedelta(seconds=backoff_seconds)
                        logger.warning(f"OutboxEvent {event.id} marked FAILED; retry {event.retry_count} scheduled in {backoff_seconds}s.")
                    event.save(update_fields=['status', 'retry_count', 'next_retry_at', 'error_message'])

    @classmethod
    def _handle_event(cls, event: OutboxEvent):
        """
        Routes the outbox event to its appropriate domain consumer with idempotency checking.
        """
        if event.event_type == 'SAFETY_SOS_TRIGGERED':
            cls._handle_safety_sos(event)
        else:
            # Generic domain event logging & idempotency recording
            consumer_name = f"GeneralConsumer_{event.aggregate_type}"
            ProcessedEvent.objects.get_or_create(
                event_id=event.id,
                consumer_name=consumer_name
            )
            logger.info(f"Dispatched {event.event_type} for {event.aggregate_type}:{event.aggregate_id}")

    @classmethod
    def _handle_safety_sos(cls, event: OutboxEvent):
        """
        High-reliability emergency SOS dispatcher.
        Sends emergency alerts to traveler's designated emergency contact with live GPS pin.
        """
        consumer_name = "SafetySOSConsumer"
        if ProcessedEvent.objects.filter(event_id=event.id, consumer_name=consumer_name).exists():
            logger.info(f"Safety SOS event {event.id} already processed. Skipping duplicate dispatch.")
            return

        payload = event.payload or {}
        traveler_name = payload.get('traveler_name', 'KeraLink Traveler')
        traveler_email = payload.get('user_email', '')
        traveler_phone = payload.get('traveler_phone', 'Not provided')
        alert_type = payload.get('alert_type', 'SOS_112')
        location_name = payload.get('location_name', 'GPS Coordinates')
        lat = payload.get('latitude')
        lng = payload.get('longitude')
        emergency_email = payload.get('emergency_contact_email')
        emergency_name = payload.get('emergency_contact_name') or 'Emergency Contact'
        emergency_phone = payload.get('emergency_contact_phone') or 'Not provided'
        blood_group = payload.get('blood_group') or 'Not specified'
        medical_conditions = payload.get('medical_conditions') or 'None reported'
        allergies = payload.get('allergies') or 'None reported'

        if lat is not None and lng is not None:
            map_url = f"https://www.google.com/maps?q={lat},{lng}"
            coordinates_str = f"{lat}, {lng}"
        else:
            map_url = "Location sharing not consented or GPS unavailable"
            coordinates_str = "Unavailable"

        subject = f"[CRITICAL EMERGENCY SOS] KeraLink Traveler Alert: {traveler_name}"

        text_message = f"""
CRITICAL EMERGENCY SOS ALERT - KERALINK TOURISM PLATFORM
=========================================================

An emergency SOS signal was initiated by {traveler_name}.

Traveler Details:
- Name: {traveler_name}
- Email: {traveler_email}
- Phone: {traveler_phone}
- Alert Type: {alert_type}

Location Details:
- Description: {location_name}
- Coordinates: {coordinates_str}
- Live Map: {map_url}

Medical & First-Responder Profile:
- Blood Group: {blood_group}
- Medical Conditions: {medical_conditions}
- Allergies: {allergies}

Designated Emergency Contact:
- Name: {emergency_name}
- Phone: {emergency_phone}

Official Emergency Helplines (Kerala):
- National Emergency Services: 112
- Kerala Tourist Police Helpline: 1800-425-4747 (24x7 Multi-lingual)
- Emergency Medical Care (Ambulance): 108
- Highway Patrol: 9846100100
"""

        html_message = f"""
<!DOCTYPE html>
<html>
<body style="font-family: Arial, sans-serif; line-height: 1.6; color: #1e293b; background-color: #f8fafc; padding: 20px;">
  <div style="max-width: 600px; margin: 0 auto; background: #ffffff; border-radius: 8px; border: 2px solid #ef4444; overflow: hidden;">
    <div style="background-color: #dc2626; color: white; padding: 18px 24px;">
      <h2 style="margin: 0; font-size: 20px;">CRITICAL EMERGENCY SOS ALERT</h2>
      <p style="margin: 4px 0 0 0; opacity: 0.9; font-size: 14px;">KeraLink Traveler Safety System</p>
    </div>
    <div style="padding: 24px;">
      <p style="font-size: 16px; font-weight: bold; color: #dc2626; margin-top: 0;">
        An urgent SOS alert has been triggered for {traveler_name}.
      </p>

      <table style="width: 100%; border-collapse: collapse; margin-bottom: 20px;">
        <tr style="border-bottom: 1px solid #e2e8f0;"><td style="padding: 8px 0; font-weight: bold;">Alert Type:</td><td style="padding: 8px 0;">{alert_type}</td></tr>
        <tr style="border-bottom: 1px solid #e2e8f0;"><td style="padding: 8px 0; font-weight: bold;">Traveler Email:</td><td style="padding: 8px 0;">{traveler_email}</td></tr>
        <tr style="border-bottom: 1px solid #e2e8f0;"><td style="padding: 8px 0; font-weight: bold;">Traveler Phone:</td><td style="padding: 8px 0;">{traveler_phone}</td></tr>
        <tr style="border-bottom: 1px solid #e2e8f0;"><td style="padding: 8px 0; font-weight: bold;">Location:</td><td style="padding: 8px 0;">{location_name}</td></tr>
        <tr style="border-bottom: 1px solid #e2e8f0;"><td style="padding: 8px 0; font-weight: bold;">Blood Group:</td><td style="padding: 8px 0;">{blood_group}</td></tr>
        <tr style="border-bottom: 1px solid #e2e8f0;"><td style="padding: 8px 0; font-weight: bold;">Medical Notes:</td><td style="padding: 8px 0;">{medical_conditions}</td></tr>
        <tr style="border-bottom: 1px solid #e2e8f0;"><td style="padding: 8px 0; font-weight: bold;">Allergies:</td><td style="padding: 8px 0;">{allergies}</td></tr>
      </table>

      {f'<div style="text-align: center; margin: 24px 0;"><a href="{map_url}" style="background-color: #dc2626; color: white; padding: 12px 24px; border-radius: 6px; text-decoration: none; font-weight: bold; display: inline-block;">Open Live Location in Google Maps</a></div>' if lat is not None else ''}

      <div style="background-color: #fef2f2; border-left: 4px solid #ef4444; padding: 12px; margin-top: 20px;">
        <h4 style="margin: 0 0 6px 0; color: #991b1b;">Immediate Helplines:</h4>
        <p style="margin: 0; font-size: 14px; color: #7f1d1d;">
          - National Emergency: <strong>112</strong><br>
          - Kerala Tourist Police: <strong>1800-425-4747</strong><br>
          - State Ambulance: <strong>108</strong>
        </p>
      </div>
    </div>
  </div>
</body>
</html>
"""

        recipients = []
        if emergency_email:
            recipients.append(emergency_email)
        if traveler_email and traveler_email not in recipients:
            recipients.append(traveler_email)

        from_email = getattr(settings, 'DEFAULT_FROM_EMAIL', 'safety@keralink.travel')

        if recipients:
            send_mail(
                subject=subject,
                message=text_message,
                from_email=from_email,
                recipient_list=recipients,
                html_message=html_message,
                fail_silently=False
            )
            logger.info(f"Dispatched emergency SOS notification to {recipients}")
        else:
            logger.warning(f"No emergency contact email found for SOS event {event.id}. Logged alert details.")

        # Record consumer idempotency
        ProcessedEvent.objects.create(
            event_id=event.id,
            consumer_name=consumer_name
        )

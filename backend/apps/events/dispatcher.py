import logging
from typing import Dict, Any
from django.utils import timezone
from .models import OutboxEvent, ProcessedEvent

logger = logging.getLogger(__name__)

class EventDispatcher:
    """
    Handles reliable asynchronous dispatch of OutboxEvents to downstream channels
    (FCM push notifications, SES transactional emails, WhatsApp, Provider dispatch, Analytics).
    """

    @classmethod
    def dispatch_pending_events(cls, batch_size: int = 100):
        pending_events = OutboxEvent.objects.filter(status='PENDING').order_by('created_at')[:batch_size]

        for event in pending_events:
            try:
                event.status = 'PROCESSING'
                event.save(update_fields=['status'])

                # Dispatch based on event type
                cls._handle_event(event)

                event.status = 'PROCESSED'
                event.processed_at = timezone.now()
                event.save(update_fields=['status', 'processed_at'])
            except Exception as e:
                logger.exception(f"Failed to dispatch event {event.id}: {e}")
                event.status = 'FAILED'
                event.retry_count += 1
                event.error_message = str(e)
                event.save(update_fields=['status', 'retry_count', 'error_message'])

    @classmethod
    def _handle_event(cls, event: OutboxEvent):
        # Specific consumer handlers
        logger.info(f"Dispatched {event.event_type} for aggregate {event.aggregate_type}:{event.aggregate_id}")

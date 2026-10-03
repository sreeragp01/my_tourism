import logging
from celery import shared_task
from .dispatcher import EventDispatcher

logger = logging.getLogger(__name__)

@shared_task
def process_outbox_events_task(batch_size: int = 100):
    """
    Periodic Celery / background worker task to poll pending OutboxEvent records
    and dispatch them reliably with retry tracking.
    """
    try:
        EventDispatcher.dispatch_pending_events(batch_size=batch_size)
    except Exception as e:
        logger.error(f"Error processing outbox events: {str(e)}")

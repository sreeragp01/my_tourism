import logging
from .services import InventoryService

logger = logging.getLogger(__name__)

def cleanup_expired_holds_task():
    """
    Periodic worker task (run every 60 seconds) to find and release
    stale 15-minute locks on rooms and experience seats.
    """
    try:
        InventoryService.release_expired_holds()
        logger.info("Successfully released expired inventory holds.")
    except Exception as e:
        logger.error(f"Failed to release expired inventory holds: {str(e)}")

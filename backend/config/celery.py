import os
from celery import Celery

# Set the default Django settings module for the 'celery' program.
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings.prod')

app = Celery('keralink')

# Using a string here means the worker doesn't have to serialize
# the configuration object to child processes.
# - namespace='CELERY' means all celery-related configuration keys
#   should have a `CELERY_` prefix in settings.py.
app.config_from_object('django.conf:settings', namespace='CELERY')

# Load task modules from all registered Django apps.
app.autodiscover_tasks()

# Celery Beat Periodic Tasks Schedule
# Note: Cleanup task is cleanup_expired_holds_task (exact name from apps.inventory.tasks)
app.conf.beat_schedule = {
    'process-outbox-every-15-seconds': {
        'task': 'apps.events.tasks.process_outbox_events_task',
        'schedule': 15.0,
    },
    'cleanup-expired-holds-every-60-seconds': {
        'task': 'apps.inventory.tasks.cleanup_expired_holds_task',
        'schedule': 60.0,
    },
}

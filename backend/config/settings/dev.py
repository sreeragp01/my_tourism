import os
from .base import *

# Local Development Settings
DEBUG = True

SECRET_KEY = os.environ.get('DJANGO_SECRET_KEY', 'keralink-dev-secret-key-local-only-do-not-use-in-prod')

ALLOWED_HOSTS = ['*']

CORS_ALLOW_ALL_ORIGINS = True
CORS_ALLOW_CREDENTIALS = True

# In dev, if no SMTP user is provided, fall back to console email backend
if not os.environ.get('EMAIL_HOST_USER'):
    EMAIL_BACKEND = 'django.core.mail.backends.console.EmailBackend'

# Allow payment simulator in local development
ALLOW_PAYMENT_SIMULATOR = True


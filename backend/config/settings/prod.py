import os
from django.core.exceptions import ImproperlyConfigured
from .base import *

# Production Settings
DEBUG = False

SECRET_KEY = os.environ.get('DJANGO_SECRET_KEY')
if not SECRET_KEY:
    raise ImproperlyConfigured("DJANGO_SECRET_KEY environment variable is strictly required in production.")

JWT_SIGNING_KEY = os.environ.get('JWT_SIGNING_KEY')
if not JWT_SIGNING_KEY:
    raise ImproperlyConfigured("JWT_SIGNING_KEY environment variable is strictly required in production (must be distinct from DJANGO_SECRET_KEY).")

hosts_raw = os.environ.get('DJANGO_ALLOWED_HOSTS', '')
ALLOWED_HOSTS = [h.strip() for h in hosts_raw.split(',') if h.strip()]
if not ALLOWED_HOSTS:
    raise ImproperlyConfigured("DJANGO_ALLOWED_HOSTS environment variable is strictly required in production.")

# CORS & CSRF Whitelist
CORS_ALLOW_ALL_ORIGINS = False
CORS_ALLOW_CREDENTIALS = True

# Reverse Proxy & SSL Configuration (Render / Cloudflare / AWS)
SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
SECURE_SSL_REDIRECT = os.environ.get('SECURE_SSL_REDIRECT', 'True').lower() in ('true', '1', 'yes')
SECURE_REDIRECT_EXEMPT = [r'^healthz/?$']

SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
SECURE_HSTS_SECONDS = 31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True
SECURE_CONTENT_TYPE_NOSNIFF = True
X_FRAME_OPTIONS = 'DENY'

# Shared Cache Architecture (Redis for Atomic DRF Throttles & Session Sync)
REDIS_URL = os.environ.get('REDIS_URL', 'redis://127.0.0.1:6379/1')
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.redis.RedisCache',
        'LOCATION': REDIS_URL,
    }
}

# Production Observability (Sentry with PII Scrubber)
SENTRY_DSN = os.environ.get('SENTRY_DSN')
if SENTRY_DSN:
    try:
        import sentry_sdk
        from sentry_sdk.integrations.django import DjangoIntegration
        from sentry_sdk.integrations.celery import CeleryIntegration

        def strip_sensitive_data(event, hint):
            if 'request' in event and 'data' in event['request']:
                req_data = event['request']['data']
                if isinstance(req_data, dict):
                    for sensitive_key in ['password', 'otp', 'token', 'secret', 'medical_notes']:
                        if sensitive_key in req_data:
                            req_data[sensitive_key] = '[REDACTED]'
            return event

        sentry_sdk.init(
            dsn=SENTRY_DSN,
            integrations=[DjangoIntegration(), CeleryIntegration()],
            traces_sample_rate=float(os.environ.get('SENTRY_TRACES_SAMPLE_RATE', '0.1')),
            send_default_pii=False,
            before_send=strip_sensitive_data,
        )
    except ImportError:
        pass

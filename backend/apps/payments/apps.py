from django.apps import AppConfig
from django.core.checks import Error, register

@register('security', 'deploy')
def check_production_payment_configuration(app_configs, **kwargs):
    """
    Startup & deployment check:
    If payments are enabled and ALLOW_PAYMENT_SIMULATOR is False, prevent the application
    from running with missing or placeholder Razorpay keys.
    """
    from django.conf import settings
    errors = []
    payments_enabled = getattr(settings, 'PAYMENTS_ENABLED', False)
    allow_simulator = getattr(settings, 'ALLOW_PAYMENT_SIMULATOR', False)

    if payments_enabled and not allow_simulator:
        key_id = getattr(settings, 'RAZORPAY_KEY_ID', '')
        key_secret = getattr(settings, 'RAZORPAY_KEY_SECRET', '')
        if not key_id or not key_secret or key_id.startswith('rzp_test_placeholder'):
            errors.append(
                Error(
                    'PAYMENTS_ENABLED is True, but valid Razorpay credentials are missing and ALLOW_PAYMENT_SIMULATOR is False. Running with PaymentSimulator in production is strictly prohibited.',
                    hint='Provide genuine production RAZORPAY_KEY_ID and RAZORPAY_KEY_SECRET, set PAYMENTS_ENABLED=False, or explicitly set ALLOW_PAYMENT_SIMULATOR=True for local testing.',
                    id='payments.E001',
                )
            )
    return errors

class PaymentsConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'apps.payments'
    verbose_name = 'Payments & Escrow Engine'

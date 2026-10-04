from abc import ABC, abstractmethod
from decimal import Decimal
import hmac
import hashlib
import json
import logging

logger = logging.getLogger(__name__)

class PaymentGateway(ABC):
    @abstractmethod
    def create_order(self, amount_inr: float, currency: str, receipt: str, notes: dict) -> dict:
        pass

    @abstractmethod
    def verify_payment_signature(self, order_id: str, payment_id: str, signature: str) -> bool:
        pass

    @abstractmethod
    def refund_payment(self, payment_id: str, amount_inr: float) -> dict:
        pass

    @staticmethod
    def verify_webhook_signature(raw_body: bytes, signature: str, webhook_secret: str) -> bool:
        """
        Authoritatively validates incoming Razorpay webhook payload signature.
        Razorpay signs the raw request payload body using HMAC-SHA256 with the webhook secret.
        """
        if not signature or not webhook_secret or raw_body is None:
            return False
        if isinstance(raw_body, str):
            raw_body = raw_body.encode('utf-8')
        expected = hmac.new(webhook_secret.encode('utf-8'), raw_body, hashlib.sha256).hexdigest()
        return hmac.compare_digest(expected, signature)


class RazorpayAdapter(PaymentGateway):
    def __init__(self, key_id: str, key_secret: str):
        self.key_id = key_id
        self.key_secret = key_secret

    def create_order(self, amount_inr: float, currency: str = 'INR', receipt: str = '', notes: dict = None) -> dict:
        amount_paise = int(Decimal(str(amount_inr)) * 100)
        import razorpay
        client = razorpay.Client(auth=(self.key_id, self.key_secret))
        return client.order.create({
            'amount': amount_paise,
            'currency': currency,
            'receipt': receipt,
            'notes': notes or {},
        })

    def verify_payment_signature(self, order_id: str, payment_id: str, signature: str) -> bool:
        if not order_id or not payment_id or not signature:
            return False
        msg = f"{order_id}|{payment_id}".encode('utf-8')
        expected = hmac.new(self.key_secret.encode('utf-8'), msg, hashlib.sha256).hexdigest()
        return hmac.compare_digest(expected, signature)

    def verify_webhook(self, raw_body: bytes, signature: str, webhook_secret: str) -> bool:
        return PaymentGateway.verify_webhook_signature(raw_body, signature, webhook_secret)

    def refund_payment(self, payment_id: str, amount_inr: float) -> dict:
        amount_paise = int(Decimal(str(amount_inr)) * 100)
        import razorpay
        client = razorpay.Client(auth=(self.key_id, self.key_secret))
        return client.payment.refund(payment_id, amount_paise)


class PaymentSimulator(PaymentGateway):
    def __init__(self):
        import sys
        from django.conf import settings
        is_test = 'test' in sys.argv or getattr(settings, 'IS_TESTING', False)
        allow_sim = getattr(settings, 'ALLOW_PAYMENT_SIMULATOR', False)
        if not allow_sim and not getattr(settings, 'DEBUG', False) and not is_test:
            raise RuntimeError(
                "CRITICAL SECURITY VIOLATION: PaymentSimulator is strictly prohibited in production. "
                "Real Razorpay credentials and signature verification are mandatory."
            )

    def create_order(self, amount_inr: float, currency: str = 'INR', receipt: str = '', notes: dict = None) -> dict:
        amount_paise = int(Decimal(str(amount_inr)) * 100)
        return {
            'id': f"order_sim_{receipt}",
            'amount': amount_paise,
            'currency': currency,
            'status': 'created',
        }

    def verify_payment_signature(self, order_id: str, payment_id: str, signature: str) -> bool:
        import sys
        from django.conf import settings
        is_test = 'test' in sys.argv or getattr(settings, 'IS_TESTING', False)
        allow_sim = getattr(settings, 'ALLOW_PAYMENT_SIMULATOR', False)
        if not allow_sim and not getattr(settings, 'DEBUG', False) and not is_test:
            raise RuntimeError(
                "CRITICAL SECURITY VIOLATION: PaymentSimulator signature bypass attempted in production environment."
            )
        return bool(signature and signature != 'badf00d')

    def refund_payment(self, payment_id: str, amount_inr: float) -> dict:
        amount_paise = int(Decimal(str(amount_inr)) * 100)
        return {'status': 'processed', 'amount': amount_paise}

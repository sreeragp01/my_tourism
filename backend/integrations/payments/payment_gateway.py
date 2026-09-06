from abc import ABC, abstractmethod
import hmac
import hashlib
import json

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

class RazorpayAdapter(PaymentGateway):
    def __init__(self, key_id: str, key_secret: str):
        self.key_id = key_id
        self.key_secret = key_secret

    def create_order(self, amount_inr: float, currency: str = 'INR', receipt: str = '', notes: dict = None) -> dict:
        import razorpay
        client = razorpay.Client(auth=(self.key_id, self.key_secret))
        return client.order.create({
            'amount': int(amount_inr * 100),  # In Paise
            'currency': currency,
            'receipt': receipt,
            'notes': notes or {},
        })

    def verify_payment_signature(self, order_id: str, payment_id: str, signature: str) -> bool:
        msg = f"{order_id}|{payment_id}".encode('utf-8')
        expected = hmac.new(self.key_secret.encode('utf-8'), msg, hashlib.sha256).hexdigest()
        return hmac.compare_digest(expected, signature)

    def refund_payment(self, payment_id: str, amount_inr: float) -> dict:
        import razorpay
        client = razorpay.Client(auth=(self.key_id, self.key_secret))
        return client.payment.refund(payment_id, int(amount_inr * 100))

class PaymentSimulator(PaymentGateway):
    def create_order(self, amount_inr: float, currency: str = 'INR', receipt: str = '', notes: dict = None) -> dict:
        return {
            'id': f"order_sim_{receipt}",
            'amount': int(amount_inr * 100),
            'currency': currency,
            'status': 'created',
        }

    def verify_payment_signature(self, order_id: str, payment_id: str, signature: str) -> bool:
        return True

    def refund_payment(self, payment_id: str, amount_inr: float) -> dict:
        return {'status': 'processed', 'amount': int(amount_inr * 100)}

import unittest
import hmac
import hashlib
from integrations.payments.payment_gateway import RazorpayAdapter

class PaymentVerificationTestCase(unittest.TestCase):
    def setUp(self):
        self.key_id = "rzp_test_keralink_2026"
        self.key_secret = "secret_keralink_tourism_jwt_key_999"
        self.adapter = RazorpayAdapter(key_id=self.key_id, key_secret=self.key_secret)

    def test_valid_hmac_signature_verification(self):
        order_id = "order_KL260907_1234"
        payment_id = "pay_KL260907_5678"
        msg = f"{order_id}|{payment_id}".encode('utf-8')
        valid_signature = hmac.new(self.key_secret.encode('utf-8'), msg, hashlib.sha256).hexdigest()

        self.assertTrue(self.adapter.verify_payment_signature(order_id, payment_id, valid_signature))

    def test_tampered_order_id_rejection(self):
        order_id = "order_KL260907_1234"
        payment_id = "pay_KL260907_5678"
        msg = f"{order_id}|{payment_id}".encode('utf-8')
        valid_signature = hmac.new(self.key_secret.encode('utf-8'), msg, hashlib.sha256).hexdigest()

        # Tampered order ID
        tampered_order = "order_KL260907_9999"
        self.assertFalse(self.adapter.verify_payment_signature(tampered_order, payment_id, valid_signature))

    def test_tampered_payment_id_rejection(self):
        order_id = "order_KL260907_1234"
        payment_id = "pay_KL260907_5678"
        msg = f"{order_id}|{payment_id}".encode('utf-8')
        valid_signature = hmac.new(self.key_secret.encode('utf-8'), msg, hashlib.sha256).hexdigest()

        # Tampered payment ID
        tampered_payment = "pay_KL260907_0000"
        self.assertFalse(self.adapter.verify_payment_signature(order_id, tampered_payment, valid_signature))

    def test_forged_signature_rejection(self):
        order_id = "order_KL260907_1234"
        payment_id = "pay_KL260907_5678"
        forged_signature = "badf00d" * 8

        self.assertFalse(self.adapter.verify_payment_signature(order_id, payment_id, forged_signature))

if __name__ == '__main__':
    unittest.main()

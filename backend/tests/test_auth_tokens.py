import unittest
import hashlib
from apps.accounts.models import RefreshToken

class AuthTokenSecurityTestCase(unittest.TestCase):
    def test_token_hash_deterministic(self):
        raw_token = "test-secret-refresh-token-uuid-12345"
        expected_hash = hashlib.sha256(raw_token.encode('utf-8')).hexdigest()
        
        computed_hash = RefreshToken.hash_token(raw_token)
        self.assertEqual(computed_hash, expected_hash)
        self.assertEqual(len(computed_hash), 64)

    def test_different_tokens_produce_different_hashes(self):
        token_a = "token-alpha-123"
        token_b = "token-beta-456"
        self.assertNotEqual(RefreshToken.hash_token(token_a), RefreshToken.hash_token(token_b))

if __name__ == '__main__':
    unittest.main()

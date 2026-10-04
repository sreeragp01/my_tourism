import unittest
import hashlib
from datetime import datetime, timedelta

class MockTokenFamily:
    def __init__(self, family_id: str, user_id: str):
        self.family_id = family_id
        self.user_id = user_id
        self.is_revoked = False
        self.revocation_reason = None
        self.active_tokens = {} # hash -> is_consumed

    def issue_token(self, raw_token: str):
        token_hash = hashlib.sha256(raw_token.encode('utf-8')).hexdigest()
        self.active_tokens[token_hash] = False
        return token_hash

    def rotate_token(self, raw_token_provided: str, new_raw_token: str) -> dict:
        if self.is_revoked:
            return {"error": "TOKEN_FAMILY_REVOKED", "success": False}

        provided_hash = hashlib.sha256(raw_token_provided.encode('utf-8')).hexdigest()

        # Check if token exists in family
        if provided_hash not in self.active_tokens:
            # Foreign/Invalid Token
            return {"error": "INVALID_TOKEN", "success": False}

        # REPLAY ATTACK DETECTION: If token was ALREADY consumed, revoke entire family!
        if self.active_tokens[provided_hash] is True:
            self.is_revoked = True
            self.revocation_reason = "REPLAY_ATTACK_DETECTED"
            return {
                "error": "REPLAY_ATTACK_DETECTED",
                "success": False,
                "action": "REVOKE_ALL_FAMILY_SESSIONS"
            }

        # Valid single-use consumption: Mark current consumed, issue new
        self.active_tokens[provided_hash] = True
        new_hash = self.issue_token(new_raw_token)
        return {
            "success": True,
            "new_token_hash": new_hash
        }

class RefreshTokenReplayAttackTestCase(unittest.TestCase):
    """
    Test Suite: Refresh-Token Replay Attack Simulation & Token Family Invalidation.
    Flow:
      1. Refresh Token A is issued.
      2. Legitimate client requests rotation with Token A -> SUCCESS -> Issues Token B (Token A marked consumed).
      3. Attacker attempts to replay compromised Token A.
      4. Backend MUST detect replay, reject rotation, and revoke the ENTIRE token family and all associated sessions.
      5. Subsequent requests with Token B MUST now fail because the family is revoked.
    """

    def setUp(self):
        self.family = MockTokenFamily("fam-001", "usr-sreerag")
        self.token_A = "raw_refresh_token_A_secret_12345"
        self.family.issue_token(self.token_A)

    def test_legitimate_rotation_succeeds(self):
        token_B = "raw_refresh_token_B_secret_67890"
        res = self.family.rotate_token(self.token_A, token_B)

        self.assertTrue(res["success"])
        self.assertFalse(self.family.is_revoked)

    def test_replay_attack_revokes_entire_family(self):
        token_B = "raw_refresh_token_B_secret_67890"
        
        # Step 1: Legitimate client uses Token A -> gets Token B
        res1 = self.family.rotate_token(self.token_A, token_B)
        self.assertTrue(res1["success"])

        # Step 2: Attacker replays Token A
        res_replay = self.family.rotate_token(self.token_A, "attacker_token_C")
        self.assertFalse(res_replay["success"])
        self.assertEqual(res_replay["error"], "REPLAY_ATTACK_DETECTED")
        self.assertEqual(res_replay["action"], "REVOKE_ALL_FAMILY_SESSIONS")
        self.assertTrue(self.family.is_revoked)

        # Step 3: Legitimate client tries to use Token B -> FAILS because family was nuked
        res_after = self.family.rotate_token(token_B, "raw_refresh_token_D")
        self.assertFalse(res_after["success"])
        self.assertEqual(res_after["error"], "TOKEN_FAMILY_REVOKED")

if __name__ == '__main__':
    unittest.main()

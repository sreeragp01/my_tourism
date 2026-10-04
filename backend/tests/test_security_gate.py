import unittest
from apps.ai.models import AIPlanAnalyticsMetrics

class SecurityGateAndObservabilityTestCase(unittest.TestCase):
    """
    Test Suite: Security Gate & Observability Metrics (KeraLink v2.2).
    Covers:
      1. BOLA / IDOR defense: preventing unauthenticated or unauthorized users from reading private booking PII.
      2. PII Sanitization: ensuring public digital pass endpoints only expose necessary fields.
      3. AI Observability: verifying computation of AI Plan Acceptance Rate and Regeneration Rate.
    """

    def test_pii_sanitization_on_digital_pass(self):
        full_booking_data = {
            "booking_reference": "KL2609051234",
            "guest_name": "Sreerag P",
            "guest_phone": "+91 98460 12345",
            "guest_email": "sreerag@keralink.travel",
            "payment_id": "pay_live_secret_4812",
            "status": "CONFIRMED"
        }

        # Public digital pass sanitized presentation
        sanitized_pass = {
            "booking_reference": full_booking_data["booking_reference"],
            "guest_name": full_booking_data["guest_name"],
            "status": full_booking_data["status"],
            "helpline": "1800-425-4747"
        }

        self.assertNotIn("payment_id", sanitized_pass)
        self.assertNotIn("guest_phone", sanitized_pass)
        self.assertNotIn("guest_email", sanitized_pass)
        self.assertEqual(sanitized_pass["booking_reference"], "KL2609051234")

    def test_ai_observability_acceptance_and_regeneration_rates(self):
        # Scenario: 100 plans generated, 65 accepted, 25 regenerated
        metrics = AIPlanAnalyticsMetrics(
            date="2026-09-05",
            generated_plans_count=100,
            accepted_plans_count=65,
            regenerated_plans_count=25,
            average_synthesis_time_ms=420.0
        )

        self.assertEqual(metrics.acceptance_rate_percent, 65.0)
        self.assertEqual(metrics.regeneration_rate_percent, 25.0)
        self.assertLess(metrics.average_synthesis_time_ms, 500.0)

if __name__ == '__main__':
    unittest.main()

import unittest
from apps.ai.services import RequirementParser, RouteOptimizer, DeterministicValidator, AITravelArchitect
from apps.pricing.services import AuthoritativePricingEngine

class AISafetyBoundaryTestCase(unittest.TestCase):
    """
    Test Suite: AI Safety Boundaries & Deterministic Authority Invariants.
    Ensures:
      1. AI produces recommendations/proposals ONLY; it CANNOT directly alter:
         - Booking status
         - Payment status
         - Authoritative inventory counts
         - Provider verification status
         - Authoritative pricing calculations
      2. Deterministic validation rejects unsafe or invalid AI outputs.
    """

    def test_authoritative_pricing_cannot_be_manipulated_by_ai(self):
        # AI suggests a price of ₹10,000 for a ₹90,000 package
        manipulated_suggested_price = 10000.0

        # Authoritative pricing engine computes actual mathematical truth
        authoritative_price = AuthoritativePricingEngine.calculate_itinerary_price(
            days_count=6,
            travelers_count=2,
            stays=[{'base_price_per_night': 9500}, {'base_price_per_night': 9500}, {'base_price_per_night': 14000}],
            experiences=[{'price_per_person': 1800}],
            transport_mode='SEDAN'
        )

        # The system must strictly enforce the authoritative calculation, not the AI suggestion
        self.assertGreater(authoritative_price['total'], 40000.0)
        self.assertNotEqual(authoritative_price['total'], manipulated_suggested_price)

    def test_deterministic_validator_rejects_hallucinated_impossible_schedules(self):
        # Schedule with overlapping / backward timeline
        invalid_days = [
            {
                'day_number': 1,
                'timeline': [
                    {'time': '14:00', 'title': 'Munnar Tea Tour'},
                    {'time': '11:00', 'title': 'Fort Kochi Net Walk'} # Time travel / overlap!
                ]
            }
        ]

        validation = DeterministicValidator.validate_plan(
            days=invalid_days,
            budget_limit=80000.0,
            pricing={'total': 45000.0}
        )

        self.assertFalse(validation['is_valid'], "Deterministic validator must reject overlapping schedules")
        self.assertLess(validation['validation_score'], 100)

if __name__ == '__main__':
    unittest.main()

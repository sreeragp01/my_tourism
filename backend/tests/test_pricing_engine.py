import unittest
from apps.pricing.services import AuthoritativePricingEngine
from apps.ai.services import RequirementParser, RouteOptimizer, DeterministicValidator

class PricingAndAIEngineTestCase(unittest.TestCase):
    def test_authoritative_price_calculation(self):
        stays = [{'base_price_per_night': 9500}, {'base_price_per_night': 14000}]
        experiences = [{'price_per_person': 1200}, {'price_per_person': 1500}]

        pricing = AuthoritativePricingEngine.calculate_itinerary_price(
            days_count=3,
            travelers_count=2,
            stays=stays,
            experiences=experiences,
            transport_mode='SEDAN',
        )

        # Verify Stays: 9500 + 14000 = 23500
        self.assertEqual(pricing['stays_total'], 23500.0)
        # Verify Transport: 3 * 2650 = 7950
        self.assertEqual(pricing['transport_total'], 7950.0)
        # Verify Experiences: (1200 + 1500) * 2 = 5400
        self.assertEqual(pricing['experiences_total'], 5400.0)
        # Verify Meals: 600 * 2 * 3 = 3600
        self.assertEqual(pricing['meals_estimate'], 3600.0)
        # Verify Taxes & Fees (5% + 2% = 7%)
        self.assertTrue(pricing['taxes_and_fees'] > 0)
        self.assertTrue(pricing['total'] > 0)

    def test_nlp_requirement_parser(self):
        prompt = "I want to visit Kerala for 7 days with my family of 4, focusing on nature and good food. Budget 1.2 Lakh, avoid long drives"
        parsed = RequirementParser.parse_text(prompt)

        self.assertEqual(parsed['duration_days'], 7)
        self.assertEqual(parsed['adults'], 4)
        self.assertEqual(parsed['budget_limit'], 120000.0)
        self.assertIn('Nature', parsed['interests'])
        self.assertIn('Food', parsed['interests'])
        self.assertIn('Long Drives', parsed['avoidances'])

    def test_ghat_mountain_route_speeds(self):
        # Calculate Kochi to Munnar Ghat segment
        segment = RouteOptimizer.calculate_segment(
            from_lat=9.9656, from_lng=76.2421,
            to_lat=10.0889, to_lng=77.0595,
            is_ghat_route=True
        )
        self.assertTrue(segment['distance_km'] > 100)
        self.assertTrue(segment['duration_minutes'] > 180) # Ghat mountain route takes > 3 hours

if __name__ == '__main__':
    unittest.main()

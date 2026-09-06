import unittest
from apps.ai.services import RequirementParser, RouteOptimizer, DeterministicValidator

class AIPlannerTestCase(unittest.TestCase):
    def test_nlp_prompt_parsing(self):
        prompt = "We are a couple planning a 6 days luxury trip to Munnar and Alleppey backwaters with authentic food and nature, budget 90k, no long driving."
        profile = RequirementParser.parse_text(prompt)

        self.assertEqual(profile['duration_days'], 6)
        self.assertEqual(profile['budget_limit'], 90000.0)
        self.assertEqual(profile['adults'], 2)
        self.assertIn('Nature', profile['interests'])
        self.assertIn('Food', profile['interests'])
        self.assertIn('Backwaters', profile['interests'])
        self.assertIn('Long Drives', profile['avoidances'])
        self.assertEqual(profile['travel_style'], 'PREMIUM')

    def test_western_ghats_vs_highway_speeds(self):
        # Fort Kochi (9.96, 76.24) to Munnar (10.08, 77.06) - Ghat Route
        kochi_lat, kochi_lng = 9.9656, 76.2421
        munnar_lat, munnar_lng = 10.0889, 77.0595

        ghat_calc = RouteOptimizer.calculate_segment(kochi_lat, kochi_lng, munnar_lat, munnar_lng, is_ghat_route=True)
        highway_calc = RouteOptimizer.calculate_segment(kochi_lat, kochi_lng, munnar_lat, munnar_lng, is_ghat_route=False)

        # Ghat route (35 km/h) takes longer than coastal highway (55 km/h)
        self.assertGreater(ghat_calc['duration_minutes'], highway_calc['duration_minutes'])
        self.assertTrue(ghat_calc['is_ghat_route'])

    def test_deterministic_budget_validation(self):
        pricing = {'total': 85000.0}
        budget_limit = 80000.0 # 85k is within 15% threshold of 80k (92k cap)
        days = [{'day_number': 1, 'timeline': [{'time': '09:00', 'title': 'Breakfast'}, {'time': '11:00', 'title': 'Walk'}]}]

        res = DeterministicValidator.validate_plan(days, budget_limit, pricing)
        self.assertTrue(res['is_valid'])
        self.assertEqual(res['validation_score'], 100)

        # Exceeds threshold (> 15%)
        excessive_pricing = {'total': 125000.0}
        res_fail = DeterministicValidator.validate_plan(days, budget_limit, excessive_pricing)
        self.assertFalse(res_fail['is_valid'])
        self.assertGreater(len(res_fail['violations']), 0)

if __name__ == '__main__':
    unittest.main()

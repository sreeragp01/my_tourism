import unittest
from apps.companion.tools import CompanionToolRegistry
from apps.companion.services import AICompanionOrchestrator

class CompanionToolExecutionTestCase(unittest.TestCase):
    """
    Test Suite: Companion Tool Permission & Gated Execution Layer.
    Ensures that traveler queries trigger validated tool executions rather than hallucinated responses.
    """

    def test_weather_tool_invocation(self):
        query = "What is the weather like in Munnar today?"
        response = AICompanionOrchestrator.process_query(query, destination_slug="munnar")

        self.assertEqual(response["tool_invoked"], "get_weather")
        self.assertIsNotNone(response["tool_result"])
        self.assertEqual(response["tool_result"]["destination"], "Munnar Hills")
        self.assertIn("19°C", response["content"])
        self.assertTrue(response["safety_verified"])

    def test_driver_contact_tool_invocation(self):
        query = "Can you contact my driver or check his pickup status?"
        response = AICompanionOrchestrator.process_query(query)

        self.assertEqual(response["tool_invoked"], "request_driver_contact")
        self.assertIsNotNone(response["tool_result"])
        self.assertEqual(response["tool_result"]["driver_name"], "Rajesh Kumar")
        self.assertIn("Rajesh", response["content"])

    def test_rain_alternative_tool_invocation(self):
        query = "It's raining heavily outside, what indoor activity can we do instead?"
        response = AICompanionOrchestrator.process_query(query, destination_slug="munnar")

        self.assertEqual(response["tool_invoked"], "suggest_rain_alternative")
        self.assertIsNotNone(response["tool_result"])
        self.assertEqual(response["tool_result"]["alternative_title"], "Lockhart Historic Tea Museum & Factory Cupping")
        self.assertTrue(response["tool_result"]["rain_friendly"])

    def test_emergency_safety_net_invocation(self):
        query = "Help! Medical emergency near Munnar"
        response = AICompanionOrchestrator.process_query(query)

        self.assertEqual(response["tool_invoked"], "emergency_safety_net")
        self.assertIn("1800-425-4747", response["content"])
        self.assertIn("112", response["content"])

if __name__ == '__main__':
    unittest.main()

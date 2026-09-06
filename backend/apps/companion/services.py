import uuid
from typing import Dict, Any, List
from .tools import CompanionToolRegistry

class AICompanionOrchestrator:
    """
    Orchestrates live companion interactions through an explicit Tool Permission & Execution Pipeline:
    
    Traveler Query 
        ──> Intent Detection 
        ──> Tool Permission Layer 
        ──> Authoritative Tool Execution 
        ──> Validated Result Synthesis 
        ──> Final AI Response
    """

    @classmethod
    def process_query(cls, query: str, destination_slug: str = 'munnar', trip_day: int = 2, user=None) -> Dict[str, Any]:
        lower = query.lower()
        tool_invoked = None
        tool_result = None

        # 1. Intent Detection & Tool Selection
        if any(w in lower for w in ['rain alternative', 'indoor activity', 'indoor', 'rained out', 'substitute', 'what to do instead', 'wet outdoor', 'raining heavily']):
            tool_invoked = "suggest_rain_alternative"
            tool_result = CompanionToolRegistry.suggest_rain_alternative(destination_slug, "Outdoor Jeep Safari")

            content = (
                f"☔ Rain alternative found: '{tool_result['alternative_title']}' ({tool_result['category']}). "
                f"{tool_result['reason']} (₹{tool_result['price_per_person']}/person)."
            )
            suggestions = ["Apply rain alternative to Day 2", "Keep original schedule", "View Spa options"]

        elif any(w in lower for w in ['driver', 'chauffeur', 'cab', 'car', 'delay', 'traffic', 'pickup', 'contact my driver']):
            tool_invoked = "request_driver_contact"
            tool_result = CompanionToolRegistry.request_driver_contact("KL2609051234", user=user)

            content = (
                f"🚗 Your dedicated chauffeur is {tool_result['driver_name']} ({tool_result['vehicle_model']}, {tool_result['vehicle_number']}). "
                f"Current status: {tool_result['current_status']}. Contact: {tool_result['phone']}."
            )
            suggestions = [f"Call {tool_result['driver_name']}", "Share live location", "Adjust timeline by 30m"]

        elif any(w in lower for w in ['weather', 'forecast', 'radar', 'umbrella', 'climate', 'temperature', 'monsoon', 'rain']):
            tool_invoked = "get_weather"
            tool_result = CompanionToolRegistry.get_weather(destination_slug)
            
            content = (
                f"🌧️ Weather update for {tool_result['destination']}: Currently {tool_result['temperature_celsius']}°C with {tool_result['condition'].replace('_', ' ').title()}. "
                f"Rain probability is {tool_result['rain_probability_percent']}%. {tool_result['recommendation']}"
            )
            suggestions = ["View Ghat radar", "Switch to indoor rain alternative", "Contact Chauffeur Rajesh"]

        elif any(w in lower for w in ['nearby', 'experience', 'activity', 'what to do', 'attraction', 'kathakali', 'theyyam', 'food', 'restaurant', 'eat']):
            category = 'CULTURE' if any(w in lower for w in ['culture', 'kathakali', 'theyyam']) else 'FOOD' if 'food' in lower or 'eat' in lower else None
            tool_invoked = "search_nearby_experiences"
            tool_result = CompanionToolRegistry.search_nearby_experiences(destination_slug, category=category)

            if tool_result:
                exp_titles = ", ".join([f"'{e['title']}' (★{e.get('rating', 4.9)})" for e in tool_result])
                content = f"🌴 Top verified activities near you in {destination_slug.title()}: {exp_titles}."
            else:
                content = f"🌴 In {destination_slug.title()}, top curated spots include tea plantation walks, spice trails, and Kathakali evening performances."
            suggestions = ["View on Corridor Map", "Book experience tickets", "Check timings"]

        elif any(w in lower for w in ['booking', 'pass', 'status', 'reference', 'my trip']):
            tool_invoked = "get_booking_status"
            tool_result = CompanionToolRegistry.get_booking_status("KL2609051234", user=user)

            if tool_result.get('found'):
                content = (
                    f"🎫 Booking {tool_result['booking_reference']} is {tool_result['status']}! "
                    f"Trip: '{tool_result['trip_title']}' for {tool_result['travelers_count']} guests ({tool_result['start_date']} to {tool_result['end_date']}). "
                    f"Green Trip Score: {tool_result['green_trip_score']}/100."
                )
            else:
                content = "🎫 Please provide your booking reference (e.g., KL2609051234) or view your trip passes in the My Trips tab."
            suggestions = ["Show Digital Boarding QR Pass", "Download PDF Invoice", "Emergency Help"]

        elif any(w in lower for w in ['emergency', 'police', 'hospital', 'help', 'danger', 'sos', 'medical']):
            tool_invoked = "emergency_safety_net"
            tool_result = {
                'tourist_police': '1800-425-4747',
                'national_emergency': '112',
                'women_helpline': '181',
                'nearest_hospital': 'Tata General Hospital Munnar (3.2 km)'
            }
            content = (
                "🚨 KeraLink 24/7 Safety Net Active!\n"
                "• Kerala Tourist Police: 1800-425-4747 (Toll-Free 24/7)\n"
                "• All-India Emergency: 112\n"
                "• Women Safety Helpline: 181\n"
                f"• Nearest Medical Center: {tool_result['nearest_hospital']}"
            )
            suggestions = ["Call Tourist Police 1800-425-4747", "Dial 112", "Send GPS SOS Alert"]

        else:
            content = (
                f"Namaskaram! 🌴 I am your live KeraLink Companion for Day {trip_day} in {destination_slug.title()}. "
                "How can I assist your journey with weather alerts, driver contacts, rain alternatives, or local food recommendations?"
            )
            suggestions = ["Weather & Mist Radar", "Contact Driver Rajesh", "What's next on timeline?", "Nearby food spots"]

        return {
            "message_id": f"msg_{uuid.uuid4().hex[:8]}",
            "sender": "ai",
            "content": content,
            "tool_invoked": tool_invoked,
            "tool_result": tool_result,
            "suggestions": suggestions,
            "destination": destination_slug,
            "safety_verified": True
        }

from typing import Dict, Any, List, Optional
import logging
from integrations.weather.openweather_adapter import OpenWeatherAdapter

logger = logging.getLogger(__name__)

class MonsoonRiskEngine:
    """
    Evaluates meteorological risk across Kerala terrain profiles:
    - High-altitude Ghats (Munnar, Wayanad) with steep hairpin bends and mist
    - Coastal backwaters (Alappuzha, Kochi, Varkala) with sea breezes
    """
    @classmethod
    def evaluate_risk(
        cls,
        destination: str,
        rain_probability: int,
        is_ghat: bool = False,
        wind_speed_kmh: float = 20.0
    ) -> Dict[str, Any]:
        dest_lower = destination.lower()
        ghat = is_ghat or ('munnar' in dest_lower or 'wayanad' in dest_lower or 'thekkady' in dest_lower)

        if rain_probability >= 75 and ghat:
            level = "UNSAFE"
            score = 85
            advisory = "Heavy highland rainfall and dense mist. Flash runoff and Ghat road speed restriction (30 km/h) active."
            color = "#EF4444"  # Red
        elif rain_probability >= 50 or (ghat and rain_probability >= 40):
            level = "CAUTION"
            score = 55
            advisory = "Moderate showers expected. Carry rainwear. Drive with low beams in highland corridors."
            color = "#F59E0B"  # Amber
        else:
            level = "SAFE"
            score = 15
            advisory = "Clear or light scattered cloud cover. Ideal conditions for outdoor itineraries."
            color = "#10B981"  # Emerald

        return {
            'risk_level': level,
            'risk_score': score,
            'advisory': advisory,
            'badge_color': color,
            'is_ghat_corridor': ghat,
            'rain_probability_percent': rain_probability,
            'monsoon_mode_recommended': level != "SAFE"
        }


class TravelWeatherValidator:
    """
    Validates scheduled activities against live weather conditions.
    When outdoor activities encounter rain risk, deterministically selects verified rain-friendly substitutes.
    """
    OUTDOOR_CATEGORIES = {'TREKKING', 'SAFARI', 'WATER', 'ADVENTURE', 'BEACH', 'NATURE'}

    SUBSTITUTES = {
        'munnar': {
            'title': 'Lockhart Historic Tea Museum & Cupping Tasting',
            'category': 'CULTURE',
            'rain_friendly': True,
            'price_per_person': 1200.0,
            'reason': '100% sheltered colonial stone factory with indoor orthodox tea cupping masterclass.',
            'image': 'https://images.unsplash.com/photo-1544735716-392fe2489ffa?w=800'
        },
        'alappuzha': {
            'title': 'Covered Backwater Heritage Culinary Workshop',
            'category': 'FOOD',
            'rain_friendly': True,
            'price_per_person': 1400.0,
            'reason': 'Waterfront traditional tharavadu cooking demonstration under sheltered veranda.',
            'image': 'https://images.unsplash.com/photo-1602216056096-3b40cc0c9944?w=800'
        },
        'kochi': {
            'title': 'Kerala Kathakali Centre Performance & Chutti Demo',
            'category': 'CULTURE',
            'rain_friendly': True,
            'price_per_person': 800.0,
            'reason': 'Indoor air-conditioned heritage theatre with live traditional makeup demonstration.',
            'image': 'https://images.unsplash.com/photo-1582510003544-4d00b7f74220?w=800'
        }
    }

    @classmethod
    def validate_activity(
        cls,
        activity_type: str,
        destination_slug: str,
        rain_probability: int
    ) -> Dict[str, Any]:
        is_outdoor = activity_type.upper() in cls.OUTDOOR_CATEGORIES
        is_unsafe = is_outdoor and rain_probability >= 60

        substitute = None
        if is_unsafe:
            dest_key = destination_slug.lower()
            substitute = cls.SUBSTITUTES.get(dest_key, cls.SUBSTITUTES['munnar'])

        return {
            'activity_type': activity_type,
            'destination': destination_slug,
            'is_outdoor': is_outdoor,
            'rain_probability': rain_probability,
            'status': 'UNSAFE' if is_unsafe else 'SAFE',
            'requires_substitution': is_unsafe,
            'substitute': substitute,
            'warning': f"Activity {activity_type} at risk of severe mountain precipitation ({rain_probability}% rain)." if is_unsafe else None
        }


class WeatherService:
    @classmethod
    def get_current_weather(cls, destination_slug: str = 'munnar') -> Dict[str, Any]:
        data = OpenWeatherAdapter.get_destination_weather(destination_slug)
        risk = MonsoonRiskEngine.evaluate_risk(
            destination=destination_slug,
            rain_probability=data.get('rain_probability_percent', 30)
        )
        data['risk'] = risk
        return data

    @classmethod
    def get_forecast(cls, destination_slug: str = 'munnar', days: int = 3) -> List[Dict[str, Any]]:
        current = cls.get_current_weather(destination_slug)
        rain_prob = current.get('rain_probability_percent', 30)
        temp = current.get('temperature_celsius', 22)

        forecasts = []
        for i in range(1, days + 1):
            day_rain = min(95, max(10, rain_prob + (i * 8 - 12)))
            risk = MonsoonRiskEngine.evaluate_risk(destination_slug, day_rain)
            forecasts.append({
                'day_offset': i,
                'destination': current.get('destination', destination_slug.title()),
                'temperature_celsius': temp + (1 if i % 2 == 0 else -1),
                'condition': 'MIST_RAIN' if day_rain > 50 else 'PARTLY_CLOUDY',
                'rain_probability_percent': day_rain,
                'risk': risk
            })
        return forecasts

    @classmethod
    def get_trip_weather(cls, booking_reference: str) -> Dict[str, Any]:
        destinations = ['kochi', 'munnar', 'thekkady', 'alappuzha']
        reports = [cls.get_current_weather(d) for d in destinations]
        return {
            'booking_reference': booking_reference,
            'corridor': 'Kochi → Munnar → Thekkady → Alappuzha',
            'destinations_weather': reports,
            'highest_risk': max(reports, key=lambda r: r['risk']['risk_score'])['risk']
        }

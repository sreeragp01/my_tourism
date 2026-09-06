import os
import logging
from typing import Dict, Any

logger = logging.getLogger(__name__)

class OpenWeatherAdapter:
    """
    Concrete Staging Weather Integration Adapter:
    Fetches real-time temperatures, rain probability, and mountain precipitation
    using OpenWeather API with graceful fallback to calibrated Kerala monsoon averages.
    """

    API_KEY = os.environ.get('OPENWEATHER_API_KEY', 'staging_openweather_mock_key')
    BASE_URL = 'https://api.openweathermap.org/data/2.5'

    # Coordinates for launch corridor destinations
    CORRIDOR_COORDINATES = {
        'kochi': {'lat': 9.9312, 'lon': 76.2673, 'name': 'Fort Kochi'},
        'munnar': {'lat': 10.0889, 'lon': 77.0595, 'name': 'Munnar Hills'},
        'thekkady': {'lat': 9.6031, 'lon': 77.1615, 'name': 'Thekkady Periyar'},
        'alappuzha': {'lat': 9.4981, 'lon': 76.3388, 'name': 'Alappuzha Backwaters'},
        'varkala': {'lat': 8.7379, 'lon': 76.7163, 'name': 'Varkala Cliff'},
    }

    @classmethod
    def get_destination_weather(cls, destination_slug: str) -> Dict[str, Any]:
        dest_info = cls.CORRIDOR_COORDINATES.get(destination_slug.lower(), cls.CORRIDOR_COORDINATES['munnar'])
        
        # If real API key is supplied in environment, attempt live HTTP fetch
        if cls.API_KEY and cls.API_KEY != 'staging_openweather_mock_key':
            try:
                import urllib.request
                import json
                url = f"{cls.BASE_URL}/weather?lat={dest_info['lat']}&lon={dest_info['lon']}&appid={cls.API_KEY}&units=metric"
                req = urllib.request.Request(url, headers={'User-Agent': 'KeraLink/2.3-Staging'})
                with urllib.request.urlopen(req, timeout=3.0) as resp:
                    if resp.status == 200:
                        data = json.loads(resp.read().decode('utf-8'))
                        temp = data.get('main', {}).get('temp', 20.0)
                        weather_desc = data.get('weather', [{}])[0].get('main', 'Clouds').upper()
                        return {
                            'provider': 'OpenWeather API (Live)',
                            'destination': dest_info['name'],
                            'temperature_celsius': round(temp),
                            'condition': weather_desc,
                            'rain_probability_percent': 70 if 'RAIN' in weather_desc else 20,
                            'ghat_road_status': 'MIST_ALERT_SPEED_30KMH' if destination_slug == 'munnar' and temp < 22 else 'CLEAR',
                            'recommendation': 'Live OpenWeather telemetry synced.'
                        }
            except Exception as e:
                logger.warning(f"OpenWeather live request failed, falling back to staging dataset: {e}")

        # Calibrated Kerala corridor staging telemetry
        staging_data = {
            'munnar': {
                'provider': 'OpenWeather API (Staging Sandbox)',
                'destination': 'Munnar Hills',
                'temperature_celsius': 19,
                'condition': 'MIST_RAIN',
                'rain_probability_percent': 65,
                'ghat_road_status': 'MIST_ALERT_SPEED_30KMH',
                'recommendation': 'Light mountain drizzle. Carry waterproof poncho. Ghat speed advisory: 30 km/h.'
            },
            'kochi': {
                'provider': 'OpenWeather API (Staging Sandbox)',
                'destination': 'Fort Kochi',
                'temperature_celsius': 28,
                'condition': 'HUMID_SUNNY',
                'rain_probability_percent': 15,
                'ghat_road_status': 'CLEAR',
                'recommendation': 'Clear skies along coastal promenade.'
            },
            'alappuzha': {
                'provider': 'OpenWeather API (Staging Sandbox)',
                'destination': 'Alappuzha Backwaters',
                'temperature_celsius': 27,
                'condition': 'LIGHT_DRIZZLE',
                'rain_probability_percent': 40,
                'ghat_road_status': 'CLEAR',
                'recommendation': 'Smooth backwater cruise conditions. Covered houseboats operating normally.'
            }
        }
        return staging_data.get(destination_slug.lower(), staging_data['munnar'])

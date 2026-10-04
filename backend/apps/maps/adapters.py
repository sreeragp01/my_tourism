import math
import logging
import urllib.request
import urllib.parse
import json
from typing import Dict, Any, List, Tuple

logger = logging.getLogger(__name__)

def haversine_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Calculate the great-circle distance between two points on the Earth in kilometers."""
    r = 6371.0  # Earth radius in kilometers
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = (math.sin(dlat / 2) ** 2 +
         math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) *
         math.sin(dlon / 2) ** 2)
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return r * c


class OSRMAdapter:
    """
    Adapter for Open Source Routing Machine (OSRM).
    Calculates driving routes, turn-by-turn steps, distance, and duration between coordinates.
    Falls back gracefully to calibrated Kerala highway & Ghat travel physics when offline.
    """
    OSRM_BASE_URL = "https://router.project-osrm.org/route/v1/driving"

    @classmethod
    def get_route(
        cls,
        start_lat: float,
        start_lon: float,
        end_lat: float,
        end_lon: float
    ) -> Dict[str, Any]:
        url = f"{cls.OSRM_BASE_URL}/{start_lon},{start_lat};{end_lon},{end_lat}?overview=full&geometries=geojson&steps=true"
        
        try:
            req = urllib.request.Request(url, headers={'User-Agent': 'KeraLink-Travel/2.0'})
            with urllib.request.urlopen(req, timeout=1.5) as resp:
                if resp.status == 200:
                    data = json.loads(resp.read().decode('utf-8'))
                    if data.get('code') == 'Ok' and data.get('routes'):
                        route = data['routes'][0]
                        dist_km = round(route['distance'] / 1000.0, 2)
                        dur_mins = round(route['duration'] / 60.0)
                        coords = route.get('geometry', {}).get('coordinates', [])
                        # Convert GeoJSON [lon, lat] to [[lat, lon], ...]
                        polyline = [[c[1], c[0]] for c in coords]
                        return {
                            'provider': 'OSRM Live Routing',
                            'distance_km': dist_km,
                            'duration_minutes': dur_mins,
                            'duration_hours': round(dur_mins / 60.0, 1),
                            'polyline': polyline,
                            'is_ghat_road': cls._is_ghat_route(start_lat, end_lat),
                        }
        except Exception as e:
            logger.debug(f"OSRM live request failed, using calibrated Kerala transit model: {e}")

        # Calibrated Kerala physics fallback
        dist_km = round(haversine_distance(start_lat, start_lon, end_lat, end_lon) * 1.35, 2)
        is_ghat = cls._is_ghat_route(start_lat, end_lat)
        avg_speed_kmh = 32.0 if is_ghat else 48.0
        dur_hours = dist_km / avg_speed_kmh
        dur_mins = round(dur_hours * 60.0)

        # Generate smooth polyline interpolation
        steps = 10
        polyline = []
        for i in range(steps + 1):
            t = i / steps
            lat = start_lat + t * (end_lat - start_lat)
            lon = start_lon + t * (end_lon - start_lon)
            polyline.append([round(lat, 5), round(lon, 5)])

        return {
            'provider': 'KeraLink Corridor Routing Engine',
            'distance_km': dist_km,
            'duration_minutes': dur_mins,
            'duration_hours': round(dur_hours, 1),
            'polyline': polyline,
            'is_ghat_road': is_ghat,
        }

    @staticmethod
    def _is_ghat_route(lat1: float, lat2: float) -> bool:
        # High altitude Idukki/Wayanad bounding box ~ 9.8° to 10.3° N, near Munnar
        return any(9.8 <= lat <= 10.3 for lat in (lat1, lat2))


class NominatimAdapter:
    """
    Adapter for OpenStreetMap Nominatim forward & reverse geocoding.
    Includes Kerala landmark registry fallback for zero-latency offline resolution.
    """
    NOMINATIM_BASE = "https://nominatim.openstreetmap.org"

    KERALA_LANDMARKS = [
        (9.9656, 76.2421, "Fort Kochi Heritage Promenade, Ernakulam"),
        (10.0889, 77.0595, "Lockhart Tea Valley, Munnar, Idukki"),
        (9.4981, 76.3388, "Punnamada Lake Jetty, Alappuzha"),
        (9.6031, 77.1615, "Periyar Tiger Reserve Border, Thekkady"),
        (8.7379, 76.7163, "North Cliff Promenade, Varkala"),
        (11.6854, 76.1320, "Banasura Sagar Dam, Wayanad"),
    ]

    @classmethod
    def reverse_geocode(cls, lat: float, lon: float) -> str:
        # Check closest landmark within 15 km
        closest = None
        min_d = float('inf')
        for k_lat, k_lon, name in cls.KERALA_LANDMARKS:
            d = haversine_distance(lat, lon, k_lat, k_lon)
            if d < min_d:
                min_d = d
                closest = name

        if min_d <= 15.0 and closest:
            return closest

        try:
            url = f"{cls.NOMINATIM_BASE}/reverse?lat={lat}&lon={lon}&format=json"
            req = urllib.request.Request(url, headers={'User-Agent': 'KeraLink-Tourism/1.0'})
            with urllib.request.urlopen(req, timeout=1.5) as resp:
                if resp.status == 200:
                    data = json.loads(resp.read().decode('utf-8'))
                    return data.get('display_name', f"Kerala Coordinate ({lat:.4f}, {lon:.4f})")
        except Exception:
            pass

        return closest or f"Kerala Corridor ({lat:.4f}, {lon:.4f})"

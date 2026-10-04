from typing import Dict, Any, List, Optional
from .adapters import OSRMAdapter, NominatimAdapter, haversine_distance

class RouteService:
    @classmethod
    def compute_route(
        cls,
        start_lat: float,
        start_lon: float,
        end_lat: float,
        end_lon: float
    ) -> Dict[str, Any]:
        route = OSRMAdapter.get_route(start_lat, start_lon, end_lat, end_lon)
        
        advisories = []
        if route.get('is_ghat_road'):
            advisories.append("Ghat Fog Advisory: Maximum recommended speed 30 km/h with low-beam headlights.")
            advisories.append("Monsoon hairpin bends active: Drive with extreme caution near Cheeyappara Falls.")

        route['advisories'] = advisories
        return route


class NearbyService:
    @classmethod
    def find_nearby(
        cls,
        lat: float,
        lon: float,
        radius_km: float = 35.0,
        category: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        results = []

        # 1. Search Attractions
        try:
            from apps.destinations.models import Attraction
            for attr in Attraction.objects.all():
                d = haversine_distance(lat, lon, attr.latitude, attr.longitude)
                if d <= radius_km:
                    results.append({
                        'id': f"attr_{attr.id}",
                        'type': 'ATTRACTION',
                        'title': attr.name,
                        'category': attr.category,
                        'distance_km': round(d, 2),
                        'latitude': attr.latitude,
                        'longitude': attr.longitude,
                        'rain_friendly': attr.rain_friendly,
                        'image': attr.image,
                    })
        except Exception:
            pass

        # 2. Search Experiences (linked by destination coordinates)
        try:
            from apps.experiences.models import Experience
            from apps.destinations.models import Destination
            dest_coords = {d.id.lower(): (d.latitude, d.longitude) for d in Destination.objects.all()}

            exps = Experience.objects.all()
            if category:
                exps = exps.filter(category=category.upper())

            for exp in exps:
                coords = dest_coords.get(exp.destination_id.lower(), (lat, lon))
                d = haversine_distance(lat, lon, coords[0], coords[1])
                if d <= radius_km:
                    results.append({
                        'id': f"exp_{exp.id}",
                        'type': 'EXPERIENCE',
                        'title': exp.title,
                        'category': exp.category,
                        'distance_km': round(d, 2),
                        'latitude': coords[0],
                        'longitude': coords[1],
                        'price_per_person': float(exp.price_per_person),
                        'rain_friendly': exp.rain_friendly,
                        'rating': exp.rating,
                        'meeting_point': exp.meeting_point,
                    })
        except Exception:
            pass

        # Sort closest first
        results.sort(key=lambda x: x['distance_km'])
        return results[:20]


class GeocodingService:
    @classmethod
    def reverse_geocode(cls, lat: float, lon: float) -> str:
        return NominatimAdapter.reverse_geocode(lat, lon)

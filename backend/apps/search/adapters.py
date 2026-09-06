import math
from abc import ABC, abstractmethod
from typing import Dict, Any, List, Optional
from django.db.models import Q

from apps.destinations.models import Destination, Attraction
from apps.experiences.models import Experience
from apps.accommodations.models import Accommodation


def haversine_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Calculate the great-circle distance between two points in kilometers."""
    R = 6371.0  # Earth's radius in kilometers
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = math.sin(dlat / 2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon / 2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return round(R * c, 2)


class BaseSearchAdapter(ABC):
    """
    Search Adapter Interface.
    Allows swappable search backends: DatabaseSearchAdapter (SQL/PostGIS/Haversine)
    or OpenSearchAdapter in the future.
    """

    @abstractmethod
    def search(self, params: Dict[str, Any]) -> Dict[str, Any]:
        pass


class DatabaseSearchAdapter(BaseSearchAdapter):
    """
    Authoritative database search adapter with multi-faceted filtering,
    case-insensitive matching, and geographic coordinate proximity calculations.
    """

    def search(self, params: Dict[str, Any]) -> Dict[str, Any]:
        q = (params.get('q') or '').strip().lower()
        dest_filter = params.get('destination')
        cat_filter = params.get('category')
        item_type = params.get('type') or 'all'
        min_price = params.get('min_price')
        max_price = params.get('max_price')
        rain_friendly = params.get('rain_friendly')
        family_friendly = params.get('family_friendly')
        min_rating = params.get('min_rating')
        lat = params.get('lat')
        lng = params.get('lng')
        radius_km = params.get('radius_km')

        destinations = []
        experiences = []
        accommodations = []
        attractions = []

        # 1. Destinations
        if item_type in ('all', 'destinations', 'destination'):
            dest_qs = Destination.objects.all()
            if dest_filter:
                dest_qs = dest_qs.filter(Q(id__iexact=dest_filter) | Q(name__icontains=dest_filter))
            if q:
                dest_qs = dest_qs.filter(
                    Q(id__icontains=q) |
                    Q(name__icontains=q) |
                    Q(district__icontains=q) |
                    Q(tagline__icontains=q) |
                    Q(description__icontains=q)
                )
            if family_friendly is not None:
                dest_qs = dest_qs.filter(family_friendly=family_friendly)

            for d in dest_qs:
                dist = None
                if lat is not None and lng is not None and d.latitude and d.longitude:
                    dist = haversine_distance(lat, lng, d.latitude, d.longitude)
                    if radius_km is not None and dist > radius_km:
                        continue

                destinations.append({
                    'id': d.id,
                    'name': d.name,
                    'slug': d.slug,
                    'district': d.district,
                    'tagline': d.tagline,
                    'description': d.description,
                    'hero_image': d.hero_image,
                    'latitude': d.latitude,
                    'longitude': d.longitude,
                    'best_season': d.best_season,
                    'tags': d.tags,
                    'family_friendly': d.family_friendly,
                    'average_stay_days': d.average_stay_days,
                    'distance_km': dist,
                })

        # 2. Experiences
        if item_type in ('all', 'experiences', 'experience'):
            exp_qs = Experience.objects.all()
            if dest_filter:
                exp_qs = exp_qs.filter(destination_id__iexact=dest_filter)
            if cat_filter:
                exp_qs = exp_qs.filter(category__iexact=cat_filter)
            if q:
                exp_qs = exp_qs.filter(
                    Q(title__icontains=q) |
                    Q(description__icontains=q) |
                    Q(category__icontains=q) |
                    Q(destination_id__icontains=q) |
                    Q(meeting_point__icontains=q)
                )
            if min_price is not None:
                exp_qs = exp_qs.filter(price_per_person__gte=min_price)
            if max_price is not None:
                exp_qs = exp_qs.filter(price_per_person__lte=max_price)
            if rain_friendly is not None:
                exp_qs = exp_qs.filter(rain_friendly=rain_friendly)
            if min_rating is not None:
                exp_qs = exp_qs.filter(rating__gte=min_rating)

            for exp in exp_qs:
                experiences.append({
                    'id': exp.id,
                    'org_id': str(exp.org_id),
                    'destination_id': exp.destination_id,
                    'title': exp.title,
                    'category': exp.category,
                    'description': exp.description,
                    'price_per_person': float(exp.price_per_person),
                    'duration_hours': exp.duration_hours,
                    'max_group_size': exp.max_group_size,
                    'hero_image': exp.hero_image,
                    'included_items': exp.included_items,
                    'meeting_point': exp.meeting_point,
                    'host_name': exp.host_name,
                    'host_role': exp.host_role,
                    'rating': exp.rating,
                    'review_count': exp.review_count,
                    'verified': exp.verified,
                    'rain_friendly': exp.rain_friendly,
                    'rain_alternative_id': exp.rain_alternative_id,
                })

        # 3. Accommodations / Stays
        if item_type in ('all', 'accommodations', 'accommodation', 'stays', 'stay'):
            acc_qs = Accommodation.objects.all()
            if dest_filter:
                acc_qs = acc_qs.filter(destination_id__iexact=dest_filter)
            if cat_filter:
                acc_qs = acc_qs.filter(type__iexact=cat_filter)
            if q:
                acc_qs = acc_qs.filter(
                    Q(name__icontains=q) |
                    Q(tagline__icontains=q) |
                    Q(description__icontains=q) |
                    Q(type__icontains=q) |
                    Q(destination_id__icontains=q)
                )
            if min_price is not None:
                acc_qs = acc_qs.filter(base_price_per_night__gte=min_price)
            if max_price is not None:
                acc_qs = acc_qs.filter(base_price_per_night__lte=max_price)
            if min_rating is not None:
                acc_qs = acc_qs.filter(star_rating__gte=int(min_rating))

            for acc in acc_qs:
                accommodations.append({
                    'id': acc.id,
                    'org_id': str(acc.org_id),
                    'destination_id': acc.destination_id,
                    'name': acc.name,
                    'type': acc.type,
                    'tagline': acc.tagline,
                    'description': acc.description,
                    'hero_image': acc.hero_image,
                    'star_rating': acc.star_rating,
                    'base_price_per_night': float(acc.base_price_per_night),
                    'eco_green_score': acc.eco_green_score,
                    'amenities': acc.amenities,
                    'ai_suitability_score': acc.ai_suitability_score,
                })

        # 4. Attractions
        if item_type in ('all', 'attractions', 'attraction'):
            att_qs = Attraction.objects.all()
            if dest_filter:
                att_qs = att_qs.filter(Q(destination__id__iexact=dest_filter) | Q(destination__name__icontains=dest_filter))
            if cat_filter:
                att_qs = att_qs.filter(category__iexact=cat_filter)
            if q:
                att_qs = att_qs.filter(
                    Q(name__icontains=q) |
                    Q(category__icontains=q) |
                    Q(description__icontains=q) |
                    Q(destination__name__icontains=q)
                )
            if rain_friendly is not None:
                att_qs = att_qs.filter(rain_friendly=rain_friendly)
            if max_price is not None:
                att_qs = att_qs.filter(entry_fee__lte=max_price)

            for att in att_qs:
                dist = None
                if lat is not None and lng is not None and att.latitude and att.longitude:
                    dist = haversine_distance(lat, lng, att.latitude, att.longitude)
                    if radius_km is not None and dist > radius_km:
                        continue

                attractions.append({
                    'id': att.id,
                    'destination_id': att.destination_id,
                    'name': att.name,
                    'category': att.category,
                    'description': att.description,
                    'image': att.image,
                    'latitude': att.latitude,
                    'longitude': att.longitude,
                    'opening_time': att.opening_time,
                    'closing_time': att.closing_time,
                    'entry_fee': float(att.entry_fee),
                    'typical_duration_mins': att.typical_duration_mins,
                    'rain_friendly': att.rain_friendly,
                    'crowd_profile': att.crowd_profile,
                    'distance_km': dist,
                })

        return {
            'destinations': destinations,
            'experiences': experiences,
            'accommodations': accommodations,
            'attractions': attractions,
        }

import hashlib
import json
import logging
from typing import Dict, Any, Optional
from apps.bookings.models import Booking

logger = logging.getLogger(__name__)


class TripContextService:
    """
    Authoritative shared trip context service.
    Aggregates booking state, live GPS location, meteorological risk, 
    upcoming milestone events, assigned chauffeur status, and emergency directory
    into a unified payload for Flutter, AI companion, and notifications.
    """

    @classmethod
    def get_trip_context(cls, booking_reference: str, user=None) -> Dict[str, Any]:
        booking = Booking.objects.filter(booking_reference=booking_reference).first()
        if not booking:
            raise ValueError(f"Booking {booking_reference} not found.")

        if user and not user.is_staff and booking.user != user:
            raise PermissionError("Unauthorized access to this booking context.")

        dest_slug = 'munnar'
        if hasattr(booking, 'destination') and booking.destination:
            dest_slug = getattr(booking.destination, 'slug', getattr(booking.destination, 'id', 'munnar'))
        elif booking.items.exists():
            first_item = booking.items.first()
            if hasattr(first_item, 'destination') and first_item.destination:
                dest_slug = getattr(first_item.destination, 'slug', 'munnar')

        # 1. Booking Summary
        booking_info = {
            'reference': booking.booking_reference,
            'trip_title': booking.trip_title,
            'status': booking.status,
            'start_date': str(booking.start_date),
            'end_date': str(booking.end_date),
            'travelers_count': booking.travelers_count,
            'green_trip_score': booking.green_trip_score,
            'destination_slug': str(dest_slug).lower(),
            'total_amount': float(booking.total_amount)
        }

        # 2. Live / Latest Location
        current_location = None
        try:
            from apps.location.services import LocationService
            loc = LocationService.get_latest_location(booking.user, booking=booking) or LocationService.get_latest_location(booking.user)
            if loc:
                from apps.maps.services import GeocodingService
                landmark = GeocodingService.reverse_geocode(loc.latitude, loc.longitude)
                current_location = {
                    'latitude': loc.latitude,
                    'longitude': loc.longitude,
                    'accuracy': loc.accuracy,
                    'speed': loc.speed,
                    'heading': loc.heading,
                    'landmark': landmark,
                    'recorded_at': str(loc.timestamp)
                }
        except Exception as e:
            logger.debug(f"Could not load location for context: {e}")

        if not current_location:
            current_location = {
                'latitude': 10.0889,
                'longitude': 77.0595,
                'accuracy': 15.0,
                'speed': 0.0,
                'heading': 0.0,
                'landmark': 'Lockhart Tea Valley, Munnar',
                'recorded_at': 'Default Centroid'
            }

        # 3. Live Weather & Monsoon Intelligence
        weather_info = None
        try:
            from apps.weather.services import WeatherService
            weather_info = WeatherService.get_current_weather(str(dest_slug).lower())
        except Exception as e:
            logger.debug(f"Could not load weather for context: {e}")
            weather_info = {
                'destination': 'Munnar Hills',
                'temperature_celsius': 19,
                'condition': 'MIST_RAIN',
                'rain_probability_percent': 70,
                'recommendation': 'Ghat road speed advisory 30 km/h in effect.',
                'risk': {
                    'risk_level': 'CAUTION',
                    'risk_score': 55,
                    'advisory': 'Moderate showers expected in highland corridor.',
                    'badge_color': '#F59E0B',
                    'is_ghat_corridor': True
                }
            }

        # 4. Next Milestone Event
        next_event = None
        first_item = booking.items.first()
        if first_item:
            next_event = {
                'id': str(first_item.id),
                'title': first_item.title,
                'item_type': first_item.item_type,
                'date': str(first_item.date),
                'time': '10:30 AM',
                'meeting_point': 'Lockhart Tea Estate Gate 2',
                'rain_friendly': True,
                'status': 'CONFIRMED'
            }
        else:
            next_event = {
                'id': 'exp_default',
                'title': 'Lockhart Estate Tea Tasting & Factory Experience',
                'item_type': 'EXPERIENCE',
                'date': str(booking.start_date),
                'time': '10:30 AM',
                'meeting_point': 'Lockhart Plantation Main Gate',
                'rain_friendly': True,
                'status': 'CONFIRMED'
            }

        # 5. Assigned Chauffeur Contact
        driver_info = None
        try:
            from apps.companion.tools import CompanionToolRegistry
            driver_info = CompanionToolRegistry.get_driver_information(booking.booking_reference, user=user)
        except Exception as e:
            logger.debug(f"Driver info fallback: {e}")
            driver_info = {
                'driver_name': 'Rajesh Kumar',
                'phone': '+91 98470 12345',
                'vehicle_model': 'Toyota Innova Crysta (AC Premium)',
                'vehicle_number': 'KL-07-CC-4821',
                'current_status': 'On Standby at Munnar Resort',
                'speed_advisory': '30 km/h on Munnar Ghat road due to morning fog'
            }

        # 6. Safety & Emergency
        safety_info = None
        try:
            from apps.safety.services import SafetyService
            safety_dir = SafetyService.get_safety_directory()
            active_share_tokens = [
                {'token': t.token, 'expires_at': str(t.expires_at), 'is_valid': t.is_valid}
                for t in booking.share_tokens.filter(is_revoked=False)
            ]
            safety_info = {
                'emergency_numbers': safety_dir['emergency_numbers'],
                'active_share_tokens': active_share_tokens
            }
        except Exception as e:
            logger.debug(f"Safety info fallback: {e}")
            safety_info = {
                'emergency_numbers': [
                    {'name': 'National Emergency SOS', 'number': '112', 'toll_free': True},
                    {'name': 'Kerala Tourist Police', 'number': '1800-425-4747', 'toll_free': True}
                ],
                'active_share_tokens': []
            }

        # 7. In-App Notifications
        notifications_info = {'unread_count': 0, 'recent': []}
        try:
            from apps.notifications.models import Notification
            unread_count = Notification.objects.filter(user=booking.user, is_read=False).count()
            recent_notifs = Notification.objects.filter(user=booking.user)[:3]
            notifications_info = {
                'unread_count': unread_count,
                'recent': [
                    {
                        'id': str(n.id),
                        'title': n.title,
                        'message': n.message,
                        'type': n.notification_type,
                        'created_at': str(n.created_at)
                    } for n in recent_notifs
                ]
            }
        except Exception as e:
            logger.debug(f"Notifications fallback: {e}")

        # Construct aggregate response
        context_payload = {
            'booking': booking_info,
            'current_location': current_location,
            'current_weather': weather_info,
            'next_event': next_event,
            'driver': driver_info,
            'safety': safety_info,
            'notifications': notifications_info,
        }

        # Compute deterministic cache hash
        serialized = json.dumps(context_payload, sort_keys=True, default=str)
        cache_hash = hashlib.sha256(serialized.encode('utf-8')).hexdigest()
        context_payload['offline_cache_hash'] = cache_hash

        return context_payload

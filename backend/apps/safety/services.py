import uuid
import datetime
import logging
from typing import Dict, Any, Optional
from django.utils import timezone
from django.conf import settings
from .models import TripShareToken, SafetyAlert

logger = logging.getLogger(__name__)


class SafetyService:
    """
    Central safety service decoupling high-reliability emergency SOS, 
    tourist police dispatch, and temporary public trip-sharing from AI and external dependencies.
    """

    @classmethod
    def get_safety_directory(cls) -> Dict[str, Any]:
        """Returns verified emergency helpline numbers and medical centers across Kerala."""
        return {
            'emergency_numbers': [
                {
                    'name': 'National Emergency SOS',
                    'number': '112',
                    'toll_free': True,
                    'type': 'ALL_EMERGENCY',
                    'description': 'Unified emergency response for Police, Fire, and Ambulance nationwide'
                },
                {
                    'name': 'Kerala Tourist Police Helpline',
                    'number': '1800-425-4747',
                    'toll_free': True,
                    'type': 'TOURIST_POLICE',
                    'description': '24x7 dedicated multi-lingual tourist assistance & guidance'
                },
                {
                    'name': 'Women Safety Mitra Helpline',
                    'number': '181',
                    'toll_free': True,
                    'type': 'WOMEN_SAFETY',
                    'description': 'Kerala Women Police Rapid Response Support'
                },
                {
                    'name': 'Ambulance / Emergency Medical Care',
                    'number': '108',
                    'toll_free': True,
                    'type': 'AMBULANCE',
                    'description': 'State Emergency Medical Services Network'
                },
                {
                    'name': 'Highway Police Control Room',
                    'number': '9846100100',
                    'toll_free': False,
                    'type': 'HIGHWAY_POLICE',
                    'description': 'Direct highway patrol for NH66, NH85 (Munnar Ghat), and MC Road'
                },
            ],
            'hospitals': [
                {
                    'name': 'Tata General Hospital Munnar',
                    'phone': '+91 4865 230222',
                    'location': 'Munnar',
                    'type': 'DISTRICT_HOSPITAL'
                },
                {
                    'name': 'General Hospital Ernakulam',
                    'phone': '+91 484 2361251',
                    'location': 'Kochi',
                    'type': 'SUPER_SPECIALTY'
                },
                {
                    'name': 'General Hospital Alappuzha',
                    'phone': '+91 477 2253324',
                    'location': 'Alappuzha',
                    'type': 'DISTRICT_HOSPITAL'
                }
            ],
            'disaster_management': {
                'state_control_room': '1077',
                'ghat_road_control': '04865-230303',
                'coastal_cyclone_cell': '0471-2331639'
            }
        }

    @classmethod
    def trigger_sos(
        cls,
        user,
        booking_reference: Optional[str] = None,
        latitude: Optional[float] = None,
        longitude: Optional[float] = None,
        location_name: str = '',
        alert_type: str = 'SOS_112',
        notes: str = ''
    ) -> Dict[str, Any]:
        """
        Immediately persists a safety alert and publishes a high-priority domain event.
        Guaranteed to return fast without blocking on AI or external latency.
        """
        booking = None
        if booking_reference:
            from apps.bookings.models import Booking
            booking = Booking.objects.filter(booking_reference=booking_reference).first()

        alert = SafetyAlert.objects.create(
            user=user,
            booking=booking,
            alert_type=alert_type,
            latitude=latitude,
            longitude=longitude,
            location_name=location_name or 'Current GPS coordinates',
            status='TRIGGERED',
            notes=notes
        )

        # Publish outbox event for async SMS / FCM / Control Room dispatch
        try:
            from apps.events.models import OutboxEvent
            OutboxEvent.objects.create(
                event_type='SAFETY_SOS_TRIGGERED',
                aggregate_type='SafetyAlert',
                aggregate_id=str(alert.id),
                payload={
                    'alert_id': str(alert.id),
                    'user_id': str(user.id),
                    'user_email': getattr(user, 'email', ''),
                    'alert_type': alert_type,
                    'latitude': latitude,
                    'longitude': longitude,
                    'location_name': alert.location_name,
                    'booking_reference': booking_reference,
                    'triggered_at': str(alert.created_at)
                }
            )
        except Exception as e:
            logger.warning(f"Could not record OutboxEvent for SOS {alert.id}: {e}")

        return {
            'success': True,
            'alert_id': str(alert.id),
            'alert_type': alert.alert_type,
            'status': alert.status,
            'location': {
                'latitude': alert.latitude,
                'longitude': alert.longitude,
                'location_name': alert.location_name
            },
            'created_at': str(alert.created_at),
            'instructions': [
                '1. Stay calm. An urgent safety alert record has been initiated.',
                '2. Kerala Tourist Police (1800-425-4747) or National Emergency (112) can be tapped directly to dial.',
                '3. If you are on a Ghat mountain road, keep vehicle hazard lights on and pull over away from steep cuts.'
            ],
            'emergency_contacts': cls.get_safety_directory()['emergency_numbers']
        }

    @classmethod
    def generate_share_token(
        cls,
        user,
        booking_reference: str,
        expiry_hours: int = 24
    ) -> Dict[str, Any]:
        """
        Creates a time-bound, revocable cryptographic token to share live trip progress.
        """
        from apps.bookings.models import Booking
        booking = Booking.objects.filter(booking_reference=booking_reference).first()
        if not booking:
            raise ValueError(f"Booking {booking_reference} not found.")

        if not (user.is_staff or booking.user == user):
            raise PermissionError("Unauthorized to share this trip.")

        expires_at = timezone.now() + datetime.timedelta(hours=expiry_hours)
        token_obj = TripShareToken.objects.create(
            booking=booking,
            user=user,
            expires_at=expires_at
        )

        return {
            'token': token_obj.token,
            'booking_reference': booking.booking_reference,
            'expires_at': str(token_obj.expires_at),
            'share_url': f"/api/v1/safety/shared/{token_obj.token}/",
            'is_valid': True
        }

    @classmethod
    def revoke_share_token(cls, user, token_str: str) -> Dict[str, Any]:
        """Revokes an existing trip share token."""
        token_obj = TripShareToken.objects.filter(token=token_str).first()
        if not token_obj:
            raise ValueError("Share token not found.")

        if not (user.is_staff or token_obj.user == user):
            raise PermissionError("Unauthorized to revoke this share token.")

        token_obj.revoke()
        return {
            'revoked': True,
            'token': token_str
        }

    @classmethod
    def get_public_trip_share_data(cls, token_str: str) -> Dict[str, Any]:
        """
        Returns sanitized, privacy-safe trip status for public family/friends view.
        Strictly scrubs traveler PII, payment info, and credentials.
        """
        token_obj = TripShareToken.objects.filter(token=token_str).first()
        if not token_obj or not token_obj.is_valid:
            return {
                'valid': False,
                'error': 'This trip share link has expired or has been revoked by the traveler.'
            }

        booking = token_obj.booking
        # Mask booking reference e.g. KL2609051234 -> KL***1234
        ref = booking.booking_reference
        masked_ref = f"{ref[:2]}***{ref[-4:]}" if len(ref) >= 6 else "***"

        # Latest location if available
        location_data = None
        try:
            from apps.location.services import LocationService
            latest_loc = LocationService.get_latest_location(booking.user)
            if latest_loc:
                from apps.maps.services import GeocodingService
                landmark = GeocodingService.reverse_geocode(latest_loc.latitude, latest_loc.longitude)
                location_data = {
                    'latitude': latest_loc.latitude,
                    'longitude': latest_loc.longitude,
                    'landmark': landmark,
                    'recorded_at': str(latest_loc.timestamp)
                }
        except Exception:
            pass

        # Sanitized itinerary highlights (no financial info)
        items_summary = []
        for item in booking.items.all().order_by('date'):
            items_summary.append({
                'title': item.title,
                'item_type': item.item_type,
                'date': str(item.date),
                'status': 'CONFIRMED'
            })

        return {
            'valid': True,
            'trip_title': booking.trip_title,
            'masked_reference': masked_ref,
            'start_date': str(booking.start_date),
            'end_date': str(booking.end_date),
            'status': booking.status,
            'latest_location': location_data,
            'itinerary': items_summary,
            'emergency_contacts': cls.get_safety_directory()['emergency_numbers'],
            'expires_at': str(token_obj.expires_at)
        }

from typing import Optional, Dict, Any, List
import logging
from django.core.exceptions import PermissionDenied
from .models import TravelerLocation

logger = logging.getLogger(__name__)

class LocationService:
    @classmethod
    def record_location(
        cls,
        user,
        latitude: float,
        longitude: float,
        accuracy: float = 10.0,
        speed: Optional[float] = None,
        heading: Optional[float] = None,
        booking_reference: Optional[str] = None
    ) -> TravelerLocation:
        """
        Ingests and validates traveler coordinates, enforces trip ownership,
        and evaluates proximity triggers for active waypoints.
        """
        booking = None
        if booking_reference:
            from apps.bookings.models import Booking
            booking = Booking.objects.filter(booking_reference=booking_reference).first()
            if booking and booking.user != user and not user.is_staff:
                raise PermissionDenied("Unauthorized access to this booking location")

        loc = TravelerLocation.objects.create(
            user=user,
            booking=booking,
            latitude=latitude,
            longitude=longitude,
            accuracy=accuracy,
            speed=speed,
            heading=heading
        )

        # Evaluate proximity trigger asynchronously or inline
        try:
            from apps.notifications.services import ProximityEngine
            if booking:
                ProximityEngine.evaluate_proximity(user, booking, latitude, longitude)
        except Exception as e:
            logger.debug(f"Proximity check non-critical failure: {e}")

        return loc

    @classmethod
    def get_latest_location(cls, user, booking=None) -> Optional[TravelerLocation]:
        qs = TravelerLocation.objects.filter(user=user)
        if booking:
            qs = qs.filter(booking=booking)
        return qs.first()

    @classmethod
    def get_trip_locations(cls, user, booking_reference: str) -> List[TravelerLocation]:
        from apps.bookings.models import Booking
        booking = Booking.objects.filter(booking_reference=booking_reference).first()
        if not booking:
            return []
        if booking.user != user and not user.is_staff:
            raise PermissionDenied("Unauthorized access to trip location history")
        return list(TravelerLocation.objects.filter(booking=booking)[:50])

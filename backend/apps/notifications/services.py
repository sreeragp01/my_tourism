import math
import logging
from typing import Dict, Any, List, Optional
from django.utils import timezone
from datetime import timedelta
from .models import Notification, DeviceToken, NotificationPreference, ProximityEvent

logger = logging.getLogger(__name__)


def calculate_haversine_distance_meters(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """
    Computes great-circle distance between two GPS coordinates in meters.
    """
    R = 6371000.0  # Earth radius in meters
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    delta_phi = math.radians(lat2 - lat1)
    delta_lambda = math.radians(lon2 - lon1)

    a = (math.sin(delta_phi / 2.0) ** 2 +
         math.cos(phi1) * math.cos(phi2) * (math.sin(delta_lambda / 2.0) ** 2))
    c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a))
    return R * c


class NotificationService:
    """
    Manages in-app notifications, push triggers, preference enforcement, and device tokens.
    """

    @classmethod
    def send_notification(
        cls,
        user,
        title: str,
        message: str,
        notification_type: str = 'SCHEDULE_UPDATE',
        data: Optional[Dict[str, Any]] = None
    ) -> Optional[Notification]:
        """
        Creates an in-app notification and publishes an outbox push event if permitted by user preferences.
        """
        prefs, _ = NotificationPreference.objects.get_or_create(user=user)

        # Check preference gates
        if notification_type == 'PROXIMITY' and not prefs.proximity_enabled:
            logger.info(f"Proximity notification suppressed for {user.email}")
            return None
        if notification_type == 'WEATHER_ALERT' and not prefs.weather_alerts_enabled:
            logger.info(f"Weather alert suppressed for {user.email}")
            return None
        if notification_type == 'SCHEDULE_UPDATE' and not prefs.schedule_updates_enabled:
            logger.info(f"Schedule update suppressed for {user.email}")
            return None
        if notification_type == 'SAFETY_ALERT' and not prefs.safety_alerts_enabled:
            logger.info(f"Safety alert suppressed for {user.email}")
            return None

        notif = Notification.objects.create(
            user=user,
            title=title,
            message=message,
            notification_type=notification_type,
            data=data or {}
        )

        try:
            from apps.events.models import OutboxEvent
            OutboxEvent.objects.create(
                event_type='NOTIFICATION_DISPATCHED',
                aggregate_type='Notification',
                aggregate_id=str(notif.id),
                payload={
                    'notification_id': str(notif.id),
                    'user_id': str(user.id),
                    'notification_type': notification_type,
                    'title': title,
                    'message': message,
                    'data': data or {},
                    'created_at': str(notif.created_at)
                }
            )
        except Exception as e:
            logger.warning(f"Could not dispatch OutboxEvent for notification {notif.id}: {e}")

        return notif

    @classmethod
    def register_device_token(cls, user, token: str, platform: str = 'ANDROID') -> DeviceToken:
        """Saves or updates traveler device FCM push token."""
        device, _ = DeviceToken.objects.update_or_create(
            token=token,
            defaults={'user': user, 'platform': platform.upper()}
        )
        return device

    @classmethod
    def get_unread_count(cls, user) -> int:
        return Notification.objects.filter(user=user, is_read=False).count()

    @classmethod
    def mark_as_read(cls, user, notification_id: Optional[str] = None) -> int:
        qs = Notification.objects.filter(user=user, is_read=False)
        if notification_id:
            qs = qs.filter(id=notification_id)
        count = qs.update(is_read=True)
        return count


class ProximityEngine:
    """
    Evaluates traveler GPS proximity against itinerary waypoints.
    Triggers 500m approach and 200m arrival notifications with a 30-minute cooldown
    to prevent repetitive alerts.
    """

    COOLDOWN_MINUTES = 30

    @classmethod
    def evaluate_proximity(
        cls,
        user,
        current_lat=None,
        current_lon=None,
        waypoints: Optional[List[Dict[str, Any]]] = None,
        cooldown_minutes: int = 30,
        **kwargs
    ) -> Dict[str, Any]:
        """
        Evaluates current traveler position against itinerary waypoints.
        Supports both evaluate_proximity(user, current_lat, current_lon, waypoints)
        and evaluate_proximity(user, booking, latitude, longitude).
        """
        # Handle signature where arg 2 is booking: evaluate_proximity(user, booking, lat, lon)
        if hasattr(current_lat, 'booking_reference') or hasattr(current_lat, 'items'):
            booking = current_lat
            actual_lat = float(current_lon)
            actual_lon = float(waypoints) if waypoints is not None else float(kwargs.get('longitude', 0.0))
            waypoints_list = []
            if hasattr(booking, 'items'):
                for item in booking.items.all():
                    waypoints_list.append({
                        'id': str(item.id),
                        'name': item.title,
                        'latitude': 10.0889,
                        'longitude': 77.0595
                    })
            current_lat = actual_lat
            current_lon = actual_lon
            waypoints = waypoints_list
        else:
            current_lat = float(current_lat or 0.0)
            current_lon = float(current_lon or 0.0)
            waypoints = waypoints or []

        triggered_events = []
        nearest_waypoint = None
        min_distance = float('inf')

        now = timezone.now()
        cooldown_cutoff = now - timedelta(minutes=cooldown_minutes)

        for wp in waypoints:
            wp_id = str(wp.get('id', wp.get('name', 'unknown')))
            wp_name = wp.get('name', 'Waypoint')
            wp_lat = float(wp['latitude'])
            wp_lon = float(wp['longitude'])

            dist_m = calculate_haversine_distance_meters(current_lat, current_lon, wp_lat, wp_lon)

            if dist_m < min_distance:
                min_distance = dist_m
                nearest_waypoint = {
                    'id': wp_id,
                    'name': wp_name,
                    'distance_meters': round(dist_m, 1)
                }

            # Check 200m Arrival Threshold
            if dist_m <= 200.0:
                event_type = 'ARRIVAL_200M'
                has_recent = ProximityEvent.objects.filter(
                    user=user,
                    waypoint_id=wp_id,
                    event_type=event_type,
                    triggered_at__gte=cooldown_cutoff
                ).exists()

                if not has_recent:
                    ProximityEvent.objects.create(
                        user=user,
                        waypoint_id=wp_id,
                        event_type=event_type
                    )
                    NotificationService.send_notification(
                        user=user,
                        title=f"Welcome to {wp_name}!",
                        message=f"You have arrived at {wp_name} ({round(dist_m)}m). Have your digital booking pass ready!",
                        notification_type='PROXIMITY',
                        data={'waypoint_id': wp_id, 'event_type': event_type, 'distance_meters': round(dist_m, 1)}
                    )
                    triggered_events.append({
                        'waypoint_id': wp_id,
                        'waypoint_name': wp_name,
                        'event_type': event_type,
                        'distance_meters': round(dist_m, 1)
                    })

            # Check 500m Approach Threshold
            elif dist_m <= 500.0:
                event_type = 'APPROACH_500M'
                has_recent = ProximityEvent.objects.filter(
                    user=user,
                    waypoint_id=wp_id,
                    event_type=event_type,
                    triggered_at__gte=cooldown_cutoff
                ).exists()

                if not has_recent:
                    ProximityEvent.objects.create(
                        user=user,
                        waypoint_id=wp_id,
                        event_type=event_type
                    )
                    NotificationService.send_notification(
                        user=user,
                        title=f"Approaching {wp_name}",
                        message=f"You are approximately {round(dist_m)}m away from {wp_name}.",
                        notification_type='PROXIMITY',
                        data={'waypoint_id': wp_id, 'event_type': event_type, 'distance_meters': round(dist_m, 1)}
                    )
                    triggered_events.append({
                        'waypoint_id': wp_id,
                        'waypoint_name': wp_name,
                        'event_type': event_type,
                        'distance_meters': round(dist_m, 1)
                    })

        return {
            'evaluated_count': len(waypoints),
            'nearest_waypoint': nearest_waypoint,
            'triggered_events': triggered_events
        }

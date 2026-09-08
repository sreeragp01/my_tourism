from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions
from .models import Notification, NotificationPreference
from .services import NotificationService, ProximityEngine
from .serializers import (
    NotificationSerializer,
    NotificationPreferenceSerializer,
    DeviceTokenSerializer,
    ProximityCheckSerializer
)


class NotificationListView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        notifications = Notification.objects.filter(user=request.user)[:50]
        serializer = NotificationSerializer(notifications, many=True)
        unread_count = NotificationService.get_unread_count(request.user)
        return Response({
            'unread_count': unread_count,
            'notifications': serializer.data
        }, status=status.HTTP_200_OK)

    def post(self, request):
        """Mark one or all notifications as read."""
        notif_id = request.data.get('notification_id')
        marked_count = NotificationService.mark_as_read(request.user, notif_id)
        return Response({
            'success': True,
            'marked_read': marked_count,
            'unread_count': NotificationService.get_unread_count(request.user)
        }, status=status.HTTP_200_OK)


class NotificationPreferenceView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        prefs, _ = NotificationPreference.objects.get_or_create(user=request.user)
        serializer = NotificationPreferenceSerializer(prefs)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def put(self, request):
        prefs, _ = NotificationPreference.objects.get_or_create(user=request.user)
        serializer = NotificationPreferenceSerializer(prefs, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data, status=status.HTTP_200_OK)


class DeviceTokenRegisterView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = DeviceTokenSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        device = NotificationService.register_device_token(
            user=request.user,
            token=data['token'],
            platform=data.get('platform', 'ANDROID')
        )
        return Response(DeviceTokenSerializer(device).data, status=status.HTTP_200_OK)


class ProximityCheckView(APIView):
    """
    Evaluates current GPS location against active trip waypoints.
    Triggers automated proximity arrival/approach notifications with 30-min cooldown.
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = ProximityCheckSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        lat = data['latitude']
        lon = data['longitude']
        waypoints = data.get('waypoints', [])
        booking_ref = data.get('booking_reference')

        # If waypoints not supplied in request, pull them from the booking if provided
        if not waypoints and booking_ref:
            from apps.bookings.models import Booking
            b = Booking.objects.filter(booking_reference=booking_ref).first()
            if b:
                # Add destination/experience waypoints
                waypoints.append({
                    'id': f"{b.booking_reference}_stay",
                    'name': f"{b.destination.name if b.destination else 'Resort'} Meeting Point",
                    'latitude': 10.0889,
                    'longitude': 77.0595
                })

        result = ProximityEngine.evaluate_proximity(
            user=request.user,
            current_lat=lat,
            current_lon=lon,
            waypoints=waypoints
        )

        return Response(result, status=status.HTTP_200_OK)

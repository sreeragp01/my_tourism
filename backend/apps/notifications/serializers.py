from rest_framework import serializers
from .models import Notification, DeviceToken, NotificationPreference


class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = [
            'id',
            'title',
            'message',
            'notification_type',
            'data',
            'is_read',
            'created_at'
        ]
        read_only_fields = ['id', 'created_at']


class NotificationPreferenceSerializer(serializers.ModelSerializer):
    class Meta:
        model = NotificationPreference
        fields = [
            'proximity_enabled',
            'weather_alerts_enabled',
            'schedule_updates_enabled',
            'safety_alerts_enabled',
            'updated_at'
        ]
        read_only_fields = ['updated_at']


class DeviceTokenSerializer(serializers.ModelSerializer):
    class Meta:
        model = DeviceToken
        fields = ['token', 'platform', 'updated_at']
        read_only_fields = ['updated_at']


class ProximityCheckSerializer(serializers.Serializer):
    latitude = serializers.FloatField(required=True)
    longitude = serializers.FloatField(required=True)
    booking_reference = serializers.CharField(required=False, allow_blank=True)
    waypoints = serializers.ListField(
        child=serializers.DictField(),
        required=False,
        default=list
    )

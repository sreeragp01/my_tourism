from rest_framework import serializers
from .models import TripShareToken, SafetyAlert


class SafetyAlertSerializer(serializers.ModelSerializer):
    class Meta:
        model = SafetyAlert
        fields = [
            'id',
            'alert_type',
            'latitude',
            'longitude',
            'location_name',
            'status',
            'notes',
            'created_at',
            'resolved_at'
        ]
        read_only_fields = ['id', 'status', 'created_at', 'resolved_at']


class TriggerSOSRequestSerializer(serializers.Serializer):
    booking_reference = serializers.CharField(required=False, allow_blank=True)
    latitude = serializers.FloatField(required=False)
    longitude = serializers.FloatField(required=False)
    location_name = serializers.CharField(required=False, allow_blank=True, default='')
    alert_type = serializers.CharField(default='SOS_112')
    notes = serializers.CharField(required=False, allow_blank=True, default='')


class CreateTripShareRequestSerializer(serializers.Serializer):
    booking_reference = serializers.CharField(required=True)
    expiry_hours = serializers.IntegerField(default=24, min_value=1, max_value=168)


class TripShareTokenSerializer(serializers.ModelSerializer):
    is_valid = serializers.BooleanField(read_only=True)

    class Meta:
        model = TripShareToken
        fields = [
            'id',
            'token',
            'created_at',
            'expires_at',
            'is_revoked',
            'is_valid'
        ]
        read_only_fields = ['id', 'token', 'created_at', 'expires_at', 'is_revoked', 'is_valid']

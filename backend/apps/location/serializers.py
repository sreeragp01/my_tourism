from rest_framework import serializers
from .models import TravelerLocation

class LocationUpdateSerializer(serializers.Serializer):
    latitude = serializers.FloatField(min_value=-90.0, max_value=90.0)
    longitude = serializers.FloatField(min_value=-180.0, max_value=180.0)
    accuracy = serializers.FloatField(required=False, default=10.0)
    speed = serializers.FloatField(required=False, allow_null=True)
    heading = serializers.FloatField(required=False, allow_null=True)
    booking_reference = serializers.CharField(required=False, allow_blank=True, max_length=32)

class TravelerLocationSerializer(serializers.ModelSerializer):
    class Meta:
        model = TravelerLocation
        fields = ['id', 'latitude', 'longitude', 'accuracy', 'speed', 'heading', 'timestamp']

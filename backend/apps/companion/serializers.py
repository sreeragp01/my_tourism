from rest_framework import serializers

class CompanionMessageRequestSerializer(serializers.Serializer):
    query = serializers.CharField(max_length=1000)
    current_destination = serializers.CharField(max_length=64, required=False, default='munnar')
    destination_slug = serializers.CharField(max_length=64, required=False, default=None)
    trip_day = serializers.IntegerField(default=2, required=False)
    weather_condition = serializers.CharField(max_length=50, default='MIST_RAIN', required=False)
    booking_reference = serializers.CharField(max_length=64, required=False, allow_null=True, default=None)

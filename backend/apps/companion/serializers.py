from rest_framework import serializers

class CompanionMessageRequestSerializer(serializers.Serializer):
    query = serializers.CharField(max_length=500)
    current_destination = serializers.CharField(max_length=64, default='munnar')
    trip_day = serializers.IntegerField(default=2)
    weather_condition = serializers.CharField(max_length=50, default='MIST_RAIN')

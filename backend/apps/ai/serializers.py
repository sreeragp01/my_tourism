from rest_framework import serializers

class ParsePromptRequestSerializer(serializers.Serializer):
    prompt = serializers.CharField(max_length=1000)

class GenerateItineraryRequestSerializer(serializers.Serializer):
    duration_days = serializers.IntegerField(default=6, min_value=1, max_value=30)
    budget_limit = serializers.FloatField(default=80000.0)
    interests = serializers.ListField(child=serializers.CharField(), default=list)
    avoidances = serializers.ListField(child=serializers.CharField(), default=list)
    adults = serializers.IntegerField(default=2, min_value=1)
    travel_style = serializers.CharField(default='PREMIUM')
    pace = serializers.CharField(default='BALANCED')
    origin = serializers.CharField(default='Kochi')

class SubstituteRainRequestSerializer(serializers.Serializer):
    day_number = serializers.IntegerField()
    outdoor_item_id = serializers.CharField()
    destination_id = serializers.CharField()

class RouteOptimizeRequestSerializer(serializers.Serializer):
    origin = serializers.DictField()
    destination = serializers.DictField()
    is_ghat_route = serializers.BooleanField(default=False)

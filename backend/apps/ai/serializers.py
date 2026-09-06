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
    raw_prompt = serializers.CharField(required=False, allow_blank=True, default='')

class CustomizePlanRequestSerializer(serializers.Serializer):
    action = serializers.ChoiceField(choices=[
        'SUBSTITUTE_RAIN',
        'REMOVE_ACTIVITY',
        'REPLACE_ACTIVITY',
        'ADD_ACTIVITY',
        'REORDER'
    ])
    day_number = serializers.IntegerField(min_value=1)
    timeline_event_id = serializers.CharField(required=False, allow_blank=True, default=None)
    new_event = serializers.DictField(required=False, default=None)
    reason = serializers.CharField(required=False, allow_blank=True, default=None)

class RegeneratePlanRequestSerializer(serializers.Serializer):
    reason = serializers.CharField(required=False, default='Traveler requested complete replan')
    preferences_override = serializers.DictField(required=False, default=dict)

class SubstituteRainPlanRequestSerializer(serializers.Serializer):
    day_number = serializers.IntegerField(min_value=1)
    destination_id = serializers.CharField(required=False, default='munnar')

class SubstituteRainRequestSerializer(serializers.Serializer):
    day_number = serializers.IntegerField(min_value=1)
    outdoor_item_id = serializers.CharField(required=False, default='Outdoor Activity')
    destination_id = serializers.CharField(required=False, default='munnar')

class RouteOptimizeRequestSerializer(serializers.Serializer):
    origin = serializers.DictField()
    destination = serializers.DictField()
    is_ghat_route = serializers.BooleanField(default=False)

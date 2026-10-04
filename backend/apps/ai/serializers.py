from rest_framework import serializers

class ParsePromptRequestSerializer(serializers.Serializer):
    prompt = serializers.CharField(max_length=1000)

class GenerateItineraryRequestSerializer(serializers.Serializer):
    duration_days = serializers.IntegerField(default=6, min_value=1, max_value=30)
    budget_limit = serializers.FloatField(default=80000.0)
    month = serializers.CharField(required=False, default='October')
    monsoon_mode = serializers.BooleanField(required=False, default=False)
    interests = serializers.ListField(child=serializers.CharField(), default=list)
    avoidances = serializers.ListField(child=serializers.CharField(), default=list)
    adults = serializers.IntegerField(default=2, min_value=1)
    travel_style = serializers.CharField(default='PREMIUM')
    pace = serializers.CharField(default='BALANCED')
    origin = serializers.CharField(default='Kochi')
    raw_prompt = serializers.CharField(required=False, allow_blank=True, default='')

class CustomizePlanRequestSerializer(serializers.Serializer):
    VALID_OPERATIONS = [
        'MOVE_EVENT',
        'ADD_EVENT',
        'ADD_ACTIVITY',
        'REMOVE_EVENT',
        'REMOVE_ACTIVITY',
        'SWAP_EVENT',
        'REPLACE_ACTIVITY',
        'SUBSTITUTE_RAIN',
        'RAIN_SUBSTITUTE',
        'REORDER',
        'CHANGE_DAY',
    ]

    action = serializers.CharField(required=False, allow_blank=True, default=None)
    operation = serializers.CharField(required=False, allow_blank=True, default=None)
    day_number = serializers.IntegerField(min_value=1, default=1)
    target_day = serializers.IntegerField(required=False, default=None, allow_null=True)
    target_day_number = serializers.IntegerField(required=False, default=None, allow_null=True)
    target_order = serializers.IntegerField(required=False, default=None, allow_null=True, min_value=1)
    event_id = serializers.CharField(required=False, allow_blank=True, default=None)
    timeline_event_id = serializers.CharField(required=False, allow_blank=True, default=None)
    swap_with_event_id = serializers.CharField(required=False, allow_blank=True, default=None)
    entity_type = serializers.CharField(required=False, allow_blank=True, default=None)
    entity_id = serializers.CharField(required=False, allow_blank=True, default=None)
    new_event = serializers.DictField(required=False, default=None)
    reason = serializers.CharField(required=False, allow_blank=True, default=None)

    def validate(self, attrs):
        op = (attrs.get('operation') or attrs.get('action') or '').upper()
        if not op:
            raise serializers.ValidationError("Either 'operation' or 'action' must be specified.")
        if op not in self.VALID_OPERATIONS:
            raise serializers.ValidationError(f"Invalid operation '{op}'. Supported: {', '.join(self.VALID_OPERATIONS)}")
        attrs['action'] = op
        attrs['operation'] = op
        attrs['event_id'] = attrs.get('event_id') or attrs.get('timeline_event_id')
        attrs['timeline_event_id'] = attrs['event_id']
        attrs['target_day'] = attrs.get('target_day') if attrs.get('target_day') is not None else attrs.get('target_day_number')
        attrs['target_day_number'] = attrs['target_day']
        return attrs

class RevertPlanRequestSerializer(serializers.Serializer):
    target_version = serializers.IntegerField(min_value=1)
    reason = serializers.CharField(required=False, allow_blank=True, default=None)

class CandidateSearchRequestSerializer(serializers.Serializer):
    day_number = serializers.IntegerField(default=1, min_value=1)
    entity_type = serializers.CharField(required=False, allow_blank=True, default=None)
    rain_friendly_only = serializers.BooleanField(required=False, default=False)

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

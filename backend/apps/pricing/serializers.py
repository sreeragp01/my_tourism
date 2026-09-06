from rest_framework import serializers

class PriceCalculateRequestSerializer(serializers.Serializer):
    days_count = serializers.IntegerField(default=6, min_value=1)
    travelers_count = serializers.IntegerField(default=2, min_value=1)
    stays = serializers.ListField(child=serializers.DictField(), default=list)
    experiences = serializers.ListField(child=serializers.DictField(), default=list)
    transport_mode = serializers.CharField(default='SEDAN')
    promo_code = serializers.CharField(required=False, allow_blank=True, default=None)

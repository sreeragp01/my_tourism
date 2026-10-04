from rest_framework import serializers


class SearchQuerySerializer(serializers.Serializer):
    q = serializers.CharField(required=False, allow_blank=True, default='')
    destination = serializers.CharField(required=False, allow_blank=True, allow_null=True, default=None)
    category = serializers.CharField(required=False, allow_blank=True, allow_null=True, default=None)
    type = serializers.ChoiceField(
        choices=['all', 'destinations', 'experiences', 'accommodations', 'stays', 'attractions'],
        default='all',
        required=False
    )
    min_price = serializers.FloatField(required=False, min_value=0, allow_null=True, default=None)
    max_price = serializers.FloatField(required=False, min_value=0, allow_null=True, default=None)
    rain_friendly = serializers.BooleanField(required=False, allow_null=True, default=None)
    family_friendly = serializers.BooleanField(required=False, allow_null=True, default=None)
    min_rating = serializers.FloatField(required=False, min_value=0, max_value=5.0, allow_null=True, default=None)
    page = serializers.IntegerField(required=False, default=1, min_value=1)
    page_size = serializers.IntegerField(required=False, default=20, min_value=1, max_value=100)
    lat = serializers.FloatField(required=False)
    lng = serializers.FloatField(required=False)
    radius_km = serializers.FloatField(required=False, min_value=0)

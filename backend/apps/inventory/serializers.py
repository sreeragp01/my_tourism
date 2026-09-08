from rest_framework import serializers
from .models import InventoryHold


class InventoryHoldSerializer(serializers.ModelSerializer):
    is_valid = serializers.BooleanField(read_only=True)
    remaining_seconds = serializers.IntegerField(read_only=True)

    class Meta:
        model = InventoryHold
        fields = [
            'id',
            'user',
            'booking_id',
            'itinerary_version_id',
            'date',
            'inventory_type',
            'inventory_id',
            'quantity',
            'status',
            'expires_at',
            'created_at',
            'remaining_seconds',
            'is_valid',
        ]
        read_only_fields = ['id', 'user', 'status', 'expires_at', 'created_at']


class AvailabilityQuerySerializer(serializers.Serializer):
    inventory_type = serializers.ChoiceField(choices=['ROOM', 'EXPERIENCE', 'room', 'experience'])
    inventory_id = serializers.CharField(max_length=128)
    date = serializers.DateField(required=False, allow_null=True)
    quantity = serializers.IntegerField(default=1, min_value=1)


class CreateHoldRequestSerializer(serializers.Serializer):
    inventory_type = serializers.ChoiceField(choices=['ROOM', 'EXPERIENCE', 'room', 'experience'])
    inventory_id = serializers.CharField(max_length=128)
    quantity = serializers.IntegerField(default=1, min_value=1)
    date = serializers.DateField(required=False, allow_null=True)
    dates = serializers.ListField(child=serializers.DateField(), required=False, allow_empty=True)
    itinerary_version_id = serializers.CharField(max_length=128, required=False, allow_blank=True, allow_null=True)
    booking_id = serializers.UUIDField(required=False, allow_null=True)
    duration_mins = serializers.IntegerField(default=15, min_value=1, max_value=60)


class BatchItineraryHoldItemSerializer(serializers.Serializer):
    inventory_type = serializers.ChoiceField(choices=['ROOM', 'EXPERIENCE', 'room', 'experience'])
    inventory_id = serializers.CharField(max_length=128)
    date = serializers.DateField(required=False, allow_null=True)
    quantity = serializers.IntegerField(default=1, min_value=1)


class BatchItineraryHoldRequestSerializer(serializers.Serializer):
    itinerary_version_id = serializers.CharField(max_length=128, required=False, allow_blank=True, allow_null=True)
    booking_id = serializers.UUIDField(required=False, allow_null=True)
    items = serializers.ListField(child=BatchItineraryHoldItemSerializer(), min_length=1)
    duration_mins = serializers.IntegerField(default=15, min_value=1, max_value=60)


class ExtendHoldRequestSerializer(serializers.Serializer):
    extra_minutes = serializers.IntegerField(default=10, min_value=1, max_value=30)

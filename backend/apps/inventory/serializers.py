from rest_framework import serializers
from .models import InventoryHold

class InventoryHoldSerializer(serializers.ModelSerializer):
    is_valid = serializers.BooleanField(read_only=True)

    class Meta:
        model = InventoryHold
        fields = ['id', 'booking_id', 'inventory_type', 'inventory_id', 'quantity', 'status', 'expires_at', 'created_at', 'is_valid']

class CreateHoldRequestSerializer(serializers.Serializer):
    booking_id = serializers.UUIDField()
    inventory_type = serializers.ChoiceField(choices=['ROOM', 'EXPERIENCE'])
    inventory_id = serializers.CharField(max_length=128)
    quantity = serializers.IntegerField(default=1, min_value=1)
    dates = serializers.ListField(child=serializers.DateField(), required=False)

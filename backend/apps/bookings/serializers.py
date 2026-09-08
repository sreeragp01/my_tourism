from rest_framework import serializers
from .models import Booking, BookingItem

class BookingItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = BookingItem
        fields = [
            'id', 'item_type', 'entity_type', 'entity_id', 'inventory_hold',
            'title', 'date', 'units', 'quantity', 'unit_price', 'subtotal',
            'total_price', 'provider_org_id'
        ]

class BookingSerializer(serializers.ModelSerializer):
    items = BookingItemSerializer(many=True, read_only=True)

    class Meta:
        model = Booking
        fields = [
            'id', 'booking_reference', 'user', 'itinerary_version_id', 'trip_title',
            'start_date', 'end_date', 'travelers_count', 'primary_guest_name',
            'primary_guest_phone', 'primary_guest_email', 'status', 'subtotal',
            'tax', 'platform_fee', 'total_amount', 'currency', 'idempotency_key',
            'green_trip_score', 'digital_pass_token', 'qr_code_url', 'confirmed_at',
            'created_at', 'updated_at', 'items'
        ]
        read_only_fields = [
            'id', 'booking_reference', 'status', 'subtotal', 'tax', 'platform_fee',
            'digital_pass_token', 'qr_code_url', 'confirmed_at', 'created_at', 'updated_at'
        ]

class CreateBookingRequestSerializer(serializers.Serializer):
    trip_title = serializers.CharField(max_length=255, required=False, default="Kerala Curated Tour")
    start_date = serializers.DateField(required=False)
    end_date = serializers.DateField(required=False)
    travelers_count = serializers.IntegerField(default=2, min_value=1)
    primary_guest_name = serializers.CharField(max_length=150)
    primary_guest_phone = serializers.CharField(max_length=20)
    primary_guest_email = serializers.EmailField()
    idempotency_key = serializers.CharField(max_length=128)
    itinerary_version_id = serializers.CharField(max_length=64, required=False, allow_blank=True, allow_null=True)
    hold_ids = serializers.ListField(child=serializers.CharField(), required=False, default=list)
    items = serializers.ListField(child=serializers.DictField(), required=False, default=list)

    def validate(self, attrs):
        if not attrs.get('hold_ids') and not attrs.get('items'):
            raise serializers.ValidationError("Either 'hold_ids' or 'items' must be provided.")
        if not attrs.get('hold_ids'):
            if not attrs.get('start_date') or not attrs.get('end_date'):
                raise serializers.ValidationError("start_date and end_date are required when creating direct items.")
        return attrs

class TransitionStateRequestSerializer(serializers.Serializer):
    target_state = serializers.CharField(max_length=32)
    reason = serializers.CharField(max_length=255, required=False, default="")

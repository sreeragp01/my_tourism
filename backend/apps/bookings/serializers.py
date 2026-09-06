from rest_framework import serializers
from .models import Booking, BookingItem

class BookingItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = BookingItem
        fields = ['id', 'item_type', 'title', 'date', 'units', 'unit_price', 'subtotal', 'provider_org_id']

class BookingSerializer(serializers.ModelSerializer):
    items = BookingItemSerializer(many=True, read_only=True)

    class Meta:
        model = Booking
        fields = [
            'id', 'booking_reference', 'user', 'trip_title', 'start_date', 'end_date',
            'travelers_count', 'primary_guest_name', 'primary_guest_phone', 'primary_guest_email',
            'status', 'total_amount', 'currency', 'idempotency_key', 'green_trip_score',
            'qr_code_url', 'confirmed_at', 'created_at', 'updated_at', 'items'
        ]
        read_only_fields = ['id', 'booking_reference', 'status', 'qr_code_url', 'confirmed_at', 'created_at', 'updated_at']

class CreateBookingRequestSerializer(serializers.Serializer):
    trip_title = serializers.CharField(max_length=255)
    start_date = serializers.DateField()
    end_date = serializers.DateField()
    travelers_count = serializers.IntegerField(default=2, min_value=1)
    primary_guest_name = serializers.CharField(max_length=150)
    primary_guest_phone = serializers.CharField(max_length=20)
    primary_guest_email = serializers.EmailField()
    idempotency_key = serializers.CharField(max_length=128)
    items = serializers.ListField(child=serializers.DictField())

class TransitionStateRequestSerializer(serializers.Serializer):
    target_state = serializers.CharField(max_length=32)
    reason = serializers.CharField(max_length=255, required=False, default="")

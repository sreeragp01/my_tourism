import random
from rest_framework import serializers
from .models import VehicleCategory, AirportTransferRoute, CabBooking

class VehicleCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = VehicleCategory
        fields = [
            'id', 'name', 'vehicle_type', 'tagline', 'description',
            'passenger_capacity', 'luggage_capacity', 'has_ac',
            'has_mountain_permit', 'hero_image', 'base_rate_per_km',
            'daily_rental_rate', 'driver_bata_per_day', 'features',
            'rating', 'trip_count', 'is_active'
        ]

class AirportTransferRouteSerializer(serializers.ModelSerializer):
    class Meta:
        model = AirportTransferRoute
        fields = [
            'id', 'airport_code', 'airport_name', 'destination_name',
            'district', 'distance_km', 'approx_duration_hours',
            'is_ghat_road', 'toll_and_parking_included',
            'sedan_fare', 'suv_crysta_fare', 'tempo_fare', 'is_popular'
        ]

class CabBookingSerializer(serializers.ModelSerializer):
    vehicle_details = serializers.SerializerMethodField(read_only=True)
    driver_details = serializers.SerializerMethodField(read_only=True)

    class Meta:
        model = CabBooking
        fields = [
            'id', 'booking_reference', 'booking_type',
            'traveler_name', 'traveler_email', 'traveler_phone',
            'vehicle_category', 'vehicle_details',
            'pickup_location', 'drop_location', 'pickup_date', 'pickup_time',
            'days_count', 'passenger_count', 'luggage_count',
            'flight_number', 'nameboard_text', 'flight_delayed_protection',
            'total_fare', 'payment_status', 'status',
            'driver_details', 'special_notes', 'created_at'
        ]
        read_only_fields = ['id', 'booking_reference', 'status', 'created_at']

    def get_vehicle_details(self, obj):
        return {
            'name': obj.vehicle_category.name,
            'type': obj.vehicle_category.vehicle_type,
            'plate_number': obj.vehicle_plate_number,
            'image': obj.vehicle_category.hero_image,
        }

    def get_driver_details(self, obj):
        return {
            'name': obj.assigned_driver_name,
            'phone': obj.assigned_driver_phone,
            'whatsapp': obj.assigned_driver_whatsapp,
            'whatsapp_url': f"https://wa.me/{obj.assigned_driver_whatsapp.replace('+', '')}?text=Hello+{obj.assigned_driver_name}%2C+I+have+booked+your+cab+{obj.booking_reference}",
            'rating': 4.98,
            'experience_years': 12,
            'languages': ['English', 'Malayalam', 'Hindi'],
            'is_mountain_certified': True,
        }

    def create(self, validated_data):
        # Auto-generate booking reference CAB-YEAR-XXXX
        random_suffix = random.randint(1000, 9999)
        ref = f"CAB-2026-{random_suffix}"
        validated_data['booking_reference'] = ref
        return super().create(validated_data)

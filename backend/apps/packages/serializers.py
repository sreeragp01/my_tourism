from rest_framework import serializers
from .models import TourPackage, PackageInquiry

class TourPackageListSerializer(serializers.ModelSerializer):
    operator = serializers.SerializerMethodField()
    duration = serializers.SerializerMethodField()
    savings_percent = serializers.SerializerMethodField()

    class Meta:
        model = TourPackage
        fields = [
            'id', 'title', 'slug', 'category', 'tagline',
            'duration_days', 'duration_nights', 'duration',
            'start_city', 'end_city', 'destinations_covered',
            'price_per_person', 'original_price', 'savings_percent',
            'hero_image', 'rating', 'review_count', 'is_featured',
            'highlights', 'operator'
        ]

    def get_operator(self, obj):
        return {
            'name': obj.operator_name,
            'phone': obj.operator_phone,
            'whatsapp': obj.operator_whatsapp,
            'license': obj.operator_license,
            'is_verified': obj.is_operator_verified,
        }

    def get_duration(self, obj):
        return f"{obj.duration_days}D / {obj.duration_nights}N"

    def get_savings_percent(self, obj):
        if obj.original_price and obj.original_price > obj.price_per_person:
            diff = float(obj.original_price - obj.price_per_person)
            return int((diff / float(obj.original_price)) * 100)
        return 0

class TourPackageDetailSerializer(serializers.ModelSerializer):
    operator = serializers.SerializerMethodField()
    duration = serializers.SerializerMethodField()
    savings_percent = serializers.SerializerMethodField()

    class Meta:
        model = TourPackage
        fields = [
            'id', 'title', 'slug', 'category', 'tagline', 'description',
            'duration_days', 'duration_nights', 'duration',
            'start_city', 'end_city', 'destinations_covered',
            'price_per_person', 'original_price', 'savings_percent',
            'hero_image', 'gallery_images',
            'highlights', 'inclusions', 'exclusions', 'itinerary',
            'rating', 'review_count', 'is_featured', 'operator',
            'created_at'
        ]

    def get_operator(self, obj):
        return {
            'name': obj.operator_name,
            'phone': obj.operator_phone,
            'whatsapp': obj.operator_whatsapp,
            'license': obj.operator_license,
            'is_verified': obj.is_operator_verified,
        }

    def get_duration(self, obj):
        return f"{obj.duration_days}D / {obj.duration_nights}N"

    def get_savings_percent(self, obj):
        if obj.original_price and obj.original_price > obj.price_per_person:
            diff = float(obj.original_price - obj.price_per_person)
            return int((diff / float(obj.original_price)) * 100)
        return 0

class PackageInquirySerializer(serializers.ModelSerializer):
    class Meta:
        model = PackageInquiry
        fields = [
            'id', 'package', 'traveler_name', 'traveler_email',
            'traveler_phone', 'travel_date', 'guests_count',
            'message', 'channel', 'created_at'
        ]
        read_only_fields = ['id', 'package', 'created_at']

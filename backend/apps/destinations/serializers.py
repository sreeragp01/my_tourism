from rest_framework import serializers
from .models import (
    Country, Region, State, Destination, Attraction,
    TravelCircuit, TravelCircuitStop, CircuitAnalyticsEvent, CircuitPerformanceSummary
)


class CountrySerializer(serializers.ModelSerializer):
    class Meta:
        model = Country
        fields = '__all__'


class RegionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Region
        fields = '__all__'


class StateSerializer(serializers.ModelSerializer):
    region_name = serializers.CharField(source='region.name', read_only=True)

    class Meta:
        model = State
        fields = ['id', 'name', 'slug', 'region', 'region_name', 'tourism_board_name']


class AttractionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Attraction
        fields = '__all__'


class DestinationSerializer(serializers.ModelSerializer):
    attractions = AttractionSerializer(many=True, read_only=True)
    state_name = serializers.CharField(source='state.name', read_only=True)
    region_name = serializers.CharField(source='region.name', read_only=True)

    class Meta:
        model = Destination
        fields = '__all__'


class DestinationSummarySerializer(serializers.ModelSerializer):
    class Meta:
        model = Destination
        fields = ['id', 'name', 'slug', 'district', 'hero_image', 'latitude', 'longitude', 'average_stay_days', 'best_season']


class TravelCircuitStopSerializer(serializers.ModelSerializer):
    destination = DestinationSummarySerializer(read_only=True)
    destination_id = serializers.CharField(write_only=True)

    class Meta:
        model = TravelCircuitStop
        fields = [
            'id', 'circuit', 'destination', 'destination_id', 'sequence_order',
            'minimum_stay_days', 'recommended_stay_days',
            'arrival_buffer_hours', 'departure_buffer_hours',
            'preferred_transport', 'stop_highlight'
        ]


class TravelCircuitSerializer(serializers.ModelSerializer):
    region_name = serializers.CharField(source='region.name', read_only=True)
    states = StateSerializer(many=True, read_only=True)
    stops_count = serializers.IntegerField(read_only=True)

    class Meta:
        model = TravelCircuit
        fields = [
            'id', 'name', 'slug', 'region', 'region_name', 'states',
            'tagline', 'description', 'hero_image', 'gallery_images',
            'duration_min_days', 'duration_max_days',
            'recommended_seasons', 'terrain_profile', 'status',
            'metadata', 'stops_count'
        ]


class TravelCircuitDetailSerializer(serializers.ModelSerializer):
    region_name = serializers.CharField(source='region.name', read_only=True)
    states = StateSerializer(many=True, read_only=True)
    stops = TravelCircuitStopSerializer(many=True, read_only=True)

    class Meta:
        model = TravelCircuit
        fields = [
            'id', 'name', 'slug', 'region', 'region_name', 'states',
            'tagline', 'description', 'hero_image', 'gallery_images',
            'duration_min_days', 'duration_max_days',
            'recommended_seasons', 'terrain_profile', 'status',
            'metadata', 'stops'
        ]


class CircuitAnalyticsEventSerializer(serializers.ModelSerializer):
    class Meta:
        model = CircuitAnalyticsEvent
        fields = '__all__'


class CircuitPerformanceSummarySerializer(serializers.ModelSerializer):
    circuit_name = serializers.CharField(source='circuit.name', read_only=True)
    acceptance_rate_percent = serializers.FloatField(read_only=True)
    conversion_rate_percent = serializers.FloatField(read_only=True)

    class Meta:
        model = CircuitPerformanceSummary
        fields = '__all__'

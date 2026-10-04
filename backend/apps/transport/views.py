from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from decimal import Decimal

from .models import VehicleCategory, AirportTransferRoute, CabBooking
from .serializers import (
    VehicleCategorySerializer,
    AirportTransferRouteSerializer,
    CabBookingSerializer,
)

class VehicleCategoryViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = VehicleCategory.objects.filter(is_active=True)
    serializer_class = VehicleCategorySerializer
    permission_classes = [AllowAny]

class AirportTransferRouteViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = AirportTransferRoute.objects.all()
    serializer_class = AirportTransferRouteSerializer
    permission_classes = [AllowAny]

    def get_queryset(self):
        qs = super().get_queryset()
        airport = self.request.query_params.get('airport')
        if airport:
            qs = qs.filter(airport_code=airport.upper())
        return qs

class CabBookingViewSet(viewsets.ModelViewSet):
    queryset = CabBooking.objects.all()
    serializer_class = CabBookingSerializer
    permission_classes = [AllowAny]
    lookup_field = 'booking_reference'

    @action(detail=False, methods=['post'])
    def estimate_fare(self, request):
        vehicle_id = request.data.get('vehicle_id')
        distance_km = float(request.data.get('distance_km', 100))
        days = int(request.data.get('days_count', 1))
        is_airport = request.data.get('is_airport', False)
        
        try:
            vehicle = VehicleCategory.objects.get(id=vehicle_id)
        except VehicleCategory.DoesNotExist:
            vehicle = VehicleCategory.objects.first()

        if is_airport:
            # Flat airport package
            estimated_fare = vehicle.daily_rental_rate
        else:
            # Per-day disposal rate + per km
            base = vehicle.daily_rental_rate * days
            bata = vehicle.driver_bata_per_day * days
            extra_km = max(0, distance_km - (100 * days))
            extra_fare = Decimal(str(extra_km)) * vehicle.base_rate_per_km
            estimated_fare = base + bata + extra_fare

        return Response({
            'vehicle_name': vehicle.name,
            'vehicle_type': vehicle.vehicle_type,
            'estimated_fare': float(estimated_fare),
            'days_count': days,
            'distance_km': distance_km,
            'toll_included': True,
            'driver_bata_included': True,
            'mountain_permit_included': vehicle.has_mountain_permit,
        })

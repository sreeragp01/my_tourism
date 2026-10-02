from rest_framework import viewsets, permissions, status
from rest_framework.views import APIView
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from django.db.models import F

from .models import (
    Country, Region, State, Destination, Attraction,
    TravelCircuit, TravelCircuitStop, CircuitAnalyticsEvent, CircuitPerformanceSummary
)
from .serializers import (
    CountrySerializer, RegionSerializer, StateSerializer,
    DestinationSerializer, AttractionSerializer,
    TravelCircuitSerializer, TravelCircuitDetailSerializer,
    TravelCircuitStopSerializer, CircuitAnalyticsEventSerializer,
    CircuitPerformanceSummarySerializer
)
from apps.maps.services import RouteService


class CountryViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Country.objects.all()
    serializer_class = CountrySerializer
    permission_classes = [permissions.AllowAny]


class RegionViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Region.objects.all()
    serializer_class = RegionSerializer
    permission_classes = [permissions.AllowAny]
    lookup_field = 'slug'


class StateViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = State.objects.all()
    serializer_class = StateSerializer
    permission_classes = [permissions.AllowAny]
    lookup_field = 'slug'

    def get_queryset(self):
        qs = super().get_queryset()
        region = self.request.query_params.get('region')
        if region:
            qs = qs.filter(region__slug=region)
        return qs


class DestinationViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Destination.objects.all()
    serializer_class = DestinationSerializer
    permission_classes = [permissions.AllowAny]
    lookup_field = 'slug'

    def get_queryset(self):
        qs = super().get_queryset()
        state = self.request.query_params.get('state')
        region = self.request.query_params.get('region')
        tag = self.request.query_params.get('tag')
        if state:
            qs = qs.filter(state__slug=state)
        if region:
            qs = qs.filter(region__slug=region)
        if tag:
            qs = qs.filter(tags__icontains=tag)
        return qs


class AttractionViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Attraction.objects.all()
    serializer_class = AttractionSerializer
    permission_classes = [permissions.AllowAny]


class TravelCircuitViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = TravelCircuit.objects.prefetch_related('states', 'stops', 'stops__destination').all()
    permission_classes = [permissions.AllowAny]
    lookup_field = 'slug'

    def get_serializer_class(self):
        if self.action == 'retrieve':
            return TravelCircuitDetailSerializer
        return TravelCircuitSerializer

    def get_queryset(self):
        qs = super().get_queryset()
        region = self.request.query_params.get('region')
        state = self.request.query_params.get('state')
        terrain = self.request.query_params.get('terrain')
        status_filter = self.request.query_params.get('status', 'ACTIVE')

        if status_filter:
            qs = qs.filter(status=status_filter.upper())
        if region:
            qs = qs.filter(region__slug=region)
        if state:
            qs = qs.filter(states__slug=state)
        if terrain:
            qs = qs.filter(terrain_profile=terrain.upper())
        return qs


class TravelCircuitStopsView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request, slug):
        circuit = get_object_or_404(TravelCircuit, slug=slug)
        stops = list(circuit.stops.select_related('destination').order_by('sequence_order'))

        segments = []
        for i in range(len(stops) - 1):
            s_from = stops[i].destination
            s_to = stops[i + 1].destination
            route_data = RouteService.compute_route(
                start_lat=s_from.latitude,
                start_lon=s_from.longitude,
                end_lat=s_to.latitude,
                end_lon=s_to.longitude
            )
            segments.append({
                'from_stop_order': stops[i].sequence_order,
                'from_destination': s_from.name,
                'to_stop_order': stops[i + 1].sequence_order,
                'to_destination': s_to.name,
                'distance_km': route_data.get('distance_km', 0.0),
                'duration_minutes': route_data.get('duration_minutes', 0),
                'duration_hours': route_data.get('duration_hours', 0.0),
                'is_ghat_or_mountain': route_data.get('is_ghat_road', False) or route_data.get('is_mountain_road', False),
                'advisories': route_data.get('advisories', []),
            })

        stops_serializer = TravelCircuitStopSerializer(stops, many=True)
        return Response({
            'circuit': {
                'id': circuit.id,
                'name': circuit.name,
                'slug': circuit.slug,
                'duration_min_days': circuit.duration_min_days,
                'duration_max_days': circuit.duration_max_days,
            },
            'stops': stops_serializer.data,
            'segments': segments,
        })


class CircuitAnalyticsTrackView(APIView):
    """
    Workstream F13: Ingests telemetry events and updates aggregate performance summaries in real-time.
    """
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        circuit_id = request.data.get('circuit_id')
        event_type = request.data.get('event_type')
        metadata = request.data.get('metadata', {})

        if not circuit_id or not event_type:
            return Response(
                {'error': 'circuit_id and event_type are required.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        circuit = get_object_or_404(TravelCircuit, id=circuit_id)
        user = request.user if request.user.is_authenticated else None

        event = CircuitAnalyticsEvent.objects.create(
            circuit=circuit,
            event_type=event_type.upper(),
            user=user,
            metadata=metadata
        )

        # Update or create aggregate performance summary
        summary, _ = CircuitPerformanceSummary.objects.get_or_create(circuit=circuit)
        ev = event_type.upper()
        if ev == 'VIEW':
            summary.total_views = F('total_views') + 1
        elif ev == 'PLAN_GENERATED':
            summary.plans_generated = F('plans_generated') + 1
        elif ev == 'PLAN_ACCEPTED':
            summary.plans_accepted = F('plans_accepted') + 1
        elif ev == 'PLAN_REGENERATED':
            summary.regeneration_count = F('regeneration_count') + 1
        elif ev == 'BOOKING':
            summary.bookings_count = F('bookings_count') + 1
        summary.save()

        return Response(
            {'status': 'tracked', 'event_id': str(event.id)},
            status=status.HTTP_201_CREATED
        )


class CircuitPerformanceSummaryView(APIView):
    """
    Workstream F13: Returns operational performance intelligence for all circuits.
    """
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        summaries = CircuitPerformanceSummary.objects.select_related('circuit').all()
        serializer = CircuitPerformanceSummarySerializer(summaries, many=True)
        return Response({
            'circuits_count': summaries.count(),
            'performance_metrics': serializer.data
        })

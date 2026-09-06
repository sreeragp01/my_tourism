from rest_framework import viewsets, permissions, filters
from .models import Accommodation, RoomType
from .serializers import AccommodationSerializer, RoomTypeSerializer

class AccommodationViewSet(viewsets.ReadOnlyModelViewSet):
    """
    Search and retrieve Kerala boutique resorts, houseboats, and heritage homestays.
    """
    queryset = Accommodation.objects.all()
    serializer_class = AccommodationSerializer
    permission_classes = [permissions.AllowAny]
    filter_backends = [filters.SearchFilter]
    search_fields = ['name', 'description', 'destination_id', 'type']

    def get_queryset(self):
        qs = super().get_queryset()
        dest = self.request.query_params.get('destination')
        stay_type = self.request.query_params.get('type')
        min_eco = self.request.query_params.get('min_eco_score')

        if dest:
            qs = qs.filter(destination_id=dest)
        if stay_type:
            qs = qs.filter(type=stay_type.upper())
        if min_eco:
            try:
                qs = qs.filter(eco_green_score__gte=int(min_eco))
            except ValueError:
                pass
        return qs

class RoomTypeViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = RoomType.objects.all()
    serializer_class = RoomTypeSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        qs = super().get_queryset()
        acc_id = self.request.query_params.get('accommodation_id')
        if acc_id:
            qs = qs.filter(accommodation_id=acc_id)
        return qs

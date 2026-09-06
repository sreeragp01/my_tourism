from rest_framework import viewsets, permissions, filters
from .models import Experience, ExperienceSlot
from .serializers import ExperienceSerializer, ExperienceSlotSerializer

class ExperienceViewSet(viewsets.ReadOnlyModelViewSet):
    """
    List and retrieve curated Kerala experiences with category,
    destination, and weather-suitability filters.
    """
    queryset = Experience.objects.all()
    serializer_class = ExperienceSerializer
    permission_classes = [permissions.AllowAny]
    filter_backends = [filters.SearchFilter]
    search_fields = ['title', 'description', 'category', 'destination_id']

    def get_queryset(self):
        qs = super().get_queryset()
        dest = self.request.query_params.get('destination')
        cat = self.request.query_params.get('category')
        rain_only = self.request.query_params.get('rain_friendly')
        
        if dest:
            qs = qs.filter(destination_id=dest)
        if cat:
            qs = qs.filter(category=cat.upper())
        if rain_only and rain_only.lower() in ['true', '1']:
            qs = qs.filter(rain_friendly=True)
        return qs

class ExperienceSlotViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = ExperienceSlot.objects.all()
    serializer_class = ExperienceSlotSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        qs = super().get_queryset()
        exp_id = self.request.query_params.get('experience_id')
        date_val = self.request.query_params.get('date')
        if exp_id:
            qs = qs.filter(experience_id=exp_id)
        if date_val:
            qs = qs.filter(date=date_val)
        return qs

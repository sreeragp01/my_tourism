from rest_framework import serializers, viewsets, permissions
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .models import Destination, Attraction

class AttractionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Attraction
        fields = '__all__'

class DestinationSerializer(serializers.ModelSerializer):
    attractions = AttractionSerializer(many=True, read_only=True)

    class Meta:
        model = Destination
        fields = '__all__'

class DestinationViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Destination.objects.all()
    serializer_class = DestinationSerializer
    permission_classes = [permissions.AllowAny]
    lookup_field = 'slug'

class AttractionViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Attraction.objects.all()
    serializer_class = AttractionSerializer
    permission_classes = [permissions.AllowAny]

router = DefaultRouter()
router.register(r'', DestinationViewSet, basename='destination')

urlpatterns = [
    path('', include(router.urls)),
]

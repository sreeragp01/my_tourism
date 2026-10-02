from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    DestinationViewSet, AttractionViewSet,
    CountryViewSet, RegionViewSet, StateViewSet
)

router = DefaultRouter()
router.register(r'countries', CountryViewSet, basename='country')
router.register(r'regions', RegionViewSet, basename='region')
router.register(r'states', StateViewSet, basename='state')
router.register(r'attractions', AttractionViewSet, basename='attraction')
router.register(r'', DestinationViewSet, basename='destination')

urlpatterns = [
    path('', include(router.urls)),
]

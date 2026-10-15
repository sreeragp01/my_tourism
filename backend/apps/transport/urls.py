from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    VehicleCategoryViewSet,
    AirportTransferRouteViewSet,
    CabBookingViewSet,
    DriverViewSet,
)

router = DefaultRouter()
router.register(r'vehicles', VehicleCategoryViewSet, basename='transport-vehicle')
router.register(r'airport-routes', AirportTransferRouteViewSet, basename='transport-airport-route')
router.register(r'bookings', CabBookingViewSet, basename='transport-booking')
router.register(r'drivers', DriverViewSet, basename='transport-driver')

urlpatterns = [
    path('', include(router.urls)),
]

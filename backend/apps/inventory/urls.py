from django.urls import path
from .views import (
    InventoryAvailabilityView,
    InventoryHoldsView,
    HoldDetailView,
    ReleaseHoldView,
    ExtendHoldView,
    HoldItineraryView,
    ReleaseExpiredHoldsView,
)

urlpatterns = [
    # Authoritative Phase 6 Endpoints
    path('availability/', InventoryAvailabilityView.as_view(), name='inventory-availability'),
    path('holds/', InventoryHoldsView.as_view(), name='inventory-holds'),
    path('holds/itinerary/', HoldItineraryView.as_view(), name='inventory-hold-itinerary'),
    path('holds/<uuid:id>/', HoldDetailView.as_view(), name='inventory-hold-detail'),
    path('holds/<uuid:id>/release/', ReleaseHoldView.as_view(), name='inventory-hold-release'),
    path('holds/<uuid:id>/extend/', ExtendHoldView.as_view(), name='inventory-hold-extend'),

    # Backward compatibility aliases
    path('hold/', InventoryHoldsView.as_view(), name='inventory-hold'),
    path('release-expired/', ReleaseExpiredHoldsView.as_view(), name='inventory-release-expired'),
]

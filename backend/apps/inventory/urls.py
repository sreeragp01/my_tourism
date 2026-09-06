from django.urls import path
from .views import InventoryHoldView, ReleaseExpiredHoldsView

urlpatterns = [
    path('hold/', InventoryHoldView.as_view(), name='inventory-hold'),
    path('release-expired/', ReleaseExpiredHoldsView.as_view(), name='inventory-release-expired'),
]

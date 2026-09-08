from django.urls import path
from .views import (
    NotificationListView,
    NotificationPreferenceView,
    DeviceTokenRegisterView,
    ProximityCheckView
)

urlpatterns = [
    path('', NotificationListView.as_view(), name='notification-list'),
    path('preferences/', NotificationPreferenceView.as_view(), name='notification-preferences'),
    path('device-token/', DeviceTokenRegisterView.as_view(), name='device-token-register'),
    path('proximity-check/', ProximityCheckView.as_view(), name='proximity-check'),
]

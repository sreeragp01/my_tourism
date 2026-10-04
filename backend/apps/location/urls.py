from django.urls import path
from .views import LocationUpdateView, CurrentLocationView, TripLocationView

urlpatterns = [
    path('update/', LocationUpdateView.as_view(), name='location-update'),
    path('current/', CurrentLocationView.as_view(), name='location-current'),
    path('trips/<str:reference>/', TripLocationView.as_view(), name='trip-location'),
]

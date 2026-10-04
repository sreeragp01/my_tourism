from django.urls import path
from .views import UserTripsView, TripDetailView
from .context_views import TripContextView

urlpatterns = [
    path('', UserTripsView.as_view(), name='user-trips-list'),
    path('<str:reference>/', TripDetailView.as_view(), name='trip-detail'),
    path('<str:reference>/context/', TripContextView.as_view(), name='trip-context'),
]

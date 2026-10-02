from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    TravelCircuitViewSet, TravelCircuitStopsView,
    CircuitAnalyticsTrackView, CircuitPerformanceSummaryView
)

router = DefaultRouter()
router.register(r'', TravelCircuitViewSet, basename='circuit')

urlpatterns = [
    path('analytics/track/', CircuitAnalyticsTrackView.as_view(), name='circuit-analytics-track'),
    path('analytics/summary/', CircuitPerformanceSummaryView.as_view(), name='circuit-analytics-summary'),
    path('<slug:slug>/stops/', TravelCircuitStopsView.as_view(), name='circuit-stops'),
    path('', include(router.urls)),
]

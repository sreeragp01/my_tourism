from django.urls import path
from .views import (
    SafetyDirectoryView,
    TriggerSOSView,
    CreateTripShareView,
    RevokeTripShareView,
    PublicTripShareDetailView
)

urlpatterns = [
    path('directory/', SafetyDirectoryView.as_view(), name='safety-directory'),
    path('sos/', TriggerSOSView.as_view(), name='safety-sos-trigger'),
    path('share/', CreateTripShareView.as_view(), name='safety-share-create'),
    path('share/<str:token>/revoke/', RevokeTripShareView.as_view(), name='safety-share-revoke'),
    path('shared/<str:token>/', PublicTripShareDetailView.as_view(), name='safety-shared-detail'),
]

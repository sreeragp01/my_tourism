from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import OrganizationViewSet, ProviderDashboardView, AdminVerificationQueueView

router = DefaultRouter()
router.register(r'orgs', OrganizationViewSet, basename='organization')

urlpatterns = [
    path('dashboard/', ProviderDashboardView.as_view(), name='provider-dashboard'),
    path('admin/verification-queue/', AdminVerificationQueueView.as_view(), name='admin-verification-queue'),
    path('admin/providers/<uuid:pk>/verify/', AdminVerificationQueueView.as_view(), name='admin-verify-provider'),
    path('', include(router.urls)),
]

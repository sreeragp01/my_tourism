from django.urls import path
from .views import (
    ParsePromptView,
    GenerateItineraryView,
    PlanDetailView,
    PlanCustomizeView,
    PlanRegenerateView,
    PlanSubstituteRainView,
    PlanVersionsView,
    PlanVersionDetailView,
    PlanValidateView,
    SubstituteRainView,
    OptimizeRouteView,
)

urlpatterns = [
    path('parse-prompt/', ParsePromptView.as_view(), name='ai-parse-prompt'),
    path('generate-itinerary/', GenerateItineraryView.as_view(), name='ai-generate-itinerary'),
    path('plans/<uuid:id>/', PlanDetailView.as_view(), name='ai-plan-detail'),
    path('plans/<uuid:id>/customize/', PlanCustomizeView.as_view(), name='ai-plan-customize'),
    path('plans/<uuid:id>/regenerate/', PlanRegenerateView.as_view(), name='ai-plan-regenerate'),
    path('plans/<uuid:id>/substitute-rain/', PlanSubstituteRainView.as_view(), name='ai-plan-substitute-rain'),
    path('plans/<uuid:id>/versions/', PlanVersionsView.as_view(), name='ai-plan-versions'),
    path('plans/<uuid:id>/versions/<int:version>/', PlanVersionDetailView.as_view(), name='ai-plan-version-detail'),
    path('plans/<uuid:id>/validate/', PlanValidateView.as_view(), name='ai-plan-validate'),
    path('substitute-rain/', SubstituteRainView.as_view(), name='ai-substitute-rain'),
    path('optimize-route/', OptimizeRouteView.as_view(), name='ai-optimize-route'),
]

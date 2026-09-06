from django.urls import path
from .views import ParsePromptView, GenerateItineraryView, SubstituteRainView, OptimizeRouteView

urlpatterns = [
    path('parse-prompt/', ParsePromptView.as_view(), name='ai-parse-prompt'),
    path('generate-itinerary/', GenerateItineraryView.as_view(), name='ai-generate-itinerary'),
    path('substitute-rain/', SubstituteRainView.as_view(), name='ai-substitute-rain'),
    path('optimize-route/', OptimizeRouteView.as_view(), name='ai-optimize-route'),
]

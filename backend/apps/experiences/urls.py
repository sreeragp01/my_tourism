from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import ExperienceViewSet, ExperienceSlotViewSet

router = DefaultRouter()
router.register(r'slots', ExperienceSlotViewSet, basename='experience-slot')
router.register(r'', ExperienceViewSet, basename='experience')

urlpatterns = [
    path('', include(router.urls)),
]

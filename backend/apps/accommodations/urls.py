from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import AccommodationViewSet, RoomTypeViewSet

router = DefaultRouter()
router.register(r'rooms', RoomTypeViewSet, basename='room-type')
router.register(r'', AccommodationViewSet, basename='accommodation')

urlpatterns = [
    path('', include(router.urls)),
]

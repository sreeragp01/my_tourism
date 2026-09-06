from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import BookingViewSet, BookingTransitionView, DigitalPassView

router = DefaultRouter()
router.register(r'', BookingViewSet, basename='booking')

urlpatterns = [
    path('pass/<str:reference>/', DigitalPassView.as_view(), name='booking-pass'),
    path('<uuid:pk>/transition/', BookingTransitionView.as_view(), name='booking-transition'),
    path('', include(router.urls)),
]

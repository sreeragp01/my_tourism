from django.urls import path
from .views import RouteView, NearbyView, GeocodeView

urlpatterns = [
    path('route/', RouteView.as_view(), name='maps-route'),
    path('nearby/', NearbyView.as_view(), name='maps-nearby'),
    path('geocode/', GeocodeView.as_view(), name='maps-geocode'),
]

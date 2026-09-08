from django.urls import path
from .views import CurrentWeatherView, ForecastWeatherView, TripWeatherView, WeatherRiskView

urlpatterns = [
    path('current/', CurrentWeatherView.as_view(), name='weather-current'),
    path('forecast/', ForecastWeatherView.as_view(), name='weather-forecast'),
    path('trip/<str:reference>/', TripWeatherView.as_view(), name='weather-trip'),
    path('risk/', WeatherRiskView.as_view(), name='weather-risk'),
]

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions
from .services import WeatherService, MonsoonRiskEngine, TravelWeatherValidator

class CurrentWeatherView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        destination = request.query_params.get('destination', 'munnar')
        weather_data = WeatherService.get_current_weather(destination)
        return Response(weather_data, status=status.HTTP_200_OK)


class ForecastWeatherView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        destination = request.query_params.get('destination', 'munnar')
        try:
            days = int(request.query_params.get('days', 3))
        except ValueError:
            days = 3
        forecast = WeatherService.get_forecast(destination, days=days)
        return Response({"forecast": forecast, "days": len(forecast)}, status=status.HTTP_200_OK)


class TripWeatherView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, reference):
        data = WeatherService.get_trip_weather(reference)
        return Response(data, status=status.HTTP_200_OK)


class WeatherRiskView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        activity = request.query_params.get('activity_type', 'TREKKING')
        destination = request.query_params.get('destination', 'munnar')
        try:
            rain_prob = int(request.query_params.get('rain_probability', 70))
        except ValueError:
            rain_prob = 70

        validation = TravelWeatherValidator.validate_activity(
            activity_type=activity,
            destination_slug=destination,
            rain_probability=rain_prob
        )
        risk = MonsoonRiskEngine.evaluate_risk(destination, rain_prob)
        return Response({
            "activity_validation": validation,
            "regional_risk": risk
        }, status=status.HTTP_200_OK)

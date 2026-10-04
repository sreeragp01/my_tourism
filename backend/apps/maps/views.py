from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions
from .services import RouteService, NearbyService, GeocodingService

class RouteView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        try:
            start_lat = float(request.query_params.get('start_lat', 9.9312))
            start_lon = float(request.query_params.get('start_lon', 76.2673))
            end_lat = float(request.query_params.get('end_lat', 10.0889))
            end_lon = float(request.query_params.get('end_lon', 77.0595))
        except (TypeError, ValueError):
            return Response({"error": "Invalid coordinates provided"}, status=status.HTTP_400_BAD_REQUEST)

        route_data = RouteService.compute_route(start_lat, start_lon, end_lat, end_lon)
        return Response(route_data, status=status.HTTP_200_OK)


class NearbyView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        try:
            lat = float(request.query_params.get('lat', 10.0889))
            lon = float(request.query_params.get('lon', 77.0595))
            radius_km = float(request.query_params.get('radius_km', 35.0))
        except (TypeError, ValueError):
            return Response({"error": "Invalid lat/lon/radius_km"}, status=status.HTTP_400_BAD_REQUEST)

        category = request.query_params.get('category')
        results = NearbyService.find_nearby(lat, lon, radius_km=radius_km, category=category)
        return Response({"results": results, "count": len(results)}, status=status.HTTP_200_OK)


class GeocodeView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        try:
            lat = float(request.query_params.get('lat', 9.9656))
            lon = float(request.query_params.get('lon', 76.2421))
        except (TypeError, ValueError):
            return Response({"error": "Invalid lat/lon"}, status=status.HTTP_400_BAD_REQUEST)

        name = GeocodingService.reverse_geocode(lat, lon)
        return Response({
            "latitude": lat,
            "longitude": lon,
            "landmark": name,
        }, status=status.HTTP_200_OK)

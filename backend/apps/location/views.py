from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions
from django.core.exceptions import PermissionDenied
from .serializers import LocationUpdateSerializer, TravelerLocationSerializer
from .services import LocationService

class LocationUpdateView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = LocationUpdateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        try:
            loc = LocationService.record_location(
                user=request.user,
                latitude=data['latitude'],
                longitude=data['longitude'],
                accuracy=data.get('accuracy', 10.0),
                speed=data.get('speed'),
                heading=data.get('heading'),
                booking_reference=data.get('booking_reference')
            )
            return Response(TravelerLocationSerializer(loc).data, status=status.HTTP_201_CREATED)
        except PermissionDenied as e:
            return Response({"error": str(e)}, status=status.HTTP_403_FORBIDDEN)


class CurrentLocationView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        loc = LocationService.get_latest_location(user=request.user)
        if not loc:
            # Fallback to Fort Kochi coordinate if no location recorded yet
            return Response({
                "latitude": 9.9656,
                "longitude": 76.2421,
                "accuracy": 20.0,
                "is_fallback": True,
                "landmark": "Fort Kochi Heritage Zone"
            }, status=status.HTTP_200_OK)
        return Response(TravelerLocationSerializer(loc).data, status=status.HTTP_200_OK)


class TripLocationView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, reference):
        try:
            locations = LocationService.get_trip_locations(request.user, reference)
            latest = locations[0] if locations else None
            return Response({
                "booking_reference": reference,
                "latest": TravelerLocationSerializer(latest).data if latest else None,
                "history_count": len(locations),
                "history": TravelerLocationSerializer(locations, many=True).data
            }, status=status.HTTP_200_OK)
        except PermissionDenied as e:
            return Response({"error": str(e)}, status=status.HTTP_403_FORBIDDEN)

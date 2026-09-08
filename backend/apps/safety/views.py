from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions
from .services import SafetyService
from .serializers import (
    SafetyAlertSerializer,
    TriggerSOSRequestSerializer,
    CreateTripShareRequestSerializer,
    TripShareTokenSerializer
)


class SafetyDirectoryView(APIView):
    """Publicly accessible verified emergency directory and hospital contact numbers."""
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        data = SafetyService.get_safety_directory()
        return Response(data, status=status.HTTP_200_OK)


class TriggerSOSView(APIView):
    """
    Emergency SOS endpoint. Dispatches immediate tourist police / 112 event.
    Decoupled from AI and zero external latency.
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = TriggerSOSRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        result = SafetyService.trigger_sos(
            user=request.user,
            booking_reference=data.get('booking_reference'),
            latitude=data.get('latitude'),
            longitude=data.get('longitude'),
            location_name=data.get('location_name', ''),
            alert_type=data.get('alert_type', 'SOS_112'),
            notes=data.get('notes', '')
        )
        return Response(result, status=status.HTTP_201_CREATED)


class CreateTripShareView(APIView):
    """Generates a secure temporary link for live trip sharing with family/friends."""
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = CreateTripShareRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        try:
            result = SafetyService.generate_share_token(
                user=request.user,
                booking_reference=data['booking_reference'],
                expiry_hours=data.get('expiry_hours', 24)
            )
            return Response(result, status=status.HTTP_201_CREATED)
        except PermissionError as pe:
            return Response({'error': str(pe)}, status=status.HTTP_403_FORBIDDEN)
        except ValueError as ve:
            return Response({'error': str(ve)}, status=status.HTTP_404_NOT_FOUND)


class RevokeTripShareView(APIView):
    """Revokes a previously issued trip share link immediately."""
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, token):
        try:
            result = SafetyService.revoke_share_token(request.user, token)
            return Response(result, status=status.HTTP_200_OK)
        except PermissionError as pe:
            return Response({'error': str(pe)}, status=status.HTTP_403_FORBIDDEN)
        except ValueError as ve:
            return Response({'error': str(ve)}, status=status.HTTP_404_NOT_FOUND)


class PublicTripShareDetailView(APIView):
    """Public read-only endpoint for family/friends to track trip progress without accessing PII."""
    permission_classes = [permissions.AllowAny]

    def get(self, request, token):
        data = SafetyService.get_public_trip_share_data(token)
        if not data.get('valid', True):
            return Response(data, status=status.HTTP_404_NOT_FOUND)
        return Response(data, status=status.HTTP_200_OK)

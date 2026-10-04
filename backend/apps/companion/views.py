from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions
from .serializers import CompanionMessageRequestSerializer
from .services import AICompanionOrchestrator

class LiveTripCompanionChatView(APIView):
    """
    Live Trip Companion chat endpoint backed by an explicit Tool/Action architecture:
    Traveler -> Intent Detection -> Tool Permission -> Authoritative Tool -> Validated AI Result
    """
    permission_classes = [permissions.IsAuthenticated]
    throttle_scope = 'ai_companion'

    def post(self, request):
        serializer = CompanionMessageRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        user = request.user
        destination_slug = data.get('destination_slug') or data.get('current_destination') or 'munnar'
        response_payload = AICompanionOrchestrator.process_query(
            query=data['query'],
            destination_slug=destination_slug,
            trip_day=data.get('trip_day', 2),
            booking_reference=data.get('booking_reference'),
            user=user
        )

        return Response(response_payload, status=status.HTTP_200_OK)

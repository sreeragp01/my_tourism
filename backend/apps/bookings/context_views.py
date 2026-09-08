from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions
from .context_service import TripContextService


class TripContextView(APIView):
    """
    Authoritative single trip context endpoint for Live Trip Experience Engine.
    Aggregates booking state, live GPS location, meteorological risk, 
    upcoming milestone events, assigned chauffeur status, and emergency directory.
    """
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, reference):
        try:
            context = TripContextService.get_trip_context(reference, user=request.user)
            return Response(context, status=status.HTTP_200_OK)
        except ValueError as ve:
            return Response({'error': str(ve)}, status=status.HTTP_404_NOT_FOUND)
        except PermissionError as pe:
            return Response({'error': str(pe)}, status=status.HTTP_403_FORBIDDEN)

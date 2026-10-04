from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions
from .serializers import SearchQuerySerializer
from .services import UnifiedSearchService


class SearchAPIView(APIView):
    """
    Unified Discovery & Search API for KeraLink.
    Allows travelers to search across Kerala destinations, curated experiences,
    heritage stays, and attractions with multi-faceted filtering, geo-coordinates, and pagination.
    """
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        serializer = SearchQuerySerializer(data=request.query_params)
        serializer.is_valid(raise_exception=True)
        
        service = UnifiedSearchService()
        result = service.search(serializer.validated_data)
        
        return Response(result, status=status.HTTP_200_OK)

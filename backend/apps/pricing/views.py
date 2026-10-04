from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions
from .serializers import PriceCalculateRequestSerializer
from .services import AuthoritativePricingEngine

class CalculatePriceView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = PriceCalculateRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        price_breakdown = AuthoritativePricingEngine.calculate_itinerary_price(
            days_count=data['days_count'],
            travelers_count=data['travelers_count'],
            stays=data.get('stays', []),
            experiences=data.get('experiences', []),
            transport_mode=data.get('transport_mode', 'SEDAN'),
            promo_code=data.get('promo_code')
        )
        return Response(price_breakdown, status=status.HTTP_200_OK)

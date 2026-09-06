from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions
from .serializers import CreateHoldRequestSerializer, InventoryHoldSerializer
from .services import InventoryService, InsufficientInventoryError
from .models import InventoryHold

class InventoryHoldView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = CreateHoldRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        try:
            if data['inventory_type'] == 'ROOM':
                dates = data.get('dates', [])
                holds = InventoryService.hold_room_inventory(
                    booking_id=data['booking_id'],
                    room_type_id=data['inventory_id'],
                    dates=dates,
                    quantity=data['quantity']
                )
                return Response(InventoryHoldSerializer(holds, many=True).data, status=status.HTTP_201_CREATED)
            else:
                hold = InventoryService.hold_experience_slot(
                    booking_id=data['booking_id'],
                    slot_id=data['inventory_id'],
                    quantity=data['quantity']
                )
                return Response(InventoryHoldSerializer(hold).data, status=status.HTTP_201_CREATED)
        except InsufficientInventoryError as e:
            return Response({"error": str(e), "code": "INSUFFICIENT_INVENTORY"}, status=status.HTTP_409_CONFLICT)

class ReleaseExpiredHoldsView(APIView):
    permission_classes = [permissions.IsAdminUser]

    def post(self, request):
        InventoryService.release_expired_holds()
        return Response({"status": "expired_holds_released"}, status=status.HTTP_200_OK)

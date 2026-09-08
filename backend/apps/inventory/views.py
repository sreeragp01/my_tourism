from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions
from .serializers import (
    AvailabilityQuerySerializer,
    CreateHoldRequestSerializer,
    BatchItineraryHoldRequestSerializer,
    ExtendHoldRequestSerializer,
    InventoryHoldSerializer,
)
from .services import (
    InventoryService,
    InsufficientInventoryError,
    InventoryNotFoundError,
    HoldNotFoundError,
    HoldExpiredError,
)


class InventoryAvailabilityView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        serializer = AvailabilityQuerySerializer(data=request.query_params)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        try:
            availability = InventoryService.check_availability(
                inventory_type=data['inventory_type'],
                inventory_id=data['inventory_id'],
                date=data.get('date'),
                quantity=data.get('quantity', 1),
            )
            return Response(availability, status=status.HTTP_200_OK)
        except InventoryNotFoundError as e:
            return Response({"error": str(e), "code": "INVENTORY_NOT_FOUND"}, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)


class InventoryHoldsView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = CreateHoldRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        user = request.user if request.user and request.user.is_authenticated else None

        try:
            inv_type = data['inventory_type'].upper()
            dates = data.get('dates') or ([data.get('date')] if data.get('date') else None)

            if inv_type == 'ROOM' and dates and len(dates) > 1:
                holds = []
                for d in dates:
                    hold = InventoryService.create_hold(
                        user=user,
                        inventory_type='ROOM',
                        inventory_id=data['inventory_id'],
                        date=d,
                        quantity=data['quantity'],
                        itinerary_version_id=data.get('itinerary_version_id'),
                        booking_id=data.get('booking_id'),
                        duration_mins=data.get('duration_mins', 15),
                    )
                    holds.append(hold)
                return Response(InventoryHoldSerializer(holds, many=True).data, status=status.HTTP_201_CREATED)
            else:
                hold = InventoryService.create_hold(
                    user=user,
                    inventory_type=inv_type,
                    inventory_id=data['inventory_id'],
                    date=data.get('date') or (dates[0] if dates else None),
                    quantity=data['quantity'],
                    itinerary_version_id=data.get('itinerary_version_id'),
                    booking_id=data.get('booking_id'),
                    duration_mins=data.get('duration_mins', 15),
                )
                return Response(InventoryHoldSerializer(hold).data, status=status.HTTP_201_CREATED)

        except InsufficientInventoryError as e:
            return Response(
                {"error": str(e), "code": "INSUFFICIENT_INVENTORY", "details": e.details},
                status=status.HTTP_409_CONFLICT,
            )
        except InventoryNotFoundError as e:
            return Response({"error": str(e), "code": "INVENTORY_NOT_FOUND"}, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)


class HoldDetailView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request, id):
        user = request.user if request.user and request.user.is_authenticated else None
        try:
            hold = InventoryService.get_hold(id, user=user)
            return Response(InventoryHoldSerializer(hold).data, status=status.HTTP_200_OK)
        except HoldNotFoundError:
            return Response({"error": "Inventory hold not found"}, status=status.HTTP_404_NOT_FOUND)
        except PermissionError as e:
            return Response({"error": str(e)}, status=status.HTTP_403_FORBIDDEN)


class ReleaseHoldView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request, id):
        user = request.user if request.user and request.user.is_authenticated else None
        try:
            hold = InventoryService.release_hold(id, user=user)
            return Response(InventoryHoldSerializer(hold).data, status=status.HTTP_200_OK)
        except HoldNotFoundError:
            return Response({"error": "Inventory hold not found"}, status=status.HTTP_404_NOT_FOUND)
        except PermissionError as e:
            return Response({"error": str(e)}, status=status.HTTP_403_FORBIDDEN)


class ExtendHoldView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request, id):
        serializer = ExtendHoldRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        extra_minutes = serializer.validated_data.get('extra_minutes', 10)

        user = request.user if request.user and request.user.is_authenticated else None
        try:
            hold = InventoryService.extend_hold(id, user=user, extra_minutes=extra_minutes)
            return Response(InventoryHoldSerializer(hold).data, status=status.HTTP_200_OK)
        except HoldNotFoundError:
            return Response({"error": "Inventory hold not found"}, status=status.HTTP_404_NOT_FOUND)
        except HoldExpiredError as e:
            return Response({"error": str(e), "code": "HOLD_EXPIRED"}, status=status.HTTP_410_GONE)
        except PermissionError as e:
            return Response({"error": str(e)}, status=status.HTTP_403_FORBIDDEN)
        except ValueError as e:
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)


class HoldItineraryView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = BatchItineraryHoldRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        user = request.user if request.user and request.user.is_authenticated else None

        try:
            holds = InventoryService.hold_itinerary(
                user=user,
                components=data['items'],
                itinerary_version_id=data.get('itinerary_version_id'),
                booking_id=data.get('booking_id'),
                duration_mins=data.get('duration_mins', 15),
            )
            return Response(
                {
                    "holds": InventoryHoldSerializer(holds, many=True).data,
                    "total_held": len(holds),
                    "status": "ALL_HELD",
                },
                status=status.HTTP_201_CREATED,
            )
        except InsufficientInventoryError as e:
            return Response(
                {
                    "error": str(e),
                    "code": "INSUFFICIENT_INVENTORY",
                    "details": e.details,
                    "status": "HOLD_FAILED_ROLLED_BACK",
                },
                status=status.HTTP_409_CONFLICT,
            )
        except InventoryNotFoundError as e:
            return Response({"error": str(e), "code": "INVENTORY_NOT_FOUND"}, status=status.HTTP_404_NOT_FOUND)


class ReleaseExpiredHoldsView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        count = InventoryService.release_expired_holds()
        return Response({"status": "expired_holds_released", "released_count": count}, status=status.HTTP_200_OK)

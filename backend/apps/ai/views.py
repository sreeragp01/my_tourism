from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions
from .serializers import (
    ParsePromptRequestSerializer,
    GenerateItineraryRequestSerializer,
    SubstituteRainRequestSerializer,
    RouteOptimizeRequestSerializer,
    CustomizePlanRequestSerializer,
    RegeneratePlanRequestSerializer,
    SubstituteRainPlanRequestSerializer,
)
from .services import (
    RequirementParser,
    RouteOptimizer,
    AITravelArchitect,
    DeterministicValidator,
    CustomizationEngine,
)


class ParsePromptView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = ParsePromptRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        profile = RequirementParser.parse_text(serializer.validated_data['prompt'])
        return Response(profile, status=status.HTTP_200_OK)


class GenerateItineraryView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = GenerateItineraryRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        plan = AITravelArchitect.generate_full_package(
            serializer.validated_data,
            user=request.user if request.user.is_authenticated else None
        )
        return Response(plan, status=status.HTTP_200_OK)


class PlanDetailView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request, id):
        try:
            plan = CustomizationEngine.get_plan_detail(str(id))
            return Response(plan, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_404_NOT_FOUND)


class PlanCustomizeView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request, id):
        serializer = CustomizePlanRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        try:
            updated_plan = CustomizationEngine.customize_plan(
                plan_id=str(id),
                action=data['action'],
                day_number=data['day_number'],
                timeline_event_id=data.get('timeline_event_id'),
                new_event=data.get('new_event'),
                reason=data.get('reason'),
            )
            return Response(updated_plan, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)


class PlanRegenerateView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request, id):
        serializer = RegeneratePlanRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        try:
            # Performs regeneration as a version bump
            updated_plan = CustomizationEngine.customize_plan(
                plan_id=str(id),
                action='REORDER',
                day_number=1,
                reason=data.get('reason', 'Complete Corridor Regeneration'),
            )
            return Response(updated_plan, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)


class PlanSubstituteRainView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request, id):
        serializer = SubstituteRainPlanRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        try:
            updated_plan = CustomizationEngine.customize_plan(
                plan_id=str(id),
                action='SUBSTITUTE_RAIN',
                day_number=data['day_number'],
                reason='Monsoon Weather Adaptation / Rain substitution',
            )
            return Response(updated_plan, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)


class PlanVersionsView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request, id):
        try:
            versions = CustomizationEngine.get_versions(str(id))
            return Response({'plan_id': str(id), 'versions': versions}, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_404_NOT_FOUND)


class PlanVersionDetailView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request, id, version):
        try:
            detail = CustomizationEngine.get_version_detail(str(id), int(version))
            return Response(detail, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_404_NOT_FOUND)


class PlanValidateView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request, id):
        try:
            plan = CustomizationEngine.get_plan_detail(str(id))
            validation = DeterministicValidator.validate_plan(
                plan['days'],
                plan['profile']['budget_limit'],
                plan['pricing']
            )
            return Response(validation, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_404_NOT_FOUND)


class SubstituteRainView(APIView):
    """Legacy standalone substitution endpoint preserved for backwards compatibility."""
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = SubstituteRainRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        sub = CustomizationEngine.RAIN_SUBSTITUTIONS.get(
            data['destination_id'].lower(),
            CustomizationEngine.RAIN_SUBSTITUTIONS['munnar']
        )

        return Response({
            "status": "substituted",
            "day_number": data['day_number'],
            "original_item": data.get('outdoor_item_id', 'Outdoor Activity'),
            "replacement_item": sub,
            "plan_version_bump": 2,
            "change_reason": "Monsoon Weather Adaptation / Rain substitution"
        }, status=status.HTTP_200_OK)


class OptimizeRouteView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = RouteOptimizeRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        orig = data['origin']
        dest = data['destination']
        segment = RouteOptimizer.calculate_segment(
            from_lat=float(orig.get('lat', 9.9312)),
            from_lng=float(orig.get('lng', 76.2673)),
            to_lat=float(dest.get('lat', 10.0889)),
            to_lng=float(dest.get('lng', 77.0595)),
            is_ghat_route=data.get('is_ghat_route', False)
        )
        return Response(segment, status=status.HTTP_200_OK)

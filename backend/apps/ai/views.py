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
    RevertPlanRequestSerializer,
    CandidateSearchRequestSerializer,
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
            plan = CustomizationEngine.get_plan_detail(str(id), user=request.user)
            return Response(plan, status=status.HTTP_200_OK)
        except PermissionError as e:
            return Response({'error': str(e)}, status=status.HTTP_403_FORBIDDEN)
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
                action=data.get('action'),
                operation=data.get('operation'),
                day_number=data['day_number'],
                event_id=data.get('event_id'),
                timeline_event_id=data.get('timeline_event_id'),
                target_day=data.get('target_day'),
                target_day_number=data.get('target_day_number'),
                target_order=data.get('target_order'),
                swap_with_event_id=data.get('swap_with_event_id'),
                new_event=data.get('new_event'),
                entity_type=data.get('entity_type'),
                entity_id=data.get('entity_id'),
                reason=data.get('reason'),
                user=request.user,
            )
            return Response(updated_plan, status=status.HTTP_200_OK)
        except PermissionError as e:
            return Response({'error': str(e)}, status=status.HTTP_403_FORBIDDEN)
        except ValueError as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)


class PlanDiffView(APIView):
    """
    Phase 5.5: Returns deterministic diff between two itinerary versions.
    """
    permission_classes = [permissions.AllowAny]

    def get(self, request, id):
        try:
            from_ver = request.query_params.get('from_version')
            to_ver = request.query_params.get('to_version')
            plan_detail = CustomizationEngine.get_plan_detail(str(id), user=request.user)
            current_v = plan_detail['current_version']
            parent_v = plan_detail.get('parent_version') or (current_v - 1 if current_v > 1 else 1)

            f_v = int(from_ver) if from_ver else parent_v
            t_v = int(to_ver) if to_ver else current_v

            diff = CustomizationEngine.get_diff(str(id), from_version=f_v, to_version=t_v, user=request.user)
            return Response(diff, status=status.HTTP_200_OK)
        except PermissionError as e:
            return Response({'error': str(e)}, status=status.HTTP_403_FORBIDDEN)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)


class PlanRevertView(APIView):
    """
    Phase 5.4: Version Rollback by creating a new version cloning the target version state.
    """
    permission_classes = [permissions.AllowAny]

    def post(self, request, id):
        serializer = RevertPlanRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        try:
            reverted = CustomizationEngine.revert_plan(
                plan_id=str(id),
                target_version=data['target_version'],
                reason=data.get('reason'),
                user=request.user,
            )
            return Response(reverted, status=status.HTTP_200_OK)
        except PermissionError as e:
            return Response({'error': str(e)}, status=status.HTTP_403_FORBIDDEN)
        except ValueError as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)


class PlanCandidatesView(APIView):
    """
    Phase 5.7: Provides real database candidates for adding or swapping activities.
    """
    permission_classes = [permissions.AllowAny]

    def get(self, request, id):
        try:
            day_num = int(request.query_params.get('day_number', 1))
            entity_type = request.query_params.get('entity_type')
            rain_only = request.query_params.get('rain_friendly', '').lower() in ('true', '1')
            candidates = CustomizationEngine.get_candidates(
                plan_id=str(id),
                day_number=day_num,
                entity_type=entity_type,
                rain_friendly_only=rain_only,
                user=request.user,
            )
            return Response({'plan_id': str(id), 'day_number': day_num, 'candidates': candidates}, status=status.HTTP_200_OK)
        except PermissionError as e:
            return Response({'error': str(e)}, status=status.HTTP_403_FORBIDDEN)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)


class PlanRegenerateView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request, id):
        serializer = RegeneratePlanRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        try:
            updated_plan = CustomizationEngine.customize_plan(
                plan_id=str(id),
                action='REORDER',
                day_number=1,
                reason=data.get('reason', 'Complete Corridor Regeneration'),
                user=request.user,
            )
            return Response(updated_plan, status=status.HTTP_200_OK)
        except PermissionError as e:
            return Response({'error': str(e)}, status=status.HTTP_403_FORBIDDEN)
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
                operation='RAIN_SUBSTITUTE',
                day_number=data['day_number'],
                reason='Monsoon Weather Adaptation / Rain substitution',
                user=request.user,
            )
            return Response(updated_plan, status=status.HTTP_200_OK)
        except PermissionError as e:
            return Response({'error': str(e)}, status=status.HTTP_403_FORBIDDEN)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)


class PlanVersionsView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request, id):
        try:
            versions = CustomizationEngine.get_versions(str(id), user=request.user)
            return Response({'plan_id': str(id), 'versions': versions}, status=status.HTTP_200_OK)
        except PermissionError as e:
            return Response({'error': str(e)}, status=status.HTTP_403_FORBIDDEN)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_404_NOT_FOUND)


class PlanVersionDetailView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request, id, version):
        try:
            detail = CustomizationEngine.get_version_detail(str(id), int(version), user=request.user)
            return Response(detail, status=status.HTTP_200_OK)
        except PermissionError as e:
            return Response({'error': str(e)}, status=status.HTTP_403_FORBIDDEN)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_404_NOT_FOUND)


class PlanValidateView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request, id):
        try:
            plan = CustomizationEngine.get_plan_detail(str(id), user=request.user)
            validation = DeterministicValidator.validate_plan(
                plan['days'],
                plan['profile']['budget_limit'],
                plan['pricing'],
                monsoon_mode=plan.get('monsoon_mode', False)
            )
            return Response(validation, status=status.HTTP_200_OK)
        except PermissionError as e:
            return Response({'error': str(e)}, status=status.HTTP_403_FORBIDDEN)
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

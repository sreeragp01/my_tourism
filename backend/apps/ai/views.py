from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions
from .serializers import (
    ParsePromptRequestSerializer,
    GenerateItineraryRequestSerializer,
    SubstituteRainRequestSerializer,
    RouteOptimizeRequestSerializer
)
from .services import RequirementParser, RouteOptimizer, AITravelArchitect, DeterministicValidator

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
        plan = AITravelArchitect.generate_full_package(serializer.validated_data)
        return Response(plan, status=status.HTTP_200_OK)

class SubstituteRainView(APIView):
    """
    Substitutes outdoor rain-vulnerable activities with indoor cultural/culinary alternatives.
    """
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = SubstituteRainRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        substitutions = {
            "munnar": {
                "original": "Munnar Mountain Jeep Safari & Top Station Trek",
                "replacement": {
                    "id": "exp_munnar_tea_tasting_indoor",
                    "title": "Private Connoisseur Tea Tasting & Factory Experience",
                    "category": "CULTURE",
                    "price_per_person": 850,
                    "duration_hours": 2.5,
                    "rain_friendly": True,
                    "explanation": "Substituted outdoor jeep safari due to high mountain fog and heavy Ghat downpours. Indoor plantation masterclass ensures zero rain disruption."
                }
            },
            "alappuzha": {
                "original": "Open Kayaking through Village Canals",
                "replacement": {
                    "id": "exp_alleppey_culinary_shack",
                    "title": "Covered Backwater Shappu Culinary Masterclass with Chef",
                    "category": "FOOD",
                    "price_per_person": 1200,
                    "duration_hours": 3.0,
                    "rain_friendly": True,
                    "explanation": "Substituted open kayak tour with traditional rain-sheltered backwater culinary experience overlooking the scenic waterways."
                }
            }
        }

        dest_sub = substitutions.get(data['destination_id'], substitutions['munnar'])

        return Response({
            "status": "substituted",
            "day_number": data['day_number'],
            "original_item": dest_sub["original"],
            "replacement_item": dest_sub["replacement"],
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

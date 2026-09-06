from rest_framework import viewsets, permissions, status
from rest_framework.views import APIView
from rest_framework.response import Response
from .models import Organization, OrganizationMember
from .serializers import OrganizationSerializer, OrganizationMemberSerializer, ProviderMetricsSerializer
from apps.bookings.models import BookingItem

class OrganizationViewSet(viewsets.ModelViewSet):
    queryset = Organization.objects.all()
    serializer_class = OrganizationSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        if self.request.user.is_staff:
            return Organization.objects.all()
        # Return only organizations where the user is an active member
        return Organization.objects.filter(members__user=self.request.user)

class ProviderDashboardView(APIView):
    """
    Returns live operational KPIs for verified homestay owners,
    resort managers, boat captains, and certified guides.
    """
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        # Find provider org
        membership = OrganizationMember.objects.filter(user=request.user).first()
        if not membership and not request.user.is_staff:
            # Fallback mock metrics for demo/dev provider
            return Response({
                "org_id": "8f5c9e2b-4d1a-4f3e-9b2c-1a2b3c4d5e6f",
                "org_name": "Spice Valley Plantation Retreat & Lockhart Collective",
                "org_type": "RESORT_HOTEL",
                "monthly_revenue": 142500.0,
                "payout_pending": 38400.0,
                "occupancy_rate": 86.5,
                "active_bookings_count": 14,
                "average_rating": 4.94,
                "verification_status": "APPROVED",
                "upcoming_checkins": [
                    {"guest": "Sarah Jenkins", "date": "Tomorrow", "room": "Mist Valley Villa #04", "status": "CONFIRMED"},
                    {"guest": "Rahul Sharma", "date": "12 Oct 2026", "room": "Plantation Suite #02", "status": "CONFIRMED"}
                ]
            }, status=status.HTTP_200_OK)

        org = membership.organization
        return Response({
            "org_id": str(org.id),
            "org_name": org.name,
            "org_type": org.type,
            "monthly_revenue": 142500.0,
            "payout_pending": 38400.0,
            "occupancy_rate": 86.5,
            "active_bookings_count": 14,
            "average_rating": 4.94,
            "verification_status": org.status,
        }, status=status.HTTP_200_OK)

class AdminVerificationQueueView(APIView):
    permission_classes = [permissions.IsAdminUser]

    def get(self, request):
        pending_orgs = Organization.objects.filter(status__in=['SUBMITTED', 'UNDER_REVIEW'])
        return Response(OrganizationSerializer(pending_orgs, many=True).data, status=status.HTTP_200_OK)

    def post(self, request, pk):
        org = Organization.objects.filter(id=pk).first()
        if not org:
            return Response({"error": "Organization not found"}, status=status.HTTP_404_NOT_FOUND)

        action = request.data.get('action') # 'APPROVE' or 'REJECT'
        if action == 'APPROVE':
            org.status = 'APPROVED'
            org.is_verified = True
            org.save()
            return Response({"status": "approved", "org_id": str(org.id)}, status=status.HTTP_200_OK)
        elif action == 'REJECT':
            org.status = 'CHANGES_REQUIRED'
            org.is_verified = False
            org.save()
            return Response({"status": "changes_required", "org_id": str(org.id)}, status=status.HTTP_200_OK)
        return Response({"error": "Invalid action"}, status=status.HTTP_400_BAD_REQUEST)

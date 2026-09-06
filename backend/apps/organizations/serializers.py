from rest_framework import serializers
from .models import Organization, OrganizationMember

class OrganizationMemberSerializer(serializers.ModelSerializer):
    user_email = serializers.CharField(source='user.email', read_only=True)
    user_name = serializers.CharField(source='user.get_full_name', read_only=True)

    class Meta:
        model = OrganizationMember
        fields = ['id', 'user', 'user_email', 'user_name', 'role', 'permissions', 'created_at']

class OrganizationSerializer(serializers.ModelSerializer):
    members = OrganizationMemberSerializer(many=True, read_only=True)

    class Meta:
        model = Organization
        fields = '__all__'

class ProviderMetricsSerializer(serializers.Serializer):
    org_id = serializers.UUIDField()
    org_name = serializers.CharField()
    org_type = serializers.CharField()
    monthly_revenue = serializers.DecimalField(max_digits=12, decimal_places=2)
    payout_pending = serializers.DecimalField(max_digits=12, decimal_places=2)
    occupancy_rate = serializers.FloatField()
    active_bookings_count = serializers.IntegerField()
    average_rating = serializers.FloatField()
    verification_status = serializers.CharField()

from rest_framework import serializers
from .models import AuditLog

class AuditLogSerializer(serializers.ModelSerializer):
    actor_email = serializers.CharField(source='actor.email', read_only=True)

    class Meta:
        model = AuditLog
        fields = ['id', 'actor', 'actor_email', 'actor_role', 'action', 'resource_type', 'resource_id', 'ip_address', 'timestamp']

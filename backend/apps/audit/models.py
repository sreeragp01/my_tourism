import uuid
from django.db import models
from django.conf import settings

class AuditLog(models.Model):
    """
    Immutable audit trail for security, financial transactions,
    provider verifications, and price modifications.
    Answers: 'What happened and who did it?'
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    actor = models.ForeignKey(settings.AUTH_USER_MODEL, null=True, blank=True, on_delete=models.SET_NULL)
    actor_role = models.CharField(max_length=50)
    action = models.CharField(max_length=100, db_index=True) # AUTH_LOGIN, PRICE_CHANGE, PROVIDER_VERIFIED
    resource_type = models.CharField(max_length=100)
    resource_id = models.CharField(max_length=128)
    before_state = models.JSONField(null=True, blank=True)
    after_state = models.JSONField(null=True, blank=True)
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.TextField(blank=True, null=True)
    timestamp = models.DateTimeField(auto_now_add=True, db_index=True)

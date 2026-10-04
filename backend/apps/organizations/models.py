import uuid
from django.db import models
from django.conf import settings

class Organization(models.Model):
    STATUS_CHOICES = [
        ('DRAFT', 'Draft'),
        ('SUBMITTED', 'Submitted'),
        ('UNDER_REVIEW', 'Under Review'),
        ('CHANGES_REQUIRED', 'Changes Required'),
        ('APPROVED', 'Approved'),
        ('SUSPENDED', 'Suspended'),
    ]

    TYPE_CHOICES = [
        ('RESORT_HOTEL', 'Resort / Hotel'),
        ('HOMESTAY', 'Heritage Homestay'),
        ('TOUR_OPERATOR', 'Tour Operator'),
        ('GUIDE_COLLECTIVE', 'Guide Collective'),
        ('TRANSPORT_UNION', 'Transport Union'),
        ('EXPERIENCE_HOST', 'Experience Host'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=255)
    slug = models.SlugField(unique=True)
    type = models.CharField(max_length=50, choices=TYPE_CHOICES)
    status = models.CharField(max_length=50, choices=STATUS_CHOICES, default='DRAFT')
    district = models.CharField(max_length=100)
    contact_email = models.EmailField()
    contact_phone = models.CharField(max_length=20)
    is_verified = models.BooleanField(default=False)
    verification_documents = models.JSONField(default=list)
    created_at = models.DateTimeField(auto_now_add=True)

class OrganizationMember(models.Model):
    ROLE_CHOICES = [
        ('OWNER', 'Owner'),
        ('MANAGER', 'Manager'),
        ('STAFF', 'Staff'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    organization = models.ForeignKey(Organization, on_delete=models.CASCADE, related_name='members')
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='organization_memberships')
    role = models.CharField(max_length=20, choices=ROLE_CHOICES)
    permissions = models.JSONField(default=list)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('organization', 'user')

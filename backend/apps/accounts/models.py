import uuid
import hashlib
from django.db import models
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.utils import timezone

class UserManager(BaseUserManager):
    def create_user(self, email, password=None, **extra_fields):
        if not email:
            raise ValueError("Email address is required")
        email = self.normalize_email(email)
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        return self.create_user(email, password, **extra_fields)

class User(AbstractBaseUser, PermissionsMixin):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    email = models.EmailField(unique=True, db_index=True)
    phone = models.CharField(max_length=20, blank=True, null=True, db_index=True)
    first_name = models.CharField(max_length=100)
    last_name = models.CharField(max_length=100)
    avatar_url = models.URLField(blank=True, null=True)
    is_email_verified = models.BooleanField(default=False)
    is_phone_verified = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    roles = models.JSONField(default=list)  # ['CUSTOMER', 'PROVIDER_OWNER', 'ADMIN']
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    objects = UserManager()

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['first_name', 'last_name']


def default_profile_badges():
    return [
        {
            'id': 'munnar_mist',
            'title': 'Munnar Mist Explorer',
            'icon': 'mountain',
            'description': 'Navigated high-altitude tea trails of Lockhart Valley',
            'earned_at': '2026-08-15',
        },
        {
            'id': 'backwater_guardian',
            'title': 'Backwater Guardian',
            'icon': 'anchor',
            'description': 'Completed zero-plastic solar houseboat journey in Kumarakom',
            'earned_at': '2026-09-02',
        },
        {
            'id': 'spice_route',
            'title': 'Spice Route Trekker',
            'icon': 'leaf',
            'description': 'Supported organic cardamom farmers in Thekkady',
            'earned_at': '2026-09-20',
        },
    ]


def default_offline_packages():
    return [
        {
            'id': 'pkg_munnar',
            'name': 'Munnar & Lockhart Valley Corridor',
            'size': '42 MB',
            'is_downloaded': True,
            'includes': 'Ghat route topo, offline SOS checkpoints, nearest CHC clinics',
        },
        {
            'id': 'pkg_wayanad',
            'name': 'Wayanad Ghat & Forest Pass',
            'size': '38 MB',
            'is_downloaded': False,
            'includes': 'Thamarassery Churam hairpin map, wildlife sanctuary emergency contacts',
        },
    ]


class UserProfile(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')
    
    # In Case of Emergency (ICE)
    emergency_contact_name = models.CharField(max_length=150, blank=True, default='Ananya S. (Sister)')
    emergency_contact_phone = models.CharField(max_length=50, blank=True, default='+91 94471 23456')
    blood_group = models.CharField(max_length=20, blank=True, default='O+ Positive')
    medical_notes = models.TextField(blank=True, default='No major allergies. Carries mild asthma inhaler.')
    
    # AI Architect & Experience Preferences
    dietary_preference = models.CharField(max_length=100, blank=True, default='Traditional Kerala Sadya (Veg)')
    travel_pace = models.CharField(max_length=100, blank=True, default='Balanced (2-3 stops/day)')
    accessibility_required = models.BooleanField(default=False)
    
    # Eco-Tourism Passport
    eco_score = models.IntegerField(default=92)
    eco_tier = models.CharField(max_length=100, default='Backwater Guardian')
    trips_completed = models.IntegerField(default=3)
    ev_miles = models.IntegerField(default=142)
    carbon_offset_kg = models.FloatField(default=58.4)
    badges = models.JSONField(default=default_profile_badges, blank=True)
    
    # Offline Ghat Corridors
    offline_packages = models.JSONField(default=default_offline_packages, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Profile of {self.user.email}"


class UserSession(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='sessions')
    device_id = models.CharField(max_length=128)
    device_name = models.CharField(max_length=128)
    platform = models.CharField(max_length=20)  # WEB, ANDROID, IOS
    ip_address = models.GenericIPAddressField()
    user_agent = models.TextField()
    last_active = models.DateTimeField(auto_now=True)
    expires_at = models.DateTimeField()
    revoked_at = models.DateTimeField(null=True, blank=True)

    @property
    def is_active(self):
        return self.revoked_at is None and timezone.now() < self.expires_at

class RefreshTokenFamily(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    session = models.ForeignKey(UserSession, on_delete=models.CASCADE, related_name='token_families')
    is_valid = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

class RefreshToken(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    family = models.ForeignKey(RefreshTokenFamily, on_delete=models.CASCADE, related_name='tokens')
    token_hash = models.CharField(max_length=64, db_index=True)  # SHA-256
    issued_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    used_at = models.DateTimeField(null=True, blank=True)
    revoked_at = models.DateTimeField(null=True, blank=True)
    replaced_by = models.ForeignKey('self', null=True, blank=True, on_delete=models.SET_NULL)

    @staticmethod
    def hash_token(raw_token: str) -> str:
        return hashlib.sha256(raw_token.encode('utf-8')).hexdigest()

class PasswordResetOTP(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='password_otps')
    otp = models.CharField(max_length=6, db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    is_used = models.BooleanField(default=False)

    class Meta:
        ordering = ['-created_at']

    @classmethod
    def generate_otp_for_user(cls, user):
        import random
        from datetime import timedelta
        # Invalidate old unused OTPs
        cls.objects.filter(user=user, is_used=False).update(is_used=True)
        code = f"{random.randint(100000, 999999)}"
        return cls.objects.create(
            user=user,
            otp=code,
            expires_at=timezone.now() + timedelta(minutes=15),
            is_used=False
        )

    def is_valid(self):
        return not self.is_used and timezone.now() <= self.expires_at


class EmailVerificationOTP(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='email_otps')
    otp = models.CharField(max_length=6, db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    is_used = models.BooleanField(default=False)

    class Meta:
        ordering = ['-created_at']

    @classmethod
    def generate_otp_for_user(cls, user):
        import random
        from datetime import timedelta
        cls.objects.filter(user=user, is_used=False).update(is_used=True)
        code = f"{random.randint(100000, 999999)}"
        return cls.objects.create(
            user=user,
            otp=code,
            expires_at=timezone.now() + timedelta(minutes=30),
            is_used=False
        )

    def is_valid(self):
        return not self.is_used and timezone.now() <= self.expires_at

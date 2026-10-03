from rest_framework import serializers
from .models import User, UserProfile, UserSession, RefreshTokenFamily, RefreshToken, BLOOD_GROUP_CHOICES

class UserSerializer(serializers.ModelSerializer):
    """
    Safe public user identity representation.
    Does NOT embed health, medical notes, or emergency contact data.
    Safe for login responses, token checks, and general user references.
    """
    class Meta:
        model = User
        fields = ['id', 'email', 'phone', 'first_name', 'last_name', 'avatar_url', 'is_email_verified', 'is_phone_verified', 'roles', 'created_at']
        read_only_fields = ['id', 'is_email_verified', 'is_phone_verified', 'created_at']


class UserProfileSerializer(serializers.ModelSerializer):
    """
    Full representation of UserProfile.
    Strictly restricted to the authenticated account owner.
    """
    class Meta:
        model = UserProfile
        fields = [
            'emergency_contact_name', 'emergency_contact_phone', 'emergency_contact_email',
            'emergency_location_sharing_consented', 'blood_group', 'medical_notes',
            'dietary_preference', 'travel_pace', 'accessibility_required',
            'eco_score', 'eco_tier', 'trips_completed', 'ev_miles', 'carbon_offset_kg',
            'badges', 'offline_packages',
            'data_processing_consented', 'data_processing_consented_at', 'consent_policy_version'
        ]
        read_only_fields = ['eco_score', 'eco_tier', 'trips_completed', 'ev_miles', 'carbon_offset_kg', 'badges']


class UserOwnerDetailSerializer(serializers.ModelSerializer):
    """
    Complete private account detail serializer returned only to the authenticated owner.
    """
    profile = UserProfileSerializer(read_only=True)

    class Meta:
        model = User
        fields = ['id', 'email', 'phone', 'first_name', 'last_name', 'avatar_url', 'is_email_verified', 'is_phone_verified', 'roles', 'profile', 'created_at']
        read_only_fields = ['id', 'is_email_verified', 'is_phone_verified', 'created_at']


class UserProfileUpdateSerializer(serializers.Serializer):
    """
    Strict write serializer with an explicit whitelist.
    Validates field constraints, lengths, and choices.
    Eco counters and badges are strictly omitted from writes.
    """
    # User identity fields
    first_name = serializers.CharField(max_length=100, required=False)
    last_name = serializers.CharField(max_length=100, required=False)
    phone = serializers.CharField(max_length=20, required=False, allow_blank=True)
    avatar_url = serializers.URLField(max_length=500, required=False, allow_blank=True)

    # Emergency Contact (ICE) & Health fields
    emergency_contact_name = serializers.CharField(max_length=150, required=False, allow_blank=True)
    emergency_contact_phone = serializers.CharField(max_length=50, required=False, allow_blank=True)
    emergency_contact_email = serializers.EmailField(required=False, allow_null=True, allow_blank=True)
    emergency_location_sharing_consented = serializers.BooleanField(required=False)
    blood_group = serializers.ChoiceField(choices=BLOOD_GROUP_CHOICES, required=False, allow_blank=True)
    medical_notes = serializers.CharField(max_length=500, required=False, allow_blank=True)

    # Travel & Accessibility preferences
    dietary_preference = serializers.CharField(max_length=100, required=False, allow_blank=True)
    travel_pace = serializers.CharField(max_length=100, required=False, allow_blank=True)
    accessibility_required = serializers.BooleanField(required=False)

    # Offline packages
    offline_packages = serializers.ListField(child=serializers.DictField(), required=False)

    # DPDP Consent
    data_processing_consented = serializers.BooleanField(required=False)

class UserSessionSerializer(serializers.ModelSerializer):
    is_active = serializers.BooleanField(read_only=True)

    class Meta:
        model = UserSession
        fields = ['id', 'device_id', 'device_name', 'platform', 'ip_address', 'last_active', 'expires_at', 'is_active']
        read_only_fields = ['id', 'last_active', 'expires_at']

class RegisterSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True, min_length=8)
    first_name = serializers.CharField(max_length=100)
    last_name = serializers.CharField(max_length=100)
    phone = serializers.CharField(max_length=20, required=False)

class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)
    device_name = serializers.CharField(required=False, default='Web Browser')
    platform = serializers.CharField(required=False, default='WEB')

class TokenRefreshSerializer(serializers.Serializer):
    refresh_token = serializers.CharField()

class PasswordResetRequestSerializer(serializers.Serializer):
    email = serializers.EmailField()

class PasswordResetVerifySerializer(serializers.Serializer):
    email = serializers.EmailField()
    otp = serializers.CharField(max_length=6, min_length=6)
    new_password = serializers.CharField(min_length=8)

class EmailVerificationSerializer(serializers.Serializer):
    email = serializers.EmailField()
    otp = serializers.CharField(max_length=6, min_length=6)

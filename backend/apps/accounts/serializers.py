from rest_framework import serializers
from .models import User, UserProfile, UserSession, RefreshTokenFamily, RefreshToken

class UserProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserProfile
        fields = [
            'emergency_contact_name', 'emergency_contact_phone', 'blood_group', 'medical_notes',
            'dietary_preference', 'travel_pace', 'accessibility_required',
            'eco_score', 'eco_tier', 'trips_completed', 'ev_miles', 'carbon_offset_kg',
            'badges', 'offline_packages'
        ]

class UserSerializer(serializers.ModelSerializer):
    profile = UserProfileSerializer(read_only=True)

    class Meta:
        model = User
        fields = ['id', 'email', 'phone', 'first_name', 'last_name', 'avatar_url', 'is_email_verified', 'is_phone_verified', 'roles', 'profile', 'created_at']
        read_only_fields = ['id', 'is_email_verified', 'is_phone_verified', 'created_at']

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

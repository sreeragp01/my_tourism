import uuid
import jwt
import secrets
from datetime import timedelta
from django.db import transaction
from django.conf import settings
from django.utils import timezone
from django.core.cache import cache
from rest_framework import status, views, permissions
from rest_framework.response import Response
from .models import (
    User, UserProfile, UserSession, RefreshTokenFamily, RefreshToken, PasswordResetOTP,
    EmailVerificationOTP
)
from .serializers import (
    UserSerializer, UserSessionSerializer, UserOwnerDetailSerializer, UserProfileUpdateSerializer,
    RegisterSerializer, LoginSerializer, TokenRefreshSerializer, PasswordResetRequestSerializer,
    PasswordResetVerifySerializer, EmailVerificationSerializer
)
from .services import AccountEmailService

def issue_tokens_for_session(user: User, session: UserSession, family: RefreshTokenFamily = None):
    now = timezone.now()
    if not family:
        family = RefreshTokenFamily.objects.create(session=session)

    # 15-minute Access Token
    access_payload = {
        'user_id': str(user.id),
        'session_id': str(session.id),
        'email': user.email,
        'roles': user.roles,
        'exp': now + timedelta(minutes=15),
        'iat': now,
    }
    signing_key = getattr(settings, 'JWT_SIGNING_KEY', None) or settings.SECRET_KEY
    access_token = jwt.encode(access_payload, signing_key, algorithm='HS256')

    # 14-day Refresh Token
    raw_refresh = str(uuid.uuid4())
    token_hash = RefreshToken.hash_token(raw_refresh)
    
    RefreshToken.objects.create(
        family=family,
        token_hash=token_hash,
        expires_at=now + timedelta(days=14),
    )

    return {
        'access_token': access_token,
        'refresh_token': raw_refresh,
        'refresh_token_expires_at': (now + timedelta(days=14)).isoformat(),
    }

class RegisterView(views.APIView):
    permission_classes = [permissions.AllowAny]
    throttle_scope = 'anon'

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        if User.objects.filter(email=data['email']).exists():
            return Response({'success': False, 'error': {'code': 'EMAIL_EXISTS', 'message': 'Email already in use'}}, status=status.HTTP_400_BAD_REQUEST)

        user = User.objects.create_user(
            email=data['email'],
            password=data['password'],
            first_name=data['first_name'],
            last_name=data['last_name'],
            phone=data.get('phone', ''),
            roles=['CUSTOMER'],
        )

        return Response({
            'success': True,
            'data': UserSerializer(user).data,
            'message': 'Account created successfully. Verification OTP sent.',
        }, status=status.HTTP_201_CREATED)

class LoginView(views.APIView):
    permission_classes = [permissions.AllowAny]
    throttle_scope = 'auth_login'

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data
        email = data['email'].lower().strip()

        # Per-email lockout against credential stuffing
        lockout_key = f"login_lockout:{email}"
        attempts_key = f"login_attempts:{email}"

        if cache.get(lockout_key):
            return Response({
                'success': False,
                'error': {
                    'code': 'ACCOUNT_LOCKED',
                    'message': 'Account temporarily locked due to multiple failed login attempts. Please try again after 15 minutes.'
                }
            }, status=status.HTTP_429_TOO_MANY_REQUESTS)

        try:
            user = User.objects.get(email=email)
            if not user.check_password(data['password']):
                failed_count = cache.get(attempts_key, 0) + 1
                cache.set(attempts_key, failed_count, timeout=900)
                if failed_count >= 5:
                    cache.set(lockout_key, True, timeout=900)
                return Response({'success': False, 'error': {'code': 'INVALID_CREDENTIALS', 'message': 'Invalid email or password'}}, status=status.HTTP_401_UNAUTHORIZED)
        except User.DoesNotExist:
            failed_count = cache.get(attempts_key, 0) + 1
            cache.set(attempts_key, failed_count, timeout=900)
            if failed_count >= 5:
                cache.set(lockout_key, True, timeout=900)
            return Response({'success': False, 'error': {'code': 'INVALID_CREDENTIALS', 'message': 'Invalid email or password'}}, status=status.HTTP_401_UNAUTHORIZED)

        # Successful authentication: clear failure counters
        cache.delete(attempts_key)
        cache.delete(lockout_key)

        # Extract client IP supporting reverse proxy
        xff = request.META.get('HTTP_X_FORWARDED_FOR')
        client_ip = xff.split(',')[0].strip() if xff else request.META.get('REMOTE_ADDR', '127.0.0.1')

        # Create session
        session = UserSession.objects.create(
            user=user,
            device_id=str(uuid.uuid4())[:12],
            device_name=data.get('device_name', 'Web Browser'),
            platform=data.get('platform', 'WEB'),
            ip_address=client_ip,
            user_agent=request.META.get('HTTP_USER_AGENT', 'Unknown'),
            expires_at=timezone.now() + timedelta(days=30),
        )

        tokens = issue_tokens_for_session(user, session)

        return Response({
            'success': True,
            'data': {
                'user': UserSerializer(user).data,
                'tokens': tokens,
                'session': UserSessionSerializer(session).data,
            },
            'message': 'Login successful',
        })

class RefreshTokenView(views.APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = TokenRefreshSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        raw_refresh = serializer.validated_data['refresh_token']
        token_hash = RefreshToken.hash_token(raw_refresh)

        try:
            token_record = RefreshToken.objects.select_related('family__session__user').get(token_hash=token_hash)
        except RefreshToken.DoesNotExist:
            return Response({'success': False, 'error': {'code': 'INVALID_TOKEN', 'message': 'Invalid refresh token'}}, status=status.HTTP_401_UNAUTHORIZED)

        family = token_record.family

        # Token Reuse / Theft Detection
        if token_record.used_at is not None or not family.is_valid:
            # Replay attack detected: invalidate entire token family & session
            family.is_valid = False
            family.save()
            family.session.revoked_at = timezone.now()
            family.session.save()
            return Response({
                'success': False,
                'error': {'code': 'TOKEN_REPLAY_DETECTED', 'message': 'Security alert: Token reuse detected. Session terminated.'}
            }, status=status.HTTP_401_UNAUTHORIZED)

        if token_record.expires_at < timezone.now():
            return Response({'success': False, 'error': {'code': 'TOKEN_EXPIRED', 'message': 'Refresh token has expired'}}, status=status.HTTP_401_UNAUTHORIZED)

        # Mark token as used (rotate)
        token_record.used_at = timezone.now()
        token_record.save()

        # Issue replacement token & new access token
        user = family.session.user
        new_tokens = issue_tokens_for_session(user, family.session, family)

        return Response({
            'success': True,
            'data': new_tokens,
            'message': 'Tokens rotated successfully',
        })

class SessionListView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        sessions = UserSession.objects.filter(user=request.user, revoked_at__isnull=True).order_by('-last_active')
        return Response({
            'success': True,
            'data': UserSessionSerializer(sessions, many=True).data,
        })

class RevokeSessionView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, session_id):
        try:
            session = UserSession.objects.get(id=session_id, user=request.user)
            session.revoked_at = timezone.now()
            session.save()
            # Invalidate all token families under this session
            session.token_families.update(is_valid=False)
            return Response({'success': True, 'message': 'Session revoked successfully'})
        except UserSession.DoesNotExist:
            return Response({'success': False, 'error': {'code': 'NOT_FOUND', 'message': 'Session not found'}}, status=status.HTTP_404_NOT_FOUND)


class RequestPasswordResetView(views.APIView):
    permission_classes = [permissions.AllowAny]
    throttle_scope = 'otp_request'

    def post(self, request):
        serializer = PasswordResetRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        email = serializer.validated_data['email'].lower().strip()

        try:
            user = User.objects.get(email=email)
            otp = PasswordResetOTP.generate_otp_for_user(user)
            email_sent = AccountEmailService.send_password_reset_otp_email(user, otp.otp)
            return Response({
                'success': True,
                'message': f'6-digit verification OTP sent to {email}.',
                'email_sent': email_sent,
            }, status=status.HTTP_200_OK)
        except User.DoesNotExist:
            return Response({
                'success': True,
                'message': f'If an account exists with {email}, a 6-digit verification OTP has been sent.'
            }, status=status.HTTP_200_OK)


class VerifyPasswordResetView(views.APIView):
    permission_classes = [permissions.AllowAny]
    throttle_scope = 'otp_verify'

    def post(self, request):
        serializer = PasswordResetVerifySerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        email = serializer.validated_data['email'].lower().strip()
        code = serializer.validated_data['otp'].strip()
        new_password = serializer.validated_data['new_password']

        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            return Response({'success': False, 'error': {'code': 'INVALID_REQUEST', 'message': 'Invalid reset request'}}, status=status.HTTP_400_BAD_REQUEST)

        # Fetch user's latest active OTP record
        otp_record = PasswordResetOTP.objects.filter(user=user, is_used=False).order_by('-created_at').first()
        if not otp_record:
            return Response({'success': False, 'error': {'code': 'INVALID_OTP', 'message': 'No active OTP verification found. Please request a new code.'}}, status=status.HTTP_400_BAD_REQUEST)

        if otp_record.attempts >= 5:
            otp_record.is_used = True
            otp_record.save(update_fields=['is_used'])
            return Response({
                'success': False,
                'error': {'code': 'OTP_LOCKED', 'message': 'Too many failed attempts. This OTP code has been locked. Please request a new code.'}
            }, status=status.HTTP_429_TOO_MANY_REQUESTS)

        if timezone.now() > otp_record.expires_at:
            return Response({'success': False, 'error': {'code': 'OTP_EXPIRED', 'message': 'OTP verification code has expired. Please request a new code.'}}, status=status.HTTP_400_BAD_REQUEST)

        # Constant-time comparison
        if not secrets.compare_digest(otp_record.otp, code):
            otp_record.attempts += 1
            otp_record.save(update_fields=['attempts'])
            remaining = max(0, 5 - otp_record.attempts)
            return Response({
                'success': False,
                'error': {'code': 'INVALID_OTP', 'message': f'Invalid verification code. {remaining} attempt(s) remaining.'}
            }, status=status.HTTP_400_BAD_REQUEST)

        # Successfully verified
        otp_record.is_used = True
        otp_record.save(update_fields=['is_used'])

        user.set_password(new_password)
        user.save()

        # Revoke all active sessions for security
        UserSession.objects.filter(user=user, revoked_at__isnull=True).update(revoked_at=timezone.now())

        return Response({
            'success': True,
            'message': 'Password has been successfully reset! Please log in with your new password.'
        }, status=status.HTTP_200_OK)


class SendVerificationOTPView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]
    throttle_scope = 'otp_request'

    def post(self, request):
        otp = EmailVerificationOTP.generate_otp_for_user(request.user)
        email_sent = AccountEmailService.send_verification_otp_email(request.user, otp.otp)
        return Response({
            'success': True,
            'message': f'Verification OTP sent to {request.user.email}',
            'email_sent': email_sent,
        }, status=status.HTTP_200_OK)


class VerifyEmailOTPView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]
    throttle_scope = 'otp_verify'

    def post(self, request):
        code = request.data.get('otp', '').strip()
        otp_record = EmailVerificationOTP.objects.filter(user=request.user, is_used=False).order_by('-created_at').first()
        if not otp_record:
            return Response({'success': False, 'error': {'code': 'INVALID_OTP', 'message': 'No active verification code found.'}}, status=status.HTTP_400_BAD_REQUEST)

        if otp_record.attempts >= 5:
            otp_record.is_used = True
            otp_record.save(update_fields=['is_used'])
            return Response({
                'success': False,
                'error': {'code': 'OTP_LOCKED', 'message': 'Too many failed attempts. Code locked. Please request a new code.'}
            }, status=status.HTTP_429_TOO_MANY_REQUESTS)

        if timezone.now() > otp_record.expires_at:
            return Response({'success': False, 'error': {'code': 'OTP_EXPIRED', 'message': 'Verification code has expired. Please request a new code.'}}, status=status.HTTP_400_BAD_REQUEST)

        if not secrets.compare_digest(otp_record.otp, code):
            otp_record.attempts += 1
            otp_record.save(update_fields=['attempts'])
            remaining = max(0, 5 - otp_record.attempts)
            return Response({
                'success': False,
                'error': {'code': 'INVALID_OTP', 'message': f'Invalid verification code. {remaining} attempt(s) remaining.'}
            }, status=status.HTTP_400_BAD_REQUEST)

        otp_record.is_used = True
        otp_record.save(update_fields=['is_used'])

        request.user.is_email_verified = True
        request.user.save()

        return Response({
            'success': True,
            'message': 'Email successfully verified!'
        }, status=status.HTTP_200_OK)


class UserProfileView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        profile, _ = UserProfile.objects.get_or_create(user=request.user)
        user_data = UserOwnerDetailSerializer(request.user).data
        return Response({
            'success': True,
            'data': user_data
        }, status=status.HTTP_200_OK)

    def patch(self, request):
        serializer = UserProfileUpdateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        validated = serializer.validated_data

        user = request.user
        profile, _ = UserProfile.objects.get_or_create(user=user)

        with transaction.atomic():
            # Update user identity fields if provided
            user_fields = ['first_name', 'last_name', 'phone', 'avatar_url']
            user_updated = False
            for field in user_fields:
                if field in validated:
                    setattr(user, field, validated[field])
                    user_updated = True
            if user_updated:
                user.save()

            # Update profile fields if provided
            profile_fields = [
                'emergency_contact_name', 'emergency_contact_phone', 'emergency_contact_email',
                'emergency_location_sharing_consented', 'blood_group', 'medical_notes',
                'dietary_preference', 'travel_pace', 'accessibility_required',
                'offline_packages', 'data_processing_consented'
            ]
            profile_updated = False
            for field in profile_fields:
                if field in validated:
                    setattr(profile, field, validated[field])
                    if field == 'data_processing_consented' and validated[field]:
                        profile.data_processing_consented_at = timezone.now()
                    profile_updated = True
            if profile_updated:
                profile.save()

        data = UserOwnerDetailSerializer(user).data
        return Response({
            'success': True,
            'message': 'Profile updated successfully',
            'data': data
        }, status=status.HTTP_200_OK)


import uuid
import jwt
from datetime import timedelta
from django.conf import settings
from django.utils import timezone
from rest_framework import status, views, permissions
from rest_framework.response import Response
from .models import User, UserSession, RefreshTokenFamily, RefreshToken, PasswordResetOTP, EmailVerificationOTP
from .serializers import (
    UserSerializer, UserSessionSerializer, RegisterSerializer, LoginSerializer,
    TokenRefreshSerializer, PasswordResetRequestSerializer, PasswordResetVerifySerializer,
    EmailVerificationSerializer
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
    access_token = jwt.encode(access_payload, settings.SECRET_KEY, algorithm='HS256')

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

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        try:
            user = User.objects.get(email=data['email'])
            if not user.check_password(data['password']):
                return Response({'success': False, 'error': {'code': 'INVALID_CREDENTIALS', 'message': 'Invalid email or password'}}, status=status.HTTP_401_UNAUTHORIZED)
        except User.DoesNotExist:
            return Response({'success': False, 'error': {'code': 'INVALID_CREDENTIALS', 'message': 'Invalid email or password'}}, status=status.HTTP_401_UNAUTHORIZED)

        # Create session
        session = UserSession.objects.create(
            user=user,
            device_id=str(uuid.uuid4())[:12],
            device_name=data.get('device_name', 'Web Browser'),
            platform=data.get('platform', 'WEB'),
            ip_address=request.META.get('REMOTE_ADDR', '127.0.0.1'),
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
                'demo_otp': otp.otp if getattr(settings, 'DEBUG', True) else None
            }, status=status.HTTP_200_OK)
        except User.DoesNotExist:
            return Response({
                'success': True,
                'message': f'If an account exists with {email}, a 6-digit verification OTP has been sent.'
            }, status=status.HTTP_200_OK)


class VerifyPasswordResetView(views.APIView):
    permission_classes = [permissions.AllowAny]

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

        otp_record = PasswordResetOTP.objects.filter(user=user, otp=code, is_used=False).first()
        if not otp_record or not otp_record.is_valid():
            return Response({'success': False, 'error': {'code': 'INVALID_OTP', 'message': 'Invalid or expired 6-digit OTP code'}}, status=status.HTTP_400_BAD_REQUEST)

        otp_record.is_used = True
        otp_record.save()

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

    def post(self, request):
        otp = EmailVerificationOTP.generate_otp_for_user(request.user)
        email_sent = AccountEmailService.send_verification_otp_email(request.user, otp.otp)
        return Response({
            'success': True,
            'message': f'Verification OTP sent to {request.user.email}',
            'email_sent': email_sent,
            'demo_otp': otp.otp if getattr(settings, 'DEBUG', True) else None
        }, status=status.HTTP_200_OK)


class VerifyEmailOTPView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        code = request.data.get('otp', '').strip()
        otp_record = EmailVerificationOTP.objects.filter(user=request.user, otp=code, is_used=False).first()
        if not otp_record or not otp_record.is_valid():
            return Response({'success': False, 'error': {'code': 'INVALID_OTP', 'message': 'Invalid or expired OTP'}}, status=status.HTTP_400_BAD_REQUEST)

        otp_record.is_used = True
        otp_record.save()

        request.user.is_email_verified = True
        request.user.save()

        return Response({
            'success': True,
            'message': 'Email successfully verified!'
        }, status=status.HTTP_200_OK)

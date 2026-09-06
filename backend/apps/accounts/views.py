import uuid
import jwt
from datetime import timedelta
from django.conf import settings
from django.utils import timezone
from rest_framework import status, views, permissions
from rest_framework.response import Response
from .models import User, UserSession, RefreshTokenFamily, RefreshToken
from .serializers import UserSerializer, UserSessionSerializer, RegisterSerializer, LoginSerializer, TokenRefreshSerializer

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

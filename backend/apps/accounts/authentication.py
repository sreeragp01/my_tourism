import jwt
from django.conf import settings
from rest_framework import authentication, exceptions
from .models import User, UserSession

class KeraLinkJWTAuthentication(authentication.BaseAuthentication):
    def authenticate(self, request):
        auth_header = request.headers.get('Authorization')
        if not auth_header or not auth_header.startswith('Bearer '):
            return None

        raw_token = auth_header.split(' ')[1]
        try:
            payload = jwt.decode(raw_token, settings.SECRET_KEY, algorithms=['HS256'])
        except jwt.ExpiredSignatureError:
            raise exceptions.AuthenticationFailed('Access token has expired')
        except jwt.InvalidTokenError:
            raise exceptions.AuthenticationFailed('Invalid access token')

        user_id = payload.get('user_id')
        session_id = payload.get('session_id')

        try:
            user = User.objects.get(id=user_id, is_active=True)
        except User.DoesNotExist:
            raise exceptions.AuthenticationFailed('User not found or inactive')

        if session_id:
            try:
                session = UserSession.objects.get(id=session_id)
                if not session.is_active:
                    raise exceptions.AuthenticationFailed('Session has been revoked')
            except UserSession.DoesNotExist:
                raise exceptions.AuthenticationFailed('Session not found')

        return (user, raw_token)

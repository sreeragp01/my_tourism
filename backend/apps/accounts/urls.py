from django.urls import path
from .views import (
    RegisterView, LoginView, RefreshTokenView, SessionListView, RevokeSessionView,
    RequestPasswordResetView, VerifyPasswordResetView, SendVerificationOTPView, VerifyEmailOTPView
)

urlpatterns = [
    path('register/', RegisterView.as_view(), name='register'),
    path('login/', LoginView.as_view(), name='login'),
    path('refresh/', RefreshTokenView.as_view(), name='token-refresh'),
    path('sessions/', SessionListView.as_view(), name='session-list'),
    path('sessions/<uuid:session_id>/revoke/', RevokeSessionView.as_view(), name='session-revoke'),
    
    # Password Reset & Verification
    path('password-reset/request/', RequestPasswordResetView.as_view(), name='password-reset-request'),
    path('password-reset/verify/', VerifyPasswordResetView.as_view(), name='password-reset-verify'),
    path('otp/send/', SendVerificationOTPView.as_view(), name='otp-send'),
    path('otp/verify/', VerifyEmailOTPView.as_view(), name='otp-verify'),
]

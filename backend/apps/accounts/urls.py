from django.urls import path
from .views import RegisterView, LoginView, RefreshTokenView, SessionListView, RevokeSessionView

urlpatterns = [
    path('register/', RegisterView.as_view(), name='register'),
    path('login/', LoginView.as_view(), name='login'),
    path('refresh/', RefreshTokenView.as_view(), name='token-refresh'),
    path('sessions/', SessionListView.as_view(), name='session-list'),
    path('sessions/<uuid:session_id>/revoke/', RevokeSessionView.as_view(), name='session-revoke'),
]

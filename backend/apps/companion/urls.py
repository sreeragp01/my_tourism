from django.urls import path
from .views import LiveTripCompanionChatView

urlpatterns = [
    path('chat/', LiveTripCompanionChatView.as_view(), name='companion-chat'),
]

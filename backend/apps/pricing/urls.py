from django.urls import path
from .views import CalculatePriceView

urlpatterns = [
    path('calculate/', CalculatePriceView.as_view(), name='pricing-calculate'),
]

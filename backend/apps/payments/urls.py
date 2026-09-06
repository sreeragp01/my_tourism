from django.urls import path
from .views import CreatePaymentOrderView, PaymentWebhookView, DirectPaymentVerifyView

urlpatterns = [
    path('create-order/', CreatePaymentOrderView.as_view(), name='payment-create-order'),
    path('webhook/', PaymentWebhookView.as_view(), name='payment-webhook'),
    path('verify/', DirectPaymentVerifyView.as_view(), name='payment-verify'),
]

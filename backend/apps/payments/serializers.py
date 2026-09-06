from rest_framework import serializers
from .models import Payment, ProcessedWebhookEvent

class PaymentSerializer(serializers.ModelSerializer):
    class Meta:
        model = Payment
        fields = '__all__'

class CreatePaymentOrderSerializer(serializers.Serializer):
    booking_id = serializers.UUIDField()
    amount = serializers.DecimalField(max_digits=12, decimal_places=2)
    idempotency_key = serializers.CharField(max_length=128)
    gateway = serializers.ChoiceField(choices=['RAZORPAY', 'SIMULATOR'], default='RAZORPAY')

class WebhookPayloadSerializer(serializers.Serializer):
    event_id = serializers.CharField(max_length=128)
    event_type = serializers.CharField(max_length=100)
    payload = serializers.DictField()
    signature = serializers.CharField(max_length=255, required=False, default="")

from rest_framework import serializers
from .models import Experience, ExperienceSlot

class ExperienceSlotSerializer(serializers.ModelSerializer):
    available_capacity = serializers.IntegerField(read_only=True)

    class Meta:
        model = ExperienceSlot
        fields = ['id', 'date', 'start_time', 'end_time', 'total_capacity', 'booked_capacity', 'held_capacity', 'available_capacity']

class ExperienceSerializer(serializers.ModelSerializer):
    slots = ExperienceSlotSerializer(many=True, read_only=True)

    class Meta:
        model = Experience
        fields = '__all__'

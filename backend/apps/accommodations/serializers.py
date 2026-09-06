from rest_framework import serializers
from .models import Accommodation, RoomType, RoomInventory

class RoomInventorySerializer(serializers.ModelSerializer):
    available_rooms = serializers.IntegerField(read_only=True)

    class Meta:
        model = RoomInventory
        fields = ['id', 'date', 'total_rooms', 'booked_rooms', 'held_rooms', 'available_rooms']

class RoomTypeSerializer(serializers.ModelSerializer):
    inventory = RoomInventorySerializer(many=True, read_only=True)

    class Meta:
        model = RoomType
        fields = '__all__'

class AccommodationSerializer(serializers.ModelSerializer):
    room_types = RoomTypeSerializer(many=True, read_only=True)

    class Meta:
        model = Accommodation
        fields = '__all__'

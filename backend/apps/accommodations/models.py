import uuid
from django.db import models

class Accommodation(models.Model):
    TYPE_CHOICES = [
        ('BOUTIQUE_RESORT', 'Boutique Resort'),
        ('LUXURY_HOUSEBOAT', 'Luxury Houseboat'),
        ('HERITAGE_HOMESTAY', 'Heritage Homestay'),
        ('ECO_LODGE', 'Eco Lodge'),
        ('CLIFF_VILLA', 'Cliff Villa'),
    ]

    id = models.CharField(primary_key=True, max_length=64)
    org_id = models.UUIDField(db_index=True)
    destination_id = models.CharField(max_length=64, db_index=True)
    name = models.CharField(max_length=255)
    type = models.CharField(max_length=50, choices=TYPE_CHOICES)
    tagline = models.CharField(max_length=255)
    description = models.TextField()
    hero_image = models.URLField()
    star_rating = models.PositiveIntegerField(default=5)
    base_price_per_night = models.DecimalField(max_digits=10, decimal_places=2)
    eco_green_score = models.PositiveIntegerField(default=85)
    amenities = models.JSONField(default=list)
    ai_suitability_score = models.PositiveIntegerField(default=95)
    explanation = models.JSONField(default=dict)

    def __str__(self):
        return self.name

class RoomType(models.Model):
    id = models.CharField(primary_key=True, max_length=64)
    accommodation = models.ForeignKey(Accommodation, on_delete=models.CASCADE, related_name='room_types')
    name = models.CharField(max_length=128)
    price_per_night = models.DecimalField(max_digits=10, decimal_places=2)
    capacity = models.PositiveIntegerField(default=2)
    features = models.JSONField(default=list)

class RoomInventory(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    room_type = models.ForeignKey(RoomType, on_delete=models.CASCADE, related_name='inventory')
    date = models.DateField(db_index=True)
    total_rooms = models.PositiveIntegerField(default=5)
    booked_rooms = models.PositiveIntegerField(default=0)
    held_rooms = models.PositiveIntegerField(default=0)

    @property
    def available_rooms(self):
        return max(0, self.total_rooms - self.booked_rooms - self.held_rooms)

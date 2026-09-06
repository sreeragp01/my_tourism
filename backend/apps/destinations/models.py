import uuid
from django.db import models

class Destination(models.Model):
    id = models.CharField(primary_key=True, max_length=64) # e.g. munnar, alleppey, kochi
    name = models.CharField(max_length=128)
    slug = models.SlugField(unique=True)
    district = models.CharField(max_length=64)
    tagline = models.CharField(max_length=255)
    description = models.TextField()
    hero_image = models.URLField()
    gallery_images = models.JSONField(default=list)
    latitude = models.FloatField()
    longitude = models.FloatField()
    best_season = models.CharField(max_length=128)
    tags = models.JSONField(default=list)
    preferences = models.JSONField(default=dict) # {"nature": 0.95, "romance": 0.90}
    family_friendly = models.BooleanField(default=True)
    senior_friendly = models.BooleanField(default=True)
    average_stay_days = models.PositiveIntegerField(default=2)

    def __str__(self):
        return self.name

class Attraction(models.Model):
    id = models.CharField(primary_key=True, max_length=64)
    destination = models.ForeignKey(Destination, on_delete=models.CASCADE, related_name='attractions')
    name = models.CharField(max_length=128)
    category = models.CharField(max_length=64)
    description = models.TextField()
    image = models.URLField()
    latitude = models.FloatField()
    longitude = models.FloatField()
    opening_time = models.CharField(max_length=10, default="08:00")
    closing_time = models.CharField(max_length=10, default="18:00")
    entry_fee = models.DecimalField(max_digits=8, decimal_places=2, default=0.0)
    typical_duration_mins = models.PositiveIntegerField(default=90)
    rain_friendly = models.BooleanField(default=False)
    crowd_profile = models.CharField(max_length=20, default='MODERATE')

    def __str__(self):
        return self.name

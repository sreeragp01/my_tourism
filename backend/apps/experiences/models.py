import uuid
from django.db import models

class Experience(models.Model):
    id = models.CharField(primary_key=True, max_length=64)
    org_id = models.UUIDField(db_index=True)
    destination_id = models.CharField(max_length=64, db_index=True)
    title = models.CharField(max_length=255)
    category = models.CharField(max_length=50) # NATURE, WATER, CULTURE, FOOD, ADVENTURE
    description = models.TextField()
    price_per_person = models.DecimalField(max_digits=10, decimal_places=2)
    duration_hours = models.FloatField()
    max_group_size = models.PositiveIntegerField(default=10)
    hero_image = models.URLField()
    included_items = models.JSONField(default=list)
    meeting_point = models.CharField(max_length=255)
    host_name = models.CharField(max_length=128)
    host_role = models.CharField(max_length=128)
    rating = models.FloatField(default=4.9)
    review_count = models.PositiveIntegerField(default=0)
    verified = models.BooleanField(default=True)
    rain_friendly = models.BooleanField(default=False)
    rain_alternative_id = models.CharField(max_length=64, blank=True, null=True)
    explanation = models.JSONField(default=dict)

    def __str__(self):
        return self.title

class ExperienceSlot(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    experience = models.ForeignKey(Experience, on_delete=models.CASCADE, related_name='slots')
    date = models.DateField(db_index=True)
    start_time = models.CharField(max_length=10)
    end_time = models.CharField(max_length=10)
    total_capacity = models.PositiveIntegerField(default=10)
    booked_capacity = models.PositiveIntegerField(default=0)
    held_capacity = models.PositiveIntegerField(default=0)

    @property
    def available_capacity(self):
        return max(0, self.total_capacity - self.booked_capacity - self.held_capacity)

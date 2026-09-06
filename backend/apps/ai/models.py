import uuid
from django.db import models
from django.conf import settings

class TripProfile(models.Model):
    STYLE_CHOICES = [
        ('BUDGET', 'Budget'),
        ('COMFORT', 'Comfort'),
        ('PREMIUM', 'Premium'),
        ('LUXURY', 'Luxury'),
    ]

    PACE_CHOICES = [
        ('RELAXED', 'Relaxed'),
        ('BALANCED', 'Balanced'),
        ('PACKED', 'Packed'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, null=True, blank=True, on_delete=models.SET_NULL)
    start_date = models.DateField()
    end_date = models.DateField()
    duration_days = models.PositiveIntegerField(default=6)
    adults = models.PositiveIntegerField(default=2)
    children = models.PositiveIntegerField(default=0)
    infants = models.PositiveIntegerField(default=0)
    starting_location = models.CharField(max_length=128, default='Kochi')
    ending_location = models.CharField(max_length=128, blank=True, null=True)
    budget_limit = models.DecimalField(max_digits=12, decimal_places=2, default=80000.00)
    travel_style = models.CharField(max_length=20, choices=STYLE_CHOICES, default='PREMIUM')
    pace = models.CharField(max_length=20, choices=PACE_CHOICES, default='RELAXED')
    interests = models.JSONField(default=list)  # ['Nature', 'Beaches', 'Food']
    avoidances = models.JSONField(default=list) # ['Long Drives']
    raw_prompt = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

class AIPlan(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    profile = models.ForeignKey(TripProfile, on_delete=models.CASCADE, related_name='plans')
    current_version = models.PositiveIntegerField(default=1)
    status = models.CharField(max_length=20, default='FINALIZED')  # DRAFT, FINALIZED, BOOKED
    created_at = models.DateTimeField(auto_now_add=True)

class AIPlanVersion(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    plan = models.ForeignKey(AIPlan, on_delete=models.CASCADE, related_name='versions')
    version_number = models.PositiveIntegerField(default=1)
    change_reason = models.CharField(max_length=255)
    itinerary_payload = models.JSONField()  # Full structured days, hourly timeline, transits, stays
    pricing_payload = models.JSONField()    # Price breakdown
    total_distance_km = models.FloatField(default=0.0)
    total_travel_hours = models.FloatField(default=0.0)
    green_trip_score = models.PositiveIntegerField(default=88)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('plan', 'version_number')

class AIPlanAnalyticsMetrics(models.Model):
    """
    Tracks operational utility and recommendation quality of the AI Travel Architect.
    Key Platform Signals:
      - AI Plan Acceptance Rate = (accepted / generated) * 100
      - AI Regeneration Rate = (regenerated / generated) * 100
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    date = models.DateField(unique=True, db_index=True)
    generated_plans_count = models.PositiveIntegerField(default=0)
    accepted_plans_count = models.PositiveIntegerField(default=0)
    regenerated_plans_count = models.PositiveIntegerField(default=0)
    average_synthesis_time_ms = models.FloatField(default=450.0)

    @property
    def acceptance_rate_percent(self) -> float:
        if self.generated_plans_count == 0:
            return 0.0
        return round((self.accepted_plans_count / self.generated_plans_count) * 100.0, 2)

    @property
    def regeneration_rate_percent(self) -> float:
        if self.generated_plans_count == 0:
            return 0.0
        return round((self.regenerated_plans_count / self.generated_plans_count) * 100.0, 2)

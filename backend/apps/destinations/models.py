import uuid
from django.db import models
from django.conf import settings


class Country(models.Model):
    id = models.CharField(primary_key=True, max_length=16)  # e.g. 'IN'
    name = models.CharField(max_length=128)
    code = models.CharField(max_length=8, unique=True)     # e.g. 'IND'
    currency_code = models.CharField(max_length=8, default='INR')
    currency_symbol = models.CharField(max_length=8, default='₹')
    status = models.CharField(max_length=32, default='ACTIVE')

    def __str__(self):
        return f"{self.name} ({self.code})"


class Region(models.Model):
    id = models.CharField(primary_key=True, max_length=64)  # e.g. 'south-india', 'north-india'
    country = models.ForeignKey(Country, on_delete=models.CASCADE, related_name='regions')
    name = models.CharField(max_length=128)
    slug = models.SlugField(unique=True)

    def __str__(self):
        return f"{self.name} [{self.country.code}]"


class State(models.Model):
    id = models.CharField(primary_key=True, max_length=64)  # e.g. 'kerala', 'rajasthan', 'goa'
    region = models.ForeignKey(Region, on_delete=models.CASCADE, related_name='states')
    name = models.CharField(max_length=128)
    slug = models.SlugField(unique=True)
    tourism_board_name = models.CharField(max_length=255, blank=True, null=True)

    def __str__(self):
        return f"{self.name} ({self.region.name})"


class TravelCircuit(models.Model):
    TERRAIN_CHOICES = [
        ('COASTAL', 'Coastal & Backwaters'),
        ('GHATS', 'Western Ghats & Highlands'),
        ('ALPINE', 'Himalayan Alpine & Valleys'),
        ('DESERT', 'Desert & Heritage Plains'),
        ('PLAINS', 'Plateaus & Plains'),
    ]

    STATUS_CHOICES = [
        ('ACTIVE', 'Active'),
        ('DRAFT', 'Draft'),
        ('COMING_SOON', 'Coming Soon'),
    ]

    id = models.CharField(primary_key=True, max_length=64)  # e.g. 'kerala-heritage-backwaters'
    name = models.CharField(max_length=128)
    slug = models.SlugField(unique=True)
    region = models.ForeignKey(Region, on_delete=models.SET_NULL, null=True, blank=True, related_name='circuits')
    states = models.ManyToManyField(State, related_name='circuits', blank=True)
    tagline = models.CharField(max_length=255)
    description = models.TextField()
    hero_image = models.URLField()
    gallery_images = models.JSONField(default=list)
    duration_min_days = models.PositiveIntegerField(default=4)
    duration_max_days = models.PositiveIntegerField(default=8)
    recommended_seasons = models.JSONField(default=list)  # e.g. ["October to March"]
    terrain_profile = models.CharField(max_length=32, choices=TERRAIN_CHOICES, default='COASTAL')
    status = models.CharField(max_length=32, choices=STATUS_CHOICES, default='ACTIVE')
    metadata = models.JSONField(default=dict)

    def __str__(self):
        return self.name

    @property
    def stops_count(self) -> int:
        return self.stops.count()


class Destination(models.Model):
    id = models.CharField(primary_key=True, max_length=64) # e.g. munnar, alleppey, kochi, jaipur
    name = models.CharField(max_length=128)
    slug = models.SlugField(unique=True)
    district = models.CharField(max_length=64)
    state = models.ForeignKey(State, on_delete=models.SET_NULL, null=True, blank=True, related_name='destinations')
    region = models.ForeignKey(Region, on_delete=models.SET_NULL, null=True, blank=True, related_name='destinations')
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


class TravelCircuitStop(models.Model):
    TRANSPORT_CHOICES = [
        ('CAR', 'Private Cab / Car'),
        ('TRAIN', 'Express Train'),
        ('FLIGHT', 'Domestic Flight'),
        ('FERRY', 'Houseboat / Ferry'),
        ('COMBINED', 'Multi-Modal Transit'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    circuit = models.ForeignKey(TravelCircuit, on_delete=models.CASCADE, related_name='stops')
    destination = models.ForeignKey(Destination, on_delete=models.CASCADE, related_name='circuit_stops')
    sequence_order = models.PositiveIntegerField(default=1)
    minimum_stay_days = models.PositiveIntegerField(default=1)
    recommended_stay_days = models.PositiveIntegerField(default=2)
    arrival_buffer_hours = models.FloatField(default=1.5)
    departure_buffer_hours = models.FloatField(default=1.0)
    preferred_transport = models.CharField(max_length=32, choices=TRANSPORT_CHOICES, default='CAR')
    stop_highlight = models.CharField(max_length=255, blank=True, default="")

    class Meta:
        ordering = ['sequence_order']
        unique_together = ('circuit', 'sequence_order')

    def __str__(self):
        return f"{self.circuit.name} - Stop {self.sequence_order}: {self.destination.name}"


class CircuitAnalyticsEvent(models.Model):
    """
    Workstream F13: Telemetry event model tracking circuit discovery, planning, and conversion funnel.
    """
    EVENT_TYPES = [
        ('VIEW', 'Circuit Viewed'),
        ('PLAN_STARTED', 'AI Plan Started for Circuit'),
        ('PLAN_GENERATED', 'AI Plan Generated'),
        ('PLAN_ACCEPTED', 'AI Plan Accepted'),
        ('PLAN_REGENERATED', 'AI Plan Regenerated'),
        ('BOOKING', 'Circuit Booking Initiated'),
        ('COMPLETED', 'Circuit Journey Completed'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    circuit = models.ForeignKey(TravelCircuit, on_delete=models.CASCADE, related_name='analytics_events')
    event_type = models.CharField(max_length=32, choices=EVENT_TYPES, db_index=True)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, null=True, blank=True, on_delete=models.SET_NULL)
    metadata = models.JSONField(default=dict)
    timestamp = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        ordering = ['-timestamp']

    def __str__(self):
        return f"{self.circuit.name} - {self.event_type} at {self.timestamp}"


class CircuitPerformanceSummary(models.Model):
    """
    Workstream F13: Aggregated operational intelligence and performance metrics for each circuit.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    circuit = models.OneToOneField(TravelCircuit, on_delete=models.CASCADE, related_name='performance_summary')
    total_views = models.PositiveIntegerField(default=0)
    plans_generated = models.PositiveIntegerField(default=0)
    plans_accepted = models.PositiveIntegerField(default=0)
    regeneration_count = models.PositiveIntegerField(default=0)
    bookings_count = models.PositiveIntegerField(default=0)
    average_trip_days = models.FloatField(default=5.0)
    average_booking_value_inr = models.DecimalField(max_digits=12, decimal_places=2, default=0.0)
    weather_substitution_count = models.PositiveIntegerField(default=0)
    last_updated = models.DateTimeField(auto_now=True)

    @property
    def acceptance_rate_percent(self) -> float:
        if self.plans_generated == 0:
            return 0.0
        return round((self.plans_accepted / self.plans_generated) * 100.0, 2)

    @property
    def conversion_rate_percent(self) -> float:
        if self.total_views == 0:
            return 0.0
        return round((self.bookings_count / self.total_views) * 100.0, 2)

    def __str__(self):
        return f"Summary for {self.circuit.name} (Acceptance: {self.acceptance_rate_percent}%)"

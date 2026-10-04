import uuid
from django.db import models

class TourPackage(models.Model):
    CATEGORY_CHOICES = [
        ('HILL_STATION', 'Misty Hill Stations & Tea Trails'),
        ('BACKWATERS', 'Backwaters & Houseboat Cruises'),
        ('HONEYMOON', 'Romantic Honeymoon Escapes'),
        ('ADVENTURE', 'Wildlife Safari & Adventure Treks'),
        ('AYURVEDA', 'Ayurvedic Wellness & Yoga'),
        ('CULTURE', 'Heritage, Kathakali & Temple Arts'),
        ('FAMILY', 'Complete Family Circuits'),
    ]

    id = models.CharField(primary_key=True, max_length=64)
    org_id = models.UUIDField(db_index=True, null=True, blank=True)
    operator_name = models.CharField(max_length=255)
    operator_phone = models.CharField(max_length=30)
    operator_whatsapp = models.CharField(max_length=30)
    operator_license = models.CharField(max_length=100, blank=True, default='DTPC / Kerala Tourism Accredited')
    is_operator_verified = models.BooleanField(default=True)
    
    title = models.CharField(max_length=255)
    slug = models.SlugField(unique=True, max_length=255)
    category = models.CharField(max_length=50, choices=CATEGORY_CHOICES, default='HILL_STATION', db_index=True)
    tagline = models.CharField(max_length=255)
    description = models.TextField()
    
    duration_days = models.PositiveIntegerField(default=3)
    duration_nights = models.PositiveIntegerField(default=2)
    start_city = models.CharField(max_length=100, default='Kochi')
    end_city = models.CharField(max_length=100, default='Kochi')
    destinations_covered = models.JSONField(default=list)  # ["Kochi", "Munnar", "Marayoor"]
    
    price_per_person = models.DecimalField(max_digits=10, decimal_places=2)
    original_price = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    
    hero_image = models.URLField(max_length=500)
    gallery_images = models.JSONField(default=list)
    
    highlights = models.JSONField(default=list)
    inclusions = models.JSONField(default=list)
    exclusions = models.JSONField(default=list)
    itinerary = models.JSONField(default=list)  # list of {day: 1, title: '...', description: '...', stay: '...', meals: '...'}
    
    rating = models.FloatField(default=4.9)
    review_count = models.PositiveIntegerField(default=24)
    is_featured = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-is_featured', '-rating', '-created_at']

    def __str__(self):
        return f"{self.title} ({self.operator_name})"

class PackageInquiry(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    package = models.ForeignKey(TourPackage, on_delete=models.CASCADE, related_name='inquiries')
    traveler_name = models.CharField(max_length=150)
    traveler_email = models.EmailField(blank=True, default='')
    traveler_phone = models.CharField(max_length=30)
    travel_date = models.CharField(max_length=50, blank=True, default='')
    guests_count = models.PositiveIntegerField(default=2)
    message = models.TextField(blank=True, default='')
    channel = models.CharField(max_length=50, default='INQUIRY')  # WHATSAPP, CALL, INQUIRY
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"Inquiry for {self.package.title} by {self.traveler_name}"

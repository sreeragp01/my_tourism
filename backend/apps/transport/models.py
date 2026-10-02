import uuid
from django.db import models

class VehicleCategory(models.Model):
    TYPE_CHOICES = [
        ('SEDAN', 'Prime Sedan (Dzire / Etios)'),
        ('SUV_PREMIUM', 'Premium Mountain SUV (Innova Crysta / Hycross)'),
        ('TEMPO_TRAVELLER', 'Executive Tempo Traveller (12-17 Seater)'),
        ('ELECTRIC_EV', 'Green Eco Cab (Nexon / ZS EV)'),
    ]

    id = models.CharField(primary_key=True, max_length=64)
    name = models.CharField(max_length=255)
    vehicle_type = models.CharField(max_length=50, choices=TYPE_CHOICES, default='SUV_PREMIUM')
    tagline = models.CharField(max_length=255)
    description = models.TextField(blank=True, default='')
    passenger_capacity = models.PositiveIntegerField(default=4)
    luggage_capacity = models.PositiveIntegerField(default=3)
    has_ac = models.BooleanField(default=True)
    has_mountain_permit = models.BooleanField(default=True)
    hero_image = models.URLField(max_length=500)
    base_rate_per_km = models.DecimalField(max_digits=8, decimal_places=2, default=18.00)
    daily_rental_rate = models.DecimalField(max_digits=10, decimal_places=2, default=3800.00)
    driver_bata_per_day = models.DecimalField(max_digits=8, decimal_places=2, default=500.00)
    features = models.JSONField(default=list)
    rating = models.FloatField(default=4.95)
    trip_count = models.PositiveIntegerField(default=140)
    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ['passenger_capacity']

    def __str__(self):
        return f"{self.name} ({self.get_vehicle_type_display()})"

class AirportTransferRoute(models.Model):
    AIRPORT_CHOICES = [
        ('COK', 'Cochin International Airport (Nedumbassery)'),
        ('TRV', 'Trivandrum International Airport'),
        ('CCJ', 'Calicut (Kozhikode) International Airport'),
        ('CNN', 'Kannur International Airport'),
    ]

    id = models.CharField(primary_key=True, max_length=64)
    airport_code = models.CharField(max_length=10, choices=AIRPORT_CHOICES, default='COK', db_index=True)
    airport_name = models.CharField(max_length=255)
    destination_name = models.CharField(max_length=255, db_index=True)
    district = models.CharField(max_length=100)
    distance_km = models.PositiveIntegerField()
    approx_duration_hours = models.FloatField()
    is_ghat_road = models.BooleanField(default=False)
    toll_and_parking_included = models.BooleanField(default=True)
    sedan_fare = models.DecimalField(max_digits=10, decimal_places=2)
    suv_crysta_fare = models.DecimalField(max_digits=10, decimal_places=2)
    tempo_fare = models.DecimalField(max_digits=10, decimal_places=2)
    is_popular = models.BooleanField(default=True)

    class Meta:
        ordering = ['-is_popular', 'distance_km']

    def __str__(self):
        return f"{self.airport_code} to {self.destination_name} ({self.distance_km} km)"

class CabBooking(models.Model):
    BOOKING_TYPE_CHOICES = [
        ('AIRPORT_PICKUP', 'Airport Pickup & Transfer'),
        ('AIRPORT_DROP', 'Airport Drop-off'),
        ('MULTI_DAY_RENTAL', 'Multi-Day Chauffeur Rental'),
        ('INTERCITY_DROP', 'Intercity One-Way Drop'),
    ]

    STATUS_CHOICES = [
        ('CONFIRMED', 'Confirmed'),
        ('DRIVER_ASSIGNED', 'Driver Assigned'),
        ('ON_THE_WAY', 'Chauffeur En Route'),
        ('COMPLETED', 'Completed'),
        ('CANCELLED', 'Cancelled'),
    ]

    PAYMENT_STATUS_CHOICES = [
        ('PAY_TO_DRIVER', 'Pay directly to Chauffeur (Cash / UPI)'),
        ('PAID_ONLINE', 'Paid Online in Advance'),
        ('PENDING', 'Payment Pending'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    booking_reference = models.CharField(max_length=32, unique=True, db_index=True)
    booking_type = models.CharField(max_length=50, choices=BOOKING_TYPE_CHOICES, default='AIRPORT_PICKUP')
    
    # Traveler Info
    traveler_name = models.CharField(max_length=150)
    traveler_email = models.EmailField(blank=True, default='')
    traveler_phone = models.CharField(max_length=30)
    
    # Vehicle & Itinerary
    vehicle_category = models.ForeignKey(VehicleCategory, on_delete=models.PROTECT, related_name='bookings')
    pickup_location = models.CharField(max_length=255)
    drop_location = models.CharField(max_length=255)
    pickup_date = models.DateField()
    pickup_time = models.CharField(max_length=20)
    days_count = models.PositiveIntegerField(default=1)
    passenger_count = models.PositiveIntegerField(default=2)
    luggage_count = models.PositiveIntegerField(default=2)
    
    # Airport Specific
    flight_number = models.CharField(max_length=50, blank=True, default='')
    nameboard_text = models.CharField(max_length=150, blank=True, default='')
    flight_delayed_protection = models.BooleanField(default=True)
    
    # Pricing & Status
    total_fare = models.DecimalField(max_digits=10, decimal_places=2)
    payment_status = models.CharField(max_length=50, choices=PAYMENT_STATUS_CHOICES, default='PAY_TO_DRIVER')
    status = models.CharField(max_length=50, choices=STATUS_CHOICES, default='CONFIRMED')
    
    # Assigned Driver
    assigned_driver_name = models.CharField(max_length=150, default='Rajesh Kumar')
    assigned_driver_phone = models.CharField(max_length=30, default='+91 94470 54321')
    assigned_driver_whatsapp = models.CharField(max_length=30, default='+919447054321')
    vehicle_plate_number = models.CharField(max_length=30, default='KL-07-CD-4589')
    
    special_notes = models.TextField(blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.booking_reference} - {self.traveler_name} ({self.vehicle_category.name})"

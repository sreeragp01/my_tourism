from django.core.management.base import BaseCommand
from apps.transport.models import VehicleCategory, AirportTransferRoute

class Command(BaseCommand):
    help = 'Seeds vehicle categories and airport transfer corridors in Kerala'

    def handle(self, *args, **options):
        vehicles = [
            {
                'id': 'sedan-prime',
                'name': 'Prime Sedan (Dzire / Etios)',
                'vehicle_type': 'SEDAN',
                'tagline': 'Comfortable, fuel-efficient travel for couples & solo travelers',
                'description': 'Air-conditioned compact sedan with ample boot space. Dedicated courteous chauffeur trained in Kerala tourist circuits.',
                'passenger_capacity': 4,
                'luggage_capacity': 2,
                'has_ac': True,
                'has_mountain_permit': True,
                'hero_image': 'https://images.unsplash.com/photo-1549399542-7e3f8b79c341?auto=format&fit=crop&w=800&q=80',
                'base_rate_per_km': 14.00,
                'daily_rental_rate': 2800.00,
                'driver_bata_per_day': 400.00,
                'features': [
                    'Chilled Air Conditioning',
                    '2 Large Suitcases Boot Space',
                    'English & Hindi Speaking Chauffeur',
                    'Complimentary Packaged Drinking Water',
                    'Mobile USB Charging Ports'
                ],
                'rating': 4.92,
                'trip_count': 320,
            },
            {
                'id': 'innova-crysta',
                'name': 'Toyota Innova Crysta / Hycross',
                'vehicle_type': 'SUV_PREMIUM',
                'tagline': 'Kerala #1 choice for family comfort & mountain ghat curves',
                'description': 'The undisputed king of Kerala long-distance road trips. Exceptional suspension absorbs mountain hairpins effortlessly. Ideal for families and highlands.',
                'passenger_capacity': 6,
                'luggage_capacity': 4,
                'has_ac': True,
                'has_mountain_permit': True,
                'hero_image': 'https://images.unsplash.com/photo-1533473359331-0135ef1b58bf?auto=format&fit=crop&w=800&q=80',
                'base_rate_per_km': 18.00,
                'daily_rental_rate': 3800.00,
                'driver_bata_per_day': 500.00,
                'features': [
                    'Reclining Captain Bucket Seats',
                    'Dual-Zone Rear AC Louvers',
                    'Certified Ghat-Road Mountain Chauffeur',
                    'Heavy Duty Roof Carrier for Large Bags',
                    'Emergency First-Aid & Umbrella in Vehicle'
                ],
                'rating': 4.98,
                'trip_count': 680,
            },
            {
                'id': 'tempo-traveller-12',
                'name': 'Executive Luxury Tempo Traveller',
                'vehicle_type': 'TEMPO_TRAVELLER',
                'tagline': 'Spacious group travel with luxury push-back seats',
                'description': 'Designed for large families, NRI reunions, and group celebrations. High ceiling, panoramic glass windows, and massive dedicated luggage boot.',
                'passenger_capacity': 12,
                'luggage_capacity': 10,
                'has_ac': True,
                'has_mountain_permit': True,
                'hero_image': 'https://images.unsplash.com/photo-1570125909232-eb263c188f7e?auto=format&fit=crop&w=800&q=80',
                'base_rate_per_km': 26.00,
                'daily_rental_rate': 5800.00,
                'driver_bata_per_day': 600.00,
                'features': [
                    '1x1 Individual Push-Back Velvet Seats',
                    'Overhead Individual AC Vents & Reading Lights',
                    'LED Screen with Bluetooth Stereo',
                    'Dedicated Luggage Storage Compartment',
                    'Uniformed Experienced Tourist Chauffeur'
                ],
                'rating': 4.90,
                'trip_count': 210,
            },
            {
                'id': 'electric-suv',
                'name': 'Green Kerala EV Cab (Nexon / ZS)',
                'vehicle_type': 'ELECTRIC_EV',
                'tagline': 'Zero emission, whisper-quiet eco travel for coastal trips',
                'description': 'Clean electric crossover ideal for coastal city and backwater transfers. Travel sustainably through God Own Country.',
                'passenger_capacity': 4,
                'luggage_capacity': 2,
                'has_ac': True,
                'has_mountain_permit': False,
                'hero_image': 'https://images.unsplash.com/photo-1563720223185-11003d516935?auto=format&fit=crop&w=800&q=80',
                'base_rate_per_km': 16.00,
                'daily_rental_rate': 3200.00,
                'driver_bata_per_day': 400.00,
                'features': [
                    '100% Electric & Zero Carbon Footprint',
                    'Whisper Quiet Vibration-Free Ride',
                    'KSEB Fast-Charging Network Enabled',
                    'Automatic Climate Control'
                ],
                'rating': 4.88,
                'trip_count': 95,
            },
        ]

        routes = [
            {
                'id': 'cok-to-munnar',
                'airport_code': 'COK',
                'airport_name': 'Cochin International Airport (Nedumbassery)',
                'destination_name': 'Munnar Tea Valley & Resorts',
                'district': 'Idukki',
                'distance_km': 110,
                'approx_duration_hours': 3.5,
                'is_ghat_road': True,
                'sedan_fare': 3200.00,
                'suv_crysta_fare': 4500.00,
                'tempo_fare': 7200.00,
                'is_popular': True,
            },
            {
                'id': 'cok-to-alleppey',
                'airport_code': 'COK',
                'airport_name': 'Cochin International Airport (Nedumbassery)',
                'destination_name': 'Alleppey Punnamada Houseboat Jetty',
                'district': 'Alappuzha',
                'distance_km': 85,
                'approx_duration_hours': 2.2,
                'is_ghat_road': False,
                'sedan_fare': 2600.00,
                'suv_crysta_fare': 3600.00,
                'tempo_fare': 5900.00,
                'is_popular': True,
            },
            {
                'id': 'cok-to-fort-kochi',
                'airport_code': 'COK',
                'airport_name': 'Cochin International Airport (Nedumbassery)',
                'destination_name': 'Fort Kochi & Mattancherry Heritage',
                'district': 'Ernakulam',
                'distance_km': 42,
                'approx_duration_hours': 1.2,
                'is_ghat_road': False,
                'sedan_fare': 1400.00,
                'suv_crysta_fare': 2100.00,
                'tempo_fare': 3800.00,
                'is_popular': True,
            },
            {
                'id': 'trv-to-varkala',
                'airport_code': 'TRV',
                'airport_name': 'Trivandrum International Airport (TRV)',
                'destination_name': 'Varkala North Cliff & Papanasam',
                'district': 'Trivandrum',
                'distance_km': 45,
                'approx_duration_hours': 1.2,
                'is_ghat_road': False,
                'sedan_fare': 1600.00,
                'suv_crysta_fare': 2400.00,
                'tempo_fare': 4200.00,
                'is_popular': True,
            },
            {
                'id': 'trv-to-kovalam',
                'airport_code': 'TRV',
                'airport_name': 'Trivandrum International Airport (TRV)',
                'destination_name': 'Kovalam Lighthouse Beach',
                'district': 'Trivandrum',
                'distance_km': 16,
                'approx_duration_hours': 0.5,
                'is_ghat_road': False,
                'sedan_fare': 900.00,
                'suv_crysta_fare': 1400.00,
                'tempo_fare': 2400.00,
                'is_popular': True,
            },
            {
                'id': 'ccj-to-wayanad',
                'airport_code': 'CCJ',
                'airport_name': 'Calicut International Airport (Karippur)',
                'destination_name': 'Wayanad (Vythiri / Kalpetta)',
                'district': 'Wayanad',
                'distance_km': 85,
                'approx_duration_hours': 2.5,
                'is_ghat_road': True,
                'sedan_fare': 2800.00,
                'suv_crysta_fare': 3900.00,
                'tempo_fare': 6400.00,
                'is_popular': True,
            },
        ]

        v_count = 0
        for v in vehicles:
            VehicleCategory.objects.update_or_create(id=v['id'], defaults=v)
            v_count += 1

        r_count = 0
        for r in routes:
            AirportTransferRoute.objects.update_or_create(id=r['id'], defaults=r)
            r_count += 1

        self.stdout.write(self.style.SUCCESS(f"Seeded {v_count} Vehicle Categories and {r_count} Airport Transfer Routes!"))

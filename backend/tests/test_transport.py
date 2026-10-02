from django.test import TestCase
from rest_framework.test import APIClient
from rest_framework import status
from apps.transport.models import VehicleCategory, AirportTransferRoute, CabBooking

class TransportAPITestCase(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.vehicle = VehicleCategory.objects.create(
            id='test-innova',
            name='Test Toyota Innova Crysta',
            vehicle_type='SUV_PREMIUM',
            tagline='Perfect for families',
            passenger_capacity=6,
            luggage_capacity=4,
            has_ac=True,
            has_mountain_permit=True,
            hero_image='https://example.com/innova.jpg',
            base_rate_per_km=18.00,
            daily_rental_rate=3800.00,
            driver_bata_per_day=500.00,
            features=['Captain Seats', 'Dual AC'],
            rating=4.95,
            is_active=True
        )

        self.route = AirportTransferRoute.objects.create(
            id='test-cok-munnar',
            airport_code='COK',
            airport_name='Cochin International Airport',
            destination_name='Munnar Tea Valley',
            district='Idukki',
            distance_km=110,
            approx_duration_hours=3.5,
            is_ghat_road=True,
            sedan_fare=3200.00,
            suv_crysta_fare=4500.00,
            tempo_fare=7200.00,
            is_popular=True
        )

    def test_list_vehicles(self):
        res = self.client.get('/api/v1/transport/vehicles/')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        results = res.data.get('results', res.data) if isinstance(res.data, dict) else res.data
        self.assertGreaterEqual(len(results), 1)
        self.assertEqual(results[0]['id'], 'test-innova')

    def test_list_airport_routes(self):
        res = self.client.get('/api/v1/transport/airport-routes/')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        results = res.data.get('results', res.data) if isinstance(res.data, dict) else res.data
        self.assertGreaterEqual(len(results), 1)

    def test_filter_airport_routes(self):
        res = self.client.get('/api/v1/transport/airport-routes/?airport=COK')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        results = res.data.get('results', res.data) if isinstance(res.data, dict) else res.data
        self.assertTrue(all(r['airport_code'] == 'COK' for r in results))

    def test_estimate_fare(self):
        payload = {
            'vehicle_id': self.vehicle.id,
            'distance_km': 150,
            'days_count': 2,
        }
        res = self.client.post('/api/v1/transport/bookings/estimate_fare/', payload, format='json')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertIn('estimated_fare', res.data)
        self.assertTrue(res.data['mountain_permit_included'])

    def test_create_cab_booking(self):
        payload = {
            'booking_type': 'AIRPORT_PICKUP',
            'traveler_name': 'Mohammed Al Falasi',
            'traveler_email': 'falasi@example.com',
            'traveler_phone': '+971 50 123 4567',
            'vehicle_category': self.vehicle.id,
            'pickup_location': 'Cochin International Airport - Arrival Gate 3',
            'drop_location': 'Munnar Tea Valley Resort',
            'pickup_date': '2026-11-20',
            'pickup_time': '14:30',
            'flight_number': 'EK-530',
            'nameboard_text': 'Welcome Mr. Falasi & Family',
            'days_count': 3,
            'passenger_count': 4,
            'luggage_count': 4,
            'total_fare': '11400.00',
            'payment_status': 'PAY_TO_DRIVER',
            'special_notes': 'Please keep mineral water chilled in the car.'
        }
        res = self.client.post('/api/v1/transport/bookings/', payload, format='json')
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertIn('booking_reference', res.data)
        self.assertTrue(res.data['booking_reference'].startswith('CAB-2026-'))
        self.assertEqual(res.data['traveler_name'], 'Mohammed Al Falasi')
        self.assertIn('driver_details', res.data)
        self.assertEqual(res.data['driver_details']['name'], 'Rajesh Kumar')
        self.assertIn('wa.me', res.data['driver_details']['whatsapp_url'])
        self.assertEqual(CabBooking.objects.count(), 1)

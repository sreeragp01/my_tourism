from django.test import TestCase
from rest_framework.test import APIClient
from rest_framework import status
from apps.packages.models import TourPackage, PackageInquiry

class TourPackagesAPITestCase(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.pkg = TourPackage.objects.create(
            id='pkg-test-munnar',
            title='3D2N Test Munnar Escape',
            slug='test-munnar-escape-3d2n',
            operator_name='Highland Adventures',
            operator_phone='+919876543210',
            operator_whatsapp='+919876543210',
            operator_license='DTPC Verified',
            is_operator_verified=True,
            category='HILL_STATION',
            tagline='Misty tea trails',
            description='A scenic test package in Munnar.',
            duration_days=3,
            duration_nights=2,
            start_city='Kochi',
            end_city='Kochi',
            destinations_covered=['Kochi', 'Munnar'],
            price_per_person=7999.00,
            original_price=9999.00,
            hero_image='https://example.com/img.jpg',
            highlights=['Kolukkumalai 4x4', 'Tea tasting'],
            inclusions=['Resort stay', 'Breakfast'],
            exclusions=['Flights'],
            itinerary=[
                {'day': 1, 'title': 'Arrival', 'description': 'Drive to Munnar', 'meals': 'Dinner', 'stay': 'Resort'},
                {'day': 2, 'title': 'Jeep Safari', 'description': 'Sunrise trek', 'meals': 'Breakfast', 'stay': 'Resort'},
                {'day': 3, 'title': 'Departure', 'description': 'Return to Kochi', 'meals': 'Breakfast', 'stay': 'Home'}
            ],
            rating=4.9,
            review_count=10,
            is_featured=True,
            is_active=True
        )

    def test_list_packages(self):
        res = self.client.get('/api/v1/packages/')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        # Handle paginated or direct list
        results = res.data.get('results', res.data) if isinstance(res.data, dict) else res.data
        self.assertGreaterEqual(len(results), 1)
        self.assertEqual(results[0]['operator']['name'], 'Highland Adventures')

    def test_featured_packages(self):
        res = self.client.get('/api/v1/packages/featured/')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertGreaterEqual(len(res.data), 1)

    def test_categories(self):
        res = self.client.get('/api/v1/packages/categories/')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        keys = [c['key'] for c in res.data]
        self.assertIn('HILL_STATION', keys)
        self.assertIn('BACKWATERS', keys)

    def test_filter_by_category(self):
        res = self.client.get('/api/v1/packages/?category=HILL_STATION')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        results = res.data.get('results', res.data) if isinstance(res.data, dict) else res.data
        self.assertTrue(all(p['category'] == 'HILL_STATION' for p in results))

    def test_search_package(self):
        res = self.client.get('/api/v1/packages/?q=Munnar')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        results = res.data.get('results', res.data) if isinstance(res.data, dict) else res.data
        self.assertGreaterEqual(len(results), 1)

    def test_package_detail(self):
        res = self.client.get(f'/api/v1/packages/{self.pkg.slug}/')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data['slug'], self.pkg.slug)
        self.assertEqual(len(res.data['itinerary']), 3)
        self.assertEqual(res.data['inclusions'], ['Resort stay', 'Breakfast'])

    def test_inquire_and_whatsapp_generation(self):
        payload = {
            'traveler_name': 'Rahul Sharma',
            'traveler_phone': '+91 9988776655',
            'traveler_email': 'rahul@example.com',
            'travel_date': '2026-11-15',
            'guests_count': 2,
            'message': 'Can you customize for vegetarian meals?'
        }
        res = self.client.post(f'/api/v1/packages/{self.pkg.slug}/inquire/', payload, format='json')
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertTrue(res.data['success'])
        self.assertIn('whatsapp_url', res.data)
        self.assertIn('wa.me/919876543210', res.data['whatsapp_url'])
        self.assertEqual(PackageInquiry.objects.count(), 1)

    def test_whatsapp_click(self):
        payload = {
            'traveler_name': 'Sneha',
            'traveler_phone': '+91 9123456789',
            'guests_count': 4,
            'travel_date': '2026-12-01'
        }
        res = self.client.post(f'/api/v1/packages/{self.pkg.slug}/whatsapp_click/', payload, format='json')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertIn('whatsapp_url', res.data)
        self.assertEqual(res.data['operator_name'], 'Highland Adventures')

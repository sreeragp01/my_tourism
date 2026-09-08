import uuid
from django.test import TestCase
from rest_framework.test import APIClient
from rest_framework import status

from apps.destinations.models import Destination, Attraction
from apps.experiences.models import Experience
from apps.accommodations.models import Accommodation


class UnifiedSearchTestCase(TestCase):
    """
    Comprehensive Test Suite for Phase 3: Unified Search & Discovery Engine.
    Covers:
      - Exact and partial matching
      - Case insensitivity
      - Empty query fallback
      - Multi-faceted filters (category, price, rain friendly, family friendly, rating, destination)
      - Combined filter query execution
      - Deterministic pagination (page, page_size, has_next)
      - Geographic coordinate distance proximity
      - Invalid parameter validation
      - Unauthenticated public access
    """

    def setUp(self):
        self.client = APIClient()
        self.org_id = uuid.uuid4()

        # Seed test Destinations
        self.munnar = Destination.objects.create(
            id='munnar',
            name='Munnar',
            slug='munnar',
            district='Idukki',
            tagline='Emerald Tea Gardens in the Western Ghats',
            description='Famous hill station known for expansive tea plantations and misty mountains.',
            hero_image='https://images.unsplash.com/photo-1596176530529-78163a4f7af2',
            latitude=10.0889,
            longitude=77.0595,
            best_season='Sept to May',
            tags=['tea', 'hills', 'mist', 'waterfalls'],
            family_friendly=True,
            senior_friendly=True,
            average_stay_days=3,
        )

        self.alleppey = Destination.objects.create(
            id='alleppey',
            name='Alleppey',
            slug='alleppey',
            district='Alappuzha',
            tagline='Venice of the East',
            description='World-renowned network of backwaters and lagoons.',
            hero_image='https://images.unsplash.com/photo-1602216056096-3b40cc0c9944',
            latitude=9.4981,
            longitude=76.3388,
            best_season='Oct to March',
            tags=['backwaters', 'houseboat', 'canals'],
            family_friendly=False,  # Set to False to test family_friendly filter distinction
            senior_friendly=True,
            average_stay_days=2,
        )

        # Seed Attractions
        self.tea_museum = Attraction.objects.create(
            id='att_tea_museum',
            destination=self.munnar,
            name='KDHP Tea Museum',
            category='CULTURE',
            description='Historical tea manufacturing museum with indoor processing exhibits.',
            image='https://images.unsplash.com/photo-1544787219-7f47ccb76574',
            latitude=10.0910,
            longitude=77.0600,
            opening_time='09:00',
            closing_time='17:00',
            entry_fee=150.00,
            typical_duration_mins=90,
            rain_friendly=True,
            crowd_profile='MODERATE'
        )

        self.eravikulam = Attraction.objects.create(
            id='att_eravikulam',
            destination=self.munnar,
            name='Eravikulam National Park',
            category='NATURE',
            description='Home to the endangered Nilgiri Tahr and Anamudi peak.',
            image='https://images.unsplash.com/photo-1506744038136-46273834b3fb',
            latitude=10.1500,
            longitude=77.0400,
            opening_time='08:00',
            closing_time='16:00',
            entry_fee=250.00,
            typical_duration_mins=180,
            rain_friendly=False,
            crowd_profile='HIGH'
        )

        # Seed Experiences
        self.exp_jeep = Experience.objects.create(
            id='exp_munnar_jeep',
            org_id=self.org_id,
            destination_id='munnar',
            title='Top Station 4x4 Mountain Jeep Safari',
            category='ADVENTURE',
            description='High altitude off-road jeep trail through cliffside tracks.',
            price_per_person=2200.00,
            duration_hours=4.0,
            max_group_size=6,
            hero_image='https://images.unsplash.com/photo-1533473359331-0135ef1b58bf',
            meeting_point='Munnar Town Center',
            host_name='Venu K.',
            host_role='Certified Ghat Driver',
            rating=4.9,
            review_count=84,
            verified=True,
            rain_friendly=False
        )

        self.exp_tea_tasting = Experience.objects.create(
            id='exp_tea_tasting',
            org_id=self.org_id,
            destination_id='munnar',
            title='Private Connoisseur Tea Tasting',
            category='CULTURE',
            description='Indoor sensory masterclass with certified sommelier.',
            price_per_person=850.00,
            duration_hours=2.0,
            max_group_size=10,
            hero_image='https://images.unsplash.com/photo-1576092768241-dec231879fc3',
            meeting_point='Lockhart Tea Estate',
            host_name='Priya Nair',
            host_role='Master Blender',
            rating=4.7,
            review_count=42,
            verified=True,
            rain_friendly=True
        )

        # Seed Accommodations
        self.acc_resort = Accommodation.objects.create(
            id='acc_munnar_resort',
            org_id=self.org_id,
            destination_id='munnar',
            name='Windermere Estate Heritage Retreat',
            type='BOUTIQUE_RESORT',
            tagline='Cardamom & Coffee Plantation Bungalow',
            description='Secluded heritage bungalow overlooking mist-shrouded valleys.',
            hero_image='https://images.unsplash.com/photo-1566073771259-6a8506099945',
            star_rating=5,
            base_price_per_night=8500.00,
            eco_green_score=92,
            amenities=['Plantation Walk', 'Hearth Fireplace', 'Organic Dining'],
            ai_suitability_score=98
        )

    def test_public_access_allowed(self):
        """Verify endpoint is publicly accessible without authorization tokens."""
        response = self.client.get('/api/v1/search/?q=munnar')
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_exact_match(self):
        response = self.client.get('/api/v1/search/?q=Munnar')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        self.assertTrue(any(d['id'] == 'munnar' for d in data['destinations']))

    def test_partial_match(self):
        response = self.client.get('/api/v1/search/?q=tea')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        # Should find Munnar (tag 'tea'), tea tasting experience, and tea museum attraction
        self.assertTrue(len(data['experiences']) >= 1)
        self.assertTrue(len(data['attractions']) >= 1)

    def test_case_insensitive_match(self):
        response = self.client.get('/api/v1/search/?q=mUnNaR')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        self.assertTrue(any(d['id'] == 'munnar' for d in data['destinations']))

    def test_empty_query_returns_all(self):
        response = self.client.get('/api/v1/search/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        self.assertGreaterEqual(data['total_count'], 4)

    def test_category_filter(self):
        response = self.client.get('/api/v1/search/?category=ADVENTURE')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        self.assertEqual(len(data['experiences']), 1)
        self.assertEqual(data['experiences'][0]['id'], 'exp_munnar_jeep')

    def test_price_range_filter(self):
        # min_price=1000, max_price=3000 should include 2200 jeep safari, exclude 850 tea tasting
        response = self.client.get('/api/v1/search/?min_price=1000&max_price=3000')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        exp_ids = [e['id'] for e in data['experiences']]
        self.assertIn('exp_munnar_jeep', exp_ids)
        self.assertNotIn('exp_tea_tasting', exp_ids)

    def test_rain_friendly_filter(self):
        response = self.client.get('/api/v1/search/?rain_friendly=true')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        # All returned experiences and attractions must be rain_friendly
        for exp in data['experiences']:
            self.assertTrue(exp['rain_friendly'])
        for att in data['attractions']:
            self.assertTrue(att['rain_friendly'])

    def test_family_friendly_filter(self):
        response = self.client.get('/api/v1/search/?family_friendly=true')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        dest_ids = [d['id'] for d in data['destinations']]
        self.assertIn('munnar', dest_ids)
        self.assertNotIn('alleppey', dest_ids)

    def test_rating_filter(self):
        # min_rating 4.8 should include jeep safari (4.9) and exclude tea tasting (4.7)
        response = self.client.get('/api/v1/search/?min_rating=4.8')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        exp_ids = [e['id'] for e in data['experiences']]
        self.assertIn('exp_munnar_jeep', exp_ids)
        self.assertNotIn('exp_tea_tasting', exp_ids)

    def test_destination_filter(self):
        response = self.client.get('/api/v1/search/?destination=munnar')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        for exp in data['experiences']:
            self.assertEqual(exp['destination_id'], 'munnar')

    def test_combined_filters(self):
        # munnar + rain_friendly + category CULTURE
        response = self.client.get('/api/v1/search/?destination=munnar&rain_friendly=true&category=CULTURE')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        self.assertEqual(len(data['experiences']), 1)
        self.assertEqual(data['experiences'][0]['id'], 'exp_tea_tasting')
        self.assertEqual(len(data['attractions']), 1)
        self.assertEqual(data['attractions'][0]['id'], 'att_tea_museum')

    def test_pagination_contract(self):
        response = self.client.get('/api/v1/search/?page=1&page_size=2')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        self.assertEqual(data['page'], 1)
        self.assertEqual(data['page_size'], 2)
        self.assertIn('total_count', data)
        self.assertIn('has_next', data)

    def test_geo_proximity_distance(self):
        # Munnar coordinates: (10.0889, 77.0595)
        # Search with lat/lng in Munnar within 10 km
        response = self.client.get('/api/v1/search/?lat=10.0889&lng=77.0595&radius_km=10')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        # Munnar destination is close, distance_km should be populated and <= 10
        munnar_item = next((d for d in data['destinations'] if d['id'] == 'munnar'), None)
        self.assertIsNotNone(munnar_item)
        self.assertIsNotNone(munnar_item['distance_km'])
        self.assertLessEqual(munnar_item['distance_km'], 1.0)

    def test_invalid_parameters_handling(self):
        # Invalid min_price (negative)
        response = self.client.get('/api/v1/search/?min_price=-500')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_adapter_factory_and_postgres_adapter_fallback(self):
        from apps.search.adapters import get_search_adapter, PostgresFullTextSearchAdapter, DatabaseSearchAdapter
        
        # Test factory resolution
        adapter_default = get_search_adapter()
        self.assertIsInstance(adapter_default, DatabaseSearchAdapter)
        
        adapter_pg = get_search_adapter('postgres')
        self.assertIsInstance(adapter_pg, PostgresFullTextSearchAdapter)

        # On SQLite / fallback, PostgresFullTextSearchAdapter falls back cleanly to DatabaseSearchAdapter
        res = adapter_pg.search({'q': 'munnar'})
        self.assertTrue(any(d['id'] == 'munnar' for d in res['destinations']))

    def test_haversine_distance_calculation(self):
        from apps.search.adapters import haversine_distance
        # Distance between Munnar (10.0889, 77.0595) and Kochi (9.9312, 76.2673) is ~88-90 km
        dist = haversine_distance(10.0889, 77.0595, 9.9312, 76.2673)
        self.assertGreaterEqual(dist, 85.0)
        self.assertLessEqual(dist, 95.0)

    def test_unified_search_service_type_filtering(self):
        from apps.search.services import UnifiedSearchService
        service = UnifiedSearchService()
        
        # Experiences only
        res_exp = service.search({'type': 'experiences', 'q': 'jeep'})
        self.assertEqual(len(res_exp['experiences']), 1)
        self.assertEqual(len(res_exp['destinations']), 0)
        self.assertEqual(len(res_exp['accommodations']), 0)
        self.assertEqual(len(res_exp['attractions']), 0)
        
        # Accommodations only
        res_acc = service.search({'type': 'accommodations', 'q': 'estate'})
        self.assertEqual(len(res_acc['accommodations']), 1)
        self.assertEqual(len(res_acc['destinations']), 0)
        
        # Attractions only
        res_att = service.search({'type': 'attractions', 'q': 'museum'})
        self.assertEqual(len(res_att['attractions']), 1)
        self.assertEqual(len(res_att['experiences']), 0)

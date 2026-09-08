import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:keralink_mobile/core/config/app_config.dart';
import 'package:keralink_mobile/core/network/api_client.dart';
import 'package:keralink_mobile/core/storage/secure_token_storage.dart';
import 'package:keralink_mobile/features/search/models/search_result_model.dart';
import 'package:keralink_mobile/features/search/data/search_repository.dart';
import 'package:keralink_mobile/features/search/presentation/search_discovery_screen.dart';
import 'package:keralink_mobile/features/explore/models/accommodation_model.dart';
import 'package:keralink_mobile/features/home/models/destination_model.dart';

void main() {
  group('Phase 3: Search Models & Query Parameters Tests', () {
    test('SearchFilter serializes to DRF query parameters correctly', () {
      const filter = SearchFilter(
        query: 'munnar',
        destination: 'munnar',
        category: 'ADVENTURE',
        type: 'all',
        minPrice: 1000,
        maxPrice: 5000,
        rainFriendly: true,
        familyFriendly: true,
        minRating: 4.5,
        lat: 10.0889,
        lng: 77.0595,
        radiusKm: 25.0,
        page: 1,
        pageSize: 20,
      );

      final params = filter.toQueryParams();
      expect(params['q'], 'munnar');
      expect(params['destination'], 'munnar');
      expect(params['category'], 'ADVENTURE');
      expect(params['min_price'], '1000');
      expect(params['max_price'], '5000');
      expect(params['rain_friendly'], 'true');
      expect(params['family_friendly'], 'true');
      expect(params['min_rating'], '4.5');
      expect(params['lat'], '10.0889');
      expect(params['lng'], '77.0595');
      expect(params['radius_km'], '25.0');
      expect(params['page'], '1');
      expect(params['page_size'], '20');
    });

    test('Accommodation.fromJson parses DRF payload correctly', () {
      final json = {
        'id': 'acc_spice_tree',
        'destination_id': 'munnar',
        'name': 'Spice Tree Luxury Chalets',
        'type': 'BOUTIQUE_RESORT',
        'tagline': 'Perched on Cloud-Lined Mountain Ridge',
        'description': 'Ultra-luxury stone chalets with solar-heated private plunge pools.',
        'hero_image': 'https://images.unsplash.com/photo-1582510003544',
        'star_rating': 5,
        'base_price_per_night': 9500.0,
        'eco_green_score': 92,
        'amenities': ['Infinity Pool', 'Ayurvedic Spa'],
        'ai_suitability_score': 96,
      };

      final acc = Accommodation.fromJson(json);
      expect(acc.id, 'acc_spice_tree');
      expect(acc.destinationId, 'munnar');
      expect(acc.starRating, 5);
      expect(acc.basePricePerNight, 9500.0);
      expect(acc.ecoGreenScore, 92);
      expect(acc.amenities.length, 2);
    });

    test('SearchResults.fromJson parses multi-model categorized payload', () {
      final json = {
        'query': 'munnar',
        'total_count': 4,
        'page': 1,
        'page_size': 20,
        'has_next': false,
        'destinations': [
          {
            'id': 'munnar',
            'name': 'Munnar',
            'slug': 'munnar',
            'district': 'Idukki',
            'tagline': 'Misty Tea Hills',
            'description': 'Perched in Western Ghats',
            'hero_image': 'https://images.unsplash.com/photo-1593693397690',
            'latitude': 10.0889,
            'longitude': 77.0595,
            'best_season': 'Sept to March',
            'tags': ['Tea', 'Hills'],
            'family_friendly': true,
          }
        ],
        'experiences': [
          {
            'id': 'exp_tea_tasting',
            'org_id': 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
            'destination_id': 'munnar',
            'title': 'Lockhart Tea Tasting',
            'category': 'CULTURE',
            'description': 'Cupping session with sommelier',
            'price_per_person': 1200.0,
            'duration_hours': 2.5,
            'hero_image': 'https://images.unsplash.com/photo-1593693397690',
            'rating': 4.95,
            'rain_friendly': true,
          }
        ],
        'accommodations': [
          {
            'id': 'acc_resort',
            'destination_id': 'munnar',
            'name': 'Spice Tree Resort',
            'type': 'BOUTIQUE_RESORT',
            'tagline': 'Mountain Ridge Chalets',
            'description': 'Luxury resort',
            'hero_image': 'https://images.unsplash.com/photo-1582510003544',
            'star_rating': 5,
            'base_price_per_night': 9500.0,
            'eco_green_score': 92,
          }
        ],
        'attractions': [
          {
            'id': 'att_tea_museum',
            'destination': 'munnar',
            'name': 'Tea Museum',
            'category': 'CULTURE',
            'description': 'Historical factory exhibits',
            'image': 'https://images.unsplash.com/photo-1544787219',
            'latitude': 10.0910,
            'longitude': 77.0600,
            'opening_time': '09:00',
            'closing_time': '17:00',
            'entry_fee': 150.0,
            'typical_duration_mins': 90,
            'rain_friendly': true,
            'crowd_profile': 'MODERATE',
          }
        ],
      };

      final results = SearchResults.fromJson(json);
      expect(results.query, 'munnar');
      expect(results.totalCount, 4);
      expect(results.destinations.length, 1);
      expect(results.experiences.length, 1);
      expect(results.accommodations.length, 1);
      expect(results.attractions.length, 1);
      expect(results.isEmpty, false);
    });

    test('SearchResults.append concatenates paginated results correctly', () {
      final page1 = SearchResults(
        query: 'munnar',
        totalCount: 3,
        page: 1,
        pageSize: 2,
        hasNext: true,
        destinations: const [
          Destination(
            id: 'munnar',
            name: 'Munnar',
            slug: 'munnar',
            district: 'Idukki',
            tagline: 'Tea Hills',
            description: 'Misty hills',
            heroImage: 'https://example.com/img.jpg',
            latitude: 10.0889,
            longitude: 77.0595,
            distanceKm: 1.2,
          )
        ],
      );

      final page2 = SearchResults(
        query: 'munnar',
        totalCount: 3,
        page: 2,
        pageSize: 2,
        hasNext: false,
        destinations: const [
          Destination(
            id: 'alleppey',
            name: 'Alleppey',
            slug: 'alleppey',
            district: 'Alappuzha',
            tagline: 'Backwaters',
            description: 'Canals',
            heroImage: 'https://example.com/img2.jpg',
            latitude: 9.4981,
            longitude: 76.3388,
            distanceKm: 120.5,
          )
        ],
      );

      final combined = page1.append(page2);
      expect(combined.destinations.length, 2);
      expect(combined.page, 2);
      expect(combined.hasNext, false);
      expect(combined.destinations.first.distanceKm, 1.2);
      expect(combined.destinations.last.distanceKm, 120.5);
    });
  });

  group('Phase 3: SearchRepository Integration & Caching Tests', () {
    test('SearchRepository executes query and caches response', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/search/')) {
          return http.Response(
            jsonEncode({
              'query': 'munnar',
              'total_count': 1,
              'page': 1,
              'page_size': 20,
              'has_next': false,
              'destinations': [
                {
                  'id': 'munnar',
                  'name': 'Munnar',
                  'slug': 'munnar',
                  'district': 'Idukki',
                  'tagline': 'Misty Tea Hills',
                  'description': 'Famous tea hills',
                  'hero_image': 'https://example.com/img.jpg',
                  'latitude': 10.0889,
                  'longitude': 77.0595,
                  'best_season': 'Sept-March',
                  'tags': ['Tea'],
                  'family_friendly': true,
                }
              ],
              'experiences': [],
              'accommodations': [],
              'attractions': [],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(
        config: const AppConfig(environment: AppEnvironment.development, customBaseUrl: 'http://test.api/api/v1'),
        storage: InMemoryTokenStorage(),
        httpClient: mockClient,
      );

      final repo = SearchRepository(apiClient: apiClient);
      final res = await repo.search(const SearchFilter(query: 'munnar'));

      expect(res.totalCount, 1);
      expect(res.destinations.first.name, 'Munnar');

      // Subsequent identical search hits memory cache
      final cachedRes = await repo.search(const SearchFilter(query: 'munnar'));
      expect(cachedRes.totalCount, 1);
    });

    test('SearchRepository provides offline fallback on network failure', () async {
      final failingClient = MockClient((request) async {
        return http.Response('Network Error', 500);
      });

      final apiClient = ApiClient(
        config: const AppConfig(environment: AppEnvironment.development, customBaseUrl: 'http://test.api/api/v1'),
        storage: InMemoryTokenStorage(),
        httpClient: failingClient,
      );

      final repo = SearchRepository(apiClient: apiClient);
      final res = await repo.search(const SearchFilter(query: 'munnar'));

      expect(res.destinations.isNotEmpty, true);
      expect(res.destinations.first.id, 'munnar');
    });
  });

  group('Phase 3: SearchDiscoveryScreen Widget Tests', () {
    testWidgets('SearchDiscoveryScreen renders search input, filter chips, and tab bar', (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'query': '',
            'total_count': 2,
            'page': 1,
            'page_size': 20,
            'has_next': false,
            'destinations': [
              {
                'id': 'munnar',
                'name': 'Munnar',
                'slug': 'munnar',
                'district': 'Idukki',
                'tagline': 'Misty Tea Hills',
                'description': 'Famous tea hills',
                'hero_image': 'https://example.com/img.jpg',
                'latitude': 10.0889,
                'longitude': 77.0595,
                'best_season': 'Sept-March',
                'tags': ['Tea'],
                'family_friendly': true,
              }
            ],
            'experiences': [
              {
                'id': 'exp_tea',
                'org_id': 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
                'destination_id': 'munnar',
                'title': 'Tea Tasting Experience',
                'category': 'CULTURE',
                'description': 'Artisanal tea tasting',
                'price_per_person': 1200.0,
                'duration_hours': 2.0,
                'hero_image': 'https://example.com/exp.jpg',
                'rating': 4.9,
                'rain_friendly': true,
              }
            ],
            'accommodations': [],
            'attractions': [],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        config: const AppConfig(environment: AppEnvironment.development, customBaseUrl: 'http://test.api/api/v1'),
        storage: InMemoryTokenStorage(),
        httpClient: mockClient,
      );

      final repo = SearchRepository(apiClient: apiClient);

      await tester.pumpWidget(
        MaterialApp(
          home: SearchDiscoveryScreen(searchRepository: repo),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Search TextField
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search destinations, stays, experiences...'), findsOneWidget);

      // Verify Filter Chips
      expect(find.text('Monsoon Safe'), findsAtLeastNWidgets(1));
      expect(find.text('Family Friendly'), findsOneWidget);
      expect(find.text('All Types'), findsOneWidget);
      expect(find.text('Radius / Hub'), findsOneWidget);

      // Verify Tabs & Section Headers
      expect(find.text('All (2)'), findsAtLeastNWidgets(1));
      expect(find.text('Destinations (1)'), findsAtLeastNWidgets(1));
      expect(find.text('Experiences (1)'), findsAtLeastNWidgets(1));

      // Verify Results rendered
      expect(find.text('Munnar'), findsOneWidget);
      expect(find.text('Tea Tasting Experience'), findsOneWidget);

      // Tap on experience card to verify detail sheet opens
      await tester.tap(find.text('Tea Tasting Experience'));
      await tester.pumpAndSettle();

      // Verify experience detail sheet rendered with details and CTA
      expect(find.text('About Experience'), findsOneWidget);
      expect(find.text('Artisanal tea tasting'), findsOneWidget);
      expect(find.text('Explore & Add to Trip'), findsOneWidget);
    });

    testWidgets('SearchDiscoveryScreen renders Load More button when hasNext is true', (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'query': '',
            'total_count': 10,
            'page': 1,
            'page_size': 2,
            'has_next': true,
            'destinations': [
              {
                'id': 'munnar',
                'name': 'Munnar',
                'slug': 'munnar',
                'district': 'Idukki',
                'tagline': 'Misty Tea Hills',
                'description': 'Famous tea hills',
                'hero_image': 'https://example.com/img.jpg',
                'latitude': 10.0889,
                'longitude': 77.0595,
                'best_season': 'Sept-March',
                'tags': ['Tea'],
                'family_friendly': true,
                'distance_km': 2.5,
              }
            ],
            'experiences': [],
            'accommodations': [],
            'attractions': [],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        config: const AppConfig(environment: AppEnvironment.development, customBaseUrl: 'http://test.api/api/v1'),
        storage: InMemoryTokenStorage(),
        httpClient: mockClient,
      );

      final repo = SearchRepository(apiClient: apiClient);

      await tester.pumpWidget(
        MaterialApp(
          home: SearchDiscoveryScreen(searchRepository: repo),
        ),
      );

      await tester.pumpAndSettle();

      // Verify distance badge
      expect(find.text('2.5 km'), findsOneWidget);

      // Verify Load More button is rendered when hasNext is true
      expect(find.text('Load More Results'), findsOneWidget);
    });
  });
}

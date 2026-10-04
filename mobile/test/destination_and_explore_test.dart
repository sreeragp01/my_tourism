import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:keralink_mobile/core/config/app_config.dart';
import 'package:keralink_mobile/core/network/api_client.dart';
import 'package:keralink_mobile/core/storage/secure_token_storage.dart';
import 'package:keralink_mobile/features/home/data/destination_repository.dart';
import 'package:keralink_mobile/features/home/models/destination_model.dart';
import 'package:keralink_mobile/features/explore/data/experience_repository.dart';
import 'package:keralink_mobile/features/explore/models/experience_model.dart';

void main() {
  const testConfig = AppConfig(
    environment: AppEnvironment.development,
    customBaseUrl: 'http://test-server/api/v1',
  );

  group('Destination Model & Repository Tests', () {
    final sampleDestJson = [
      {
        'id': 'munnar',
        'name': 'Munnar',
        'slug': 'munnar',
        'district': 'Idukki',
        'tagline': 'Misty Tea Hills',
        'description': 'Tea plantations and hills.',
        'hero_image': 'https://example.com/munnar.jpg',
        'gallery_images': ['https://example.com/g1.jpg'],
        'latitude': 10.0889,
        'longitude': 77.0595,
        'best_season': 'Sept to March',
        'tags': ['Hills', 'Tea'],
        'preferences': {'nature': 0.95},
        'family_friendly': true,
        'senior_friendly': true,
        'average_stay_days': 3,
        'attractions': [
          {
            'id': 'att_1',
            'name': 'Top Station',
            'category': 'VIEWPOINT',
            'description': 'Panoramic view',
            'image': 'https://example.com/top.jpg',
            'latitude': 10.12,
            'longitude': 77.24,
            'typical_duration_mins': 90,
            'rain_friendly': false,
          }
        ],
      },
      {
        'id': 'alleppey',
        'name': 'Alleppey',
        'slug': 'alleppey',
        'district': 'Alappuzha',
        'tagline': 'Backwaters',
        'description': 'Canals and houseboats.',
        'hero_image': 'https://example.com/alleppey.jpg',
        'gallery_images': [],
        'latitude': 9.49,
        'longitude': 76.33,
        'best_season': 'Oct to Feb',
        'tags': ['Backwaters'],
        'preferences': {'nature': 0.90},
        'family_friendly': true,
        'senior_friendly': true,
        'average_stay_days': 2,
        'attractions': [],
      }
    ];

    test('Destination.fromJson parses Django serializer payload correctly', () {
      final dest = Destination.fromJson(sampleDestJson.first);
      expect(dest.id, 'munnar');
      expect(dest.name, 'Munnar');
      expect(dest.district, 'Idukki');
      expect(dest.tags, contains('Hills'));
      expect(dest.attractions.length, 1);
      expect(dest.attractions.first.name, 'Top Station');
      expect(dest.preferences['nature'], 0.95);
    });

    test('DestinationRepository fetches destinations via ApiClient', () async {
      final storage = InMemoryTokenStorage();
      final mockClient = MockClient((request) async {
        expect(request.url.path.endsWith('/destinations/'), isTrue);
        return http.Response(jsonEncode(sampleDestJson), 200);
      });

      final apiClient = ApiClient(config: testConfig, storage: storage, httpClient: mockClient);
      final repo = DestinationRepository(apiClient: apiClient, storage: storage);

      final list = await repo.getDestinations();
      expect(list.length, 2);
      expect(list[0].name, 'Munnar');
      expect(list[1].name, 'Alleppey');

      // getDestinationBySlug
      final munnar = await repo.getDestinationBySlug('munnar');
      expect(munnar.name, 'Munnar');
    });

    test('DestinationRepository provides offline fallback on network failure', () async {
      final storage = InMemoryTokenStorage();
      final mockClient = MockClient((request) async {
        throw http.ClientException('Offline test');
      });

      final apiClient = ApiClient(config: testConfig, storage: storage, httpClient: mockClient);
      final repo = DestinationRepository(apiClient: apiClient, storage: storage);

      // Should not throw, returns calibrated offline destinations
      final list = await repo.getDestinations();
      expect(list.isNotEmpty, isTrue);
      expect(list.any((d) => d.slug == 'munnar'), isTrue);
    });
  });

  group('Experience Model & Repository Tests', () {
    final sampleExpJson = [
      {
        'id': 'exp_1',
        'org_id': 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
        'destination_id': 'munnar',
        'title': 'Lockhart Tea Tasting',
        'category': 'CULTURE',
        'description': 'Artisanal tea tasting class.',
        'price_per_person': 1200.0,
        'duration_hours': 2.5,
        'max_group_size': 8,
        'hero_image': 'https://example.com/tea.jpg',
        'included_items': ['Tea kit'],
        'meeting_point': 'Lockhart Portico',
        'host_name': 'Raman',
        'host_role': 'Planter',
        'rating': 4.95,
        'review_count': 48,
        'verified': true,
        'rain_friendly': true,
      },
      {
        'id': 'exp_2',
        'org_id': 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
        'destination_id': 'alleppey',
        'title': 'Canoe Safari',
        'category': 'WATER',
        'description': 'Open water paddle.',
        'price_per_person': 1600.0,
        'duration_hours': 3.0,
        'max_group_size': 4,
        'hero_image': 'https://example.com/canoe.jpg',
        'included_items': ['Lunch'],
        'meeting_point': 'Jetty',
        'host_name': 'Biju',
        'host_role': 'Oarsman',
        'rating': 4.98,
        'review_count': 72,
        'verified': true,
        'rain_friendly': false,
      },
    ];

    test('Experience.fromJson parses correctly', () {
      final exp = Experience.fromJson(sampleExpJson.first);
      expect(exp.id, 'exp_1');
      expect(exp.title, 'Lockhart Tea Tasting');
      expect(exp.category, 'CULTURE');
      expect(exp.pricePerPerson, 1200.0);
      expect(exp.rainFriendly, isTrue);
      expect(exp.rating, 4.95);
    });

    test('ExperienceRepository filters by destination and monsoon mode', () async {
      final storage = InMemoryTokenStorage();
      final mockClient = MockClient((request) async {
        expect(request.url.path.endsWith('/experiences/'), isTrue);
        if (request.url.queryParameters['rain_friendly'] == 'true') {
          return http.Response(jsonEncode([sampleExpJson.first]), 200);
        }
        return http.Response(jsonEncode(sampleExpJson), 200);
      });

      final apiClient = ApiClient(config: testConfig, storage: storage, httpClient: mockClient);
      final repo = ExperienceRepository(apiClient: apiClient);

      final all = await repo.getExperiences();
      expect(all.length, 2);

      final rainSafe = await repo.getExperiences(rainFriendly: true);
      expect(rainSafe.length, 1);
      expect(rainSafe.first.id, 'exp_1');
    });
  });
}

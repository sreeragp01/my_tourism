import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:keralink_mobile/features/maps/models/map_models.dart';
import 'package:keralink_mobile/features/maps/data/map_repository.dart';
import 'package:keralink_mobile/features/maps/presentation/live_map_screen.dart';
import 'package:keralink_mobile/features/maps/presentation/route_preview_screen.dart';
import 'package:keralink_mobile/features/maps/presentation/nearby_experiences_screen.dart';

import 'package:keralink_mobile/features/weather/models/weather_models.dart';
import 'package:keralink_mobile/features/weather/data/weather_repository.dart';
import 'package:keralink_mobile/features/weather/presentation/weather_radar_sheet.dart';

import 'package:keralink_mobile/features/companion/models/companion_models.dart';
import 'package:keralink_mobile/features/companion/data/companion_repository.dart';
import 'package:keralink_mobile/features/companion/presentation/live_companion_screen.dart';

import 'package:keralink_mobile/features/safety/models/safety_models.dart';
import 'package:keralink_mobile/features/safety/data/safety_repository.dart';
import 'package:keralink_mobile/features/safety/presentation/safety_hub_screen.dart';

import 'package:keralink_mobile/features/notifications/models/notification_models.dart';
import 'package:keralink_mobile/features/notifications/data/notification_repository.dart';
import 'package:keralink_mobile/features/notifications/presentation/notifications_screen.dart';
import 'package:keralink_mobile/features/notifications/presentation/proximity_banner.dart';

// ============================================================================
// MOCK REPOSITORIES
// ============================================================================
class MockWaveDMapRepository implements IMapRepository {
  int getRouteCalls = 0;
  int getNearbyCalls = 0;
  int reverseGeocodeCalls = 0;

  @override
  Future<RouteResult> getRoute({
    required double startLat,
    required double startLon,
    required double endLat,
    required double endLon,
  }) async {
    getRouteCalls++;
    return const RouteResult(
      distanceKm: 128.4,
      durationMinutes: 225,
      isGhatRoad: true,
      advisories: [
        'Ghat Fog Advisory: Maximum recommended speed 30 km/h with low-beam headlights.',
        'Monsoon hairpin bends active: Drive with extreme caution near Cheeyappara Falls.',
      ],
      polylinePoints: [],
      hairpinsCount: 14,
      summary: 'NH85 Cochin-Madurai Highway via Kothamangalam & Adimali',
    );
  }

  @override
  Future<List<NearbyPlace>> getNearby({
    required double lat,
    required double lon,
    double radiusKm = 35.0,
    String? category,
  }) async {
    getNearbyCalls++;
    final all = [
      const NearbyPlace(
        id: 'exp_lockhart_tea',
        title: 'Lockhart Estate Tea Tasting & Factory Experience',
        type: 'EXPERIENCE',
        category: 'CULTURE',
        distanceKm: 1.2,
        latitude: 10.0889,
        longitude: 77.0595,
        rainFriendly: true,
        rating: 4.95,
        pricePerPerson: 1200.0,
        meetingPoint: 'Lockhart Plantation Main Gate',
      ),
      const NearbyPlace(
        id: 'food_rapsy',
        title: 'Rapsy Restaurant - Kerala Parotta & Beef Fry',
        type: 'FOOD',
        category: 'FOOD',
        distanceKm: 1.8,
        latitude: 10.0850,
        longitude: 77.0620,
        rainFriendly: true,
        rating: 4.8,
      ),
    ];
    if (category != null && category != 'ALL') {
      return all.where((p) => p.category == category).toList();
    }
    return all;
  }

  @override
  Future<String> reverseGeocode({required double lat, required double lon}) async {
    reverseGeocodeCalls++;
    return 'Lockhart Tea Valley, Munnar';
  }
}

class MockWaveDWeatherRepository implements IWeatherRepository {
  int getCurrentWeatherCalls = 0;
  int getForecastCalls = 0;
  int validateActivityCalls = 0;

  @override
  Future<WeatherReport> getCurrentWeather(String destinationSlug) async {
    getCurrentWeatherCalls++;
    return const WeatherReport(
      destination: 'Munnar Highland Valley',
      temperatureCelsius: 19,
      condition: 'MIST_RAIN',
      rainProbabilityPercent: 75,
      recommendation: 'Ghat road speed advisory 30 km/h in effect due to mountain fog.',
      risk: MonsoonRisk(
        riskLevel: 'CAUTION',
        riskScore: 65,
        advisory: 'Moderate to heavy mountain showers. Carry rainwear and drive with low beams.',
        badgeColor: '#F59E0B',
        isGhatCorridor: true,
        rainProbabilityPercent: 75,
        monsoonModeRecommended: true,
      ),
    );
  }

  @override
  Future<List<WeatherReport>> getForecast(String destinationSlug, {int days = 3}) async {
    getForecastCalls++;
    return [];
  }

  @override
  Future<ActivityWeatherValidation> validateActivity({
    required String activityType,
    required String destinationSlug,
    required int rainProbability,
  }) async {
    validateActivityCalls++;
    return const ActivityWeatherValidation(
      activityType: 'TREKKING',
      destination: 'munnar',
      isOutdoor: true,
      rainProbability: 75,
      status: 'UNSAFE',
      requiresSubstitution: true,
      substitute: RainSubstitute(
        alternativeTitle: 'Lockhart Historic Tea Museum & Cupping Masterclass',
        category: 'CULTURE',
        rainFriendly: true,
        pricePerPerson: 1200.0,
        reason: '100% sheltered colonial stone factory masterclass.',
      ),
    );
  }
}

class MockWaveDCompanionRepository implements ICompanionRepository {
  int sendQueryCalls = 0;

  @override
  Future<CompanionMessage> sendQuery({
    required String query,
    String destinationSlug = 'munnar',
    int tripDay = 2,
    String? bookingReference,
  }) async {
    sendQueryCalls++;
    final lower = query.toLowerCase();

    if (lower.contains('driver') || lower.contains('rajesh')) {
      return const CompanionMessage(
        id: 'msg-mock-driver',
        sender: 'ai',
        text: '🚗 Dedicated Chauffeur: Rajesh Kumar (Toyota Innova Crysta, KL-07-CC-4821). Status: On Standby at Munnar Resort.',
        timestamp: 'Just now',
        toolInvoked: 'request_driver_contact',
        toolResult: {
          'driver_name': 'Rajesh Kumar',
          'phone': '+91 98470 12345',
          'vehicle_model': 'Toyota Innova Crysta (AC Premium)',
          'vehicle_number': 'KL-07-CC-4821',
          'current_status': 'Waiting at resort portico',
        },
        suggestions: ['Call Chauffeur Rajesh', 'Route preview'],
      );
    } else if (lower.contains('weather') || lower.contains('rain')) {
      return const CompanionMessage(
        id: 'msg-mock-weather',
        sender: 'ai',
        text: '🌧️ Weather in Munnar: 19°C with Mist Rain. Rain risk is 75%. Ghat speed restriction: 30 km/h.',
        timestamp: 'Just now',
        toolInvoked: 'get_weather',
        toolResult: {
          'destination': 'Munnar Hills',
          'temperature_celsius': 19,
          'condition': 'MIST_RAIN',
          'rain_probability_percent': 75,
        },
        suggestions: ['Suggest rain alternative'],
      );
    } else if (lower.contains('alternative') || lower.contains('indoor')) {
      return const CompanionMessage(
        id: 'msg-mock-rain-alt',
        sender: 'ai',
        text: '☔ Rain Alternative: Lockhart Historic Tea Museum & Factory Cupping (₹1200/person, 100% sheltered).',
        timestamp: 'Just now',
        toolInvoked: 'suggest_rain_alternative',
        toolResult: {
          'alternative_title': 'Lockhart Historic Tea Museum & Factory Cupping',
          'category': 'CULTURE',
          'price_per_person': 1200.0,
          'rain_friendly': true,
        },
        suggestions: ['Apply to Day 2'],
      );
    }

    return const CompanionMessage(
      id: 'msg-mock-general',
      sender: 'ai',
      text: '🌴 I am monitoring your journey in Munnar. Driver Rajesh is ready.',
      timestamp: 'Just now',
    );
  }
}

class MockWaveDSafetyRepository implements ISafetyRepository {
  int triggerSosCalls = 0;
  int createShareTokenCalls = 0;
  int revokeShareTokenCalls = 0;

  @override
  Future<List<EmergencyContact>> getEmergencyContacts() async {
    return const [
      EmergencyContact(
        name: 'National Emergency SOS',
        number: '112',
        tollFree: true,
        type: 'ALL_EMERGENCY',
        description: '24x7 Immediate Dispatch',
      ),
      EmergencyContact(
        name: 'Kerala Tourist Police Helpline',
        number: '1800-425-4747',
        tollFree: true,
        type: 'TOURIST_POLICE',
        description: 'Tourist Protection & Guidance',
      ),
    ];
  }

  @override
  Future<SafetyAlertResult> triggerSos({
    String? bookingReference,
    double? latitude,
    double? longitude,
    String? locationName,
    String alertType = 'SOS_112',
  }) async {
    triggerSosCalls++;
    return const SafetyAlertResult(
      alertId: 'alert-mock-uuid-1234',
      alertType: 'SOS_112',
      status: 'TRIGGERED',
      locationName: 'Lockhart Tea Valley, Munnar',
      instructions: ['Stay calm', 'Tourist Police dispatched'],
    );
  }

  @override
  Future<TripShareResult> createTripShareToken(String bookingReference, {int expiryHours = 24}) async {
    createShareTokenCalls++;
    return const TripShareResult(
      token: 'mock-share-token-xyz-1234',
      bookingReference: 'KL2609071234',
      expiresAt: '2026-10-18T10:00:00Z',
      shareUrl: '/api/v1/safety/shared/mock-share-token-xyz-1234/',
      isValid: true,
    );
  }

  @override
  Future<bool> revokeTripShareToken(String token) async {
    revokeShareTokenCalls++;
    return true;
  }

  @override
  Future<PublicSharedTrip> getPublicTripShare(String token) async {
    return const PublicSharedTrip(
      valid: true,
      tripTitle: 'Munnar & Backwater Odyssey',
      maskedReference: 'KL***1234',
    );
  }
}

class MockWaveDNotificationRepository implements INotificationRepository {
  int getNotificationsCalls = 0;
  int markAsReadCalls = 0;

  @override
  Future<List<NotificationModel>> getNotifications() async {
    getNotificationsCalls++;
    return const [
      NotificationModel(
        id: 'notif-1',
        title: 'Welcome to Lockhart Tea Factory!',
        message: 'You have arrived at Lockhart Estate (120m).',
        type: 'PROXIMITY',
        isRead: false,
        createdAt: '2 mins ago',
      ),
      NotificationModel(
        id: 'notif-2',
        title: 'Munnar Ghat Monsoon Caution',
        message: 'Dense mist and intermittent rain on NH85.',
        type: 'WEATHER_ALERT',
        isRead: false,
        createdAt: '25 mins ago',
      ),
    ];
  }

  @override
  Future<int> markAsRead({String? notificationId}) async {
    markAsReadCalls++;
    return 2;
  }

  @override
  Future<NotificationPreferences> getPreferences() async {
    return const NotificationPreferences();
  }

  @override
  Future<NotificationPreferences> updatePreferences(NotificationPreferences prefs) async {
    return prefs;
  }

  @override
  Future<ProximityCheckResult> checkProximity({
    required double latitude,
    required double longitude,
    String? bookingReference,
    List<Map<String, dynamic>>? waypoints,
  }) async {
    return const ProximityCheckResult(
      evaluatedCount: 1,
      nearestWaypointName: 'Lockhart Tea Factory Gate',
      nearestDistanceMeters: 120.0,
      triggeredEvents: [{'event_type': 'ARRIVAL_200M'}],
    );
  }
}

// ============================================================================
// MASTER TEST SUITE
// ============================================================================
void main() {
  group('Wave D — Phase 10: Maps & Location Screen Tests', () {
    testWidgets('LiveMapScreen renders Kerala corridor canvas, Ghat advisory, and telemetry', (tester) async {
      final mockMap = MockWaveDMapRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: LiveMapScreen(repository: mockMap),
        ),
      );
      await tester.pumpAndSettle();

      // Header & telemetry
      expect(find.text('Live Corridor Map'), findsOneWidget);
      expect(find.text('Lockhart Tea Valley, Munnar'), findsOneWidget);
      expect(find.text('Munnar Ghat Road Caution Active'), findsOneWidget);
      expect(find.text('Elevation: 1,532m'), findsOneWidget);

      // Buttons
      expect(find.byKey(const Key('route_preview_btn')), findsOneWidget);
      expect(find.byKey(const Key('nearby_experiences_btn')), findsOneWidget);

      // Tap GPS center button
      await tester.tap(find.byKey(const Key('refresh_map_btn')));
      await tester.pump();
      expect(find.text('GPS Centered: Lockhart Tea Valley (Accuracy ±8m)'), findsOneWidget);
    });

    testWidgets('RoutePreviewScreen renders distance, ETA, hairpin turns, and speed advisory', (tester) async {
      final mockMap = MockWaveDMapRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: RoutePreviewScreen(repository: mockMap),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Route & Transit Preview'), findsOneWidget);
      expect(find.text('128.4 km'), findsOneWidget);
      expect(find.text('3h 45m'), findsOneWidget);
      expect(find.text('14 bends'), findsOneWidget);
      expect(find.text('Highland Ghat Driving Advisories'), findsOneWidget);
      expect(find.byKey(const Key('start_navigation_btn')), findsOneWidget);

      // Tap begin navigation
      await tester.tap(find.byKey(const Key('start_navigation_btn')));
      await tester.pump();
    });

    testWidgets('NearbyExperiencesScreen renders category chips and filterable spots', (tester) async {
      final mockMap = MockWaveDMapRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: NearbyExperiencesScreen(repository: mockMap),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nearby Spots & Experiences'), findsOneWidget);
      expect(find.byKey(const Key('category_chip_ALL')), findsOneWidget);
      expect(find.byKey(const Key('category_chip_CULTURE')), findsOneWidget);
      expect(find.byKey(const Key('category_chip_FOOD')), findsOneWidget);

      // Verify tea tasting card
      expect(find.text('Lockhart Estate Tea Tasting & Factory Experience'), findsOneWidget);
      expect(find.text('Rain-Friendly'), findsWidgets);

      // Filter by FOOD
      await tester.tap(find.byKey(const Key('category_chip_FOOD')));
      await tester.pumpAndSettle();
      expect(find.text('Rapsy Restaurant - Kerala Parotta & Beef Fry'), findsOneWidget);
    });
  });

  group('Wave D — Phase 11: Weather & Monsoon Radar Tests', () {
    testWidgets('WeatherRadarSheet renders live rain meter and rain-alternative button', (tester) async {
      final mockWeather = MockWaveDWeatherRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeatherRadarSheet(repository: mockWeather),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Munnar Highland Valley'), findsOneWidget);
      expect(find.text('19°C'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
      expect(find.text('Ghat'), findsOneWidget);
      expect(find.text('Recommended Rain Alternative'), findsOneWidget);
      expect(find.byKey(const Key('apply_rain_alternative_btn')), findsOneWidget);

      await tester.tap(find.byKey(const Key('apply_rain_alternative_btn')));
      await tester.pump();
    });
  });

  group('Wave D — Phase 12: AI Travel Companion Gated Execution Tests', () {
    testWidgets('LiveCompanionScreen processes driver and weather queries via tools', (tester) async {
      final mockCompanion = MockWaveDCompanionRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: LiveCompanionScreen(repository: mockCompanion),
        ),
      );
      await tester.pumpAndSettle();

      // Welcome message
      expect(find.text('KeraLink AI Companion'), findsOneWidget);
      expect(find.byKey(const Key('suggestion_chip_Check Weather')), findsOneWidget);
      expect(find.byKey(const Key('suggestion_chip_Contact Chauffeur Rajesh')), findsOneWidget);

      // Tap Contact Chauffeur suggestion
      await tester.tap(find.byKey(const Key('suggestion_chip_Contact Chauffeur Rajesh')));
      await tester.pumpAndSettle();

      // Verify Driver Card rendered
      expect(find.byKey(const Key('tool_card_driver')), findsOneWidget);
      expect(find.text('Rajesh Kumar'), findsOneWidget);
      expect(find.byKey(const Key('call_driver_btn')), findsOneWidget);

      // Tap Call Driver
      await tester.tap(find.byKey(const Key('call_driver_btn')));
      await tester.pump();
      expect(find.text('Dialing +91 98470 12345...'), findsOneWidget);

      // Send text weather query
      await tester.enterText(find.byKey(const Key('companion_input_field')), 'What is the weather in Munnar?');
      await tester.tap(find.byKey(const Key('companion_send_btn')));
      await tester.pumpAndSettle();

      // Verify Weather Card rendered
      expect(find.byKey(const Key('tool_card_weather')), findsOneWidget);
      expect(find.text('19°C • Munnar Hills'), findsOneWidget);
    });
  });

  group('Wave D — Phase 13: Safety & Emergency SOS Tests', () {
    testWidgets('SafetyHubScreen triggers SOS confirmation dialog and manages trip share links', (tester) async {
      final mockSafety = MockWaveDSafetyRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: SafetyHubScreen(repository: mockSafety),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Safety & Emergency Hub'), findsOneWidget);
      expect(find.text('EMERGENCY SOS'), findsOneWidget);
      expect(find.byKey(const Key('trigger_sos_btn')), findsOneWidget);

      // Trigger SOS
      await tester.tap(find.byKey(const Key('trigger_sos_btn')));
      await tester.pumpAndSettle();

      // Alert Dialog
      expect(find.text('Emergency Alert Sent'), findsOneWidget);
      expect(find.byKey(const Key('call_112_btn')), findsOneWidget);

      await tester.tap(find.byKey(const Key('dismiss_sos_dialog_btn')));
      await tester.pumpAndSettle();

      // Family Trip Share Link Generation
      expect(find.byKey(const Key('generate_share_link_btn')), findsOneWidget);
      await tester.tap(find.byKey(const Key('generate_share_link_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Active Share Link'), findsOneWidget);
      expect(find.byKey(const Key('copy_share_link_btn')), findsOneWidget);
      expect(find.byKey(const Key('revoke_share_link_btn')), findsOneWidget);

      // Revoke Link
      await tester.tap(find.byKey(const Key('revoke_share_link_btn')));
      await tester.pumpAndSettle();
      expect(find.text('Trip share link has been revoked.'), findsOneWidget);
    });
  });

  group('Wave D — Phase 14: Notifications & Proximity Tests', () {
    testWidgets('NotificationsScreen renders notifications, filters, and preferences sheet', (tester) async {
      final mockNotif = MockWaveDNotificationRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: NotificationsScreen(repository: mockNotif),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Live Trip Notifications'), findsOneWidget);
      expect(find.text('Welcome to Lockhart Tea Factory!'), findsOneWidget);
      expect(find.text('Munnar Ghat Monsoon Caution'), findsOneWidget);

      // Filter by PROXIMITY
      await tester.tap(find.byKey(const Key('filter_chip_PROXIMITY')));
      await tester.pumpAndSettle();
      expect(find.text('Welcome to Lockhart Tea Factory!'), findsOneWidget);

      // Mark all read
      await tester.tap(find.byKey(const Key('mark_all_read_btn')));
      await tester.pump();
      expect(find.text('All notifications marked as read.'), findsOneWidget);

      // Open preferences sheet
      await tester.tap(find.byKey(const Key('notification_prefs_btn')));
      await tester.pumpAndSettle();
      expect(find.text('Notification Preferences'), findsOneWidget);
      expect(find.byKey(const Key('pref_proximity_switch')), findsOneWidget);
    });

    testWidgets('ProximityBanner displays arrival and triggers pass action', (tester) async {
      bool actionTapped = false;
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProximityBanner(
              waypointName: 'Lockhart Tea Factory',
              distanceMeters: 120.0,
              eventType: 'ARRIVAL_200M',
              onAction: () => actionTapped = true,
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );

      expect(find.text('Arrived at Lockhart Tea Factory'), findsOneWidget);
      expect(find.byKey(const Key('proximity_action_btn')), findsOneWidget);

      await tester.tap(find.byKey(const Key('proximity_action_btn')));
      expect(actionTapped, isTrue);

      await tester.tap(find.byKey(const Key('proximity_dismiss_btn')));
      expect(dismissed, isTrue);
    });
  });
}

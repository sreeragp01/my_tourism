import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keralink_mobile/features/ai_planner/data/ai_planner_repository.dart';
import 'package:keralink_mobile/features/ai_planner/models/itinerary_models.dart';
import 'package:keralink_mobile/features/ai_planner/presentation/ai_planner_screen.dart';
import 'package:keralink_mobile/features/ai_planner/presentation/itinerary_details_screen.dart';

class MockAIPlannerRepository implements IAIPlannerRepository {
  AIPlan? currentMockPlan;
  int versionCounter = 1;
  bool throwOnGenerate = false;

  MockAIPlannerRepository() {
    currentMockPlan = _createSamplePlan(1);
  }

  AIPlan _createSamplePlan(int version, {String? reason, bool rainFriendly = false}) {
    return AIPlan(
      planId: 'plan-uuid-mock-1234',
      version: version,
      title: 'Premium Kerala 5-Day Explorer',
      corridorRoute: const ['Munnar', 'Alleppey', 'Fort Kochi'],
      durationDays: 5,
      travelStyle: 'PREMIUM',
      changeReason: reason,
      pricing: const PricingBreakdown(
        daysCount: 5,
        travelersCount: 2,
        staysSubtotal: 18000,
        experiencesSubtotal: 12000,
        transportSubtotal: 12500,
        subtotal: 42500,
        gstRatePercent: 5.0,
        gstAmount: 2125,
        platformFeePercent: 2.0,
        platformFee: 850,
        taxesAndFees: 2975,
        discount: 0,
        total: 45475,
      ),
      validation: const ValidationReport(
        valid: true,
        errors: [],
        warnings: [],
        score: 95,
        budgetLimit: 55000,
        calculatedTotal: 45475,
      ),
      days: [
        PlanDay(
          dayNumber: 1,
          destinationId: 1,
          destinationName: 'Munnar',
          themeTitle: 'Highland Tea & Mist Trails',
          timeline: [
            TimelineEvent(
              id: 'ev_1_1',
              type: 'EXPERIENCE',
              title: rainFriendly ? 'Tea Museum & Heritage Indoor Factory' : 'Lockhart Tea Outdoor Trek',
              destinationId: 1,
              destinationName: 'Munnar',
              time: '09:00',
              startTime: '09:00',
              endTime: '12:00',
              durationMins: 180,
              price: 1200,
              rainFriendly: rainFriendly,
              bookingRequired: true,
            ),
            const TimelineEvent(
              id: 'ev_1_2',
              type: 'MEAL',
              title: 'Authentic Kerala Thali',
              destinationId: 1,
              destinationName: 'Munnar',
              time: '13:00',
              startTime: '13:00',
              endTime: '14:15',
              price: 450,
              rainFriendly: true,
              bookingRequired: false,
            ),
            const TimelineEvent(
              id: 'stay_1',
              type: 'STAY',
              title: 'Spice Tree Luxury Chalet',
              destinationId: 1,
              destinationName: 'Munnar',
              time: '21:30',
              startTime: '21:30',
              endTime: '08:00',
              durationMins: 630,
              price: 4500,
              rainFriendly: true,
              bookingRequired: true,
            ),
          ],
        ),
        const PlanDay(
          dayNumber: 2,
          destinationId: 2,
          destinationName: 'Alleppey',
          themeTitle: 'Backwater Canals & Shikara Life',
          timeline: [
            TimelineEvent(
              id: 'ev_2_1',
              type: 'EXPERIENCE',
              title: 'Covered Shikara Boat Cruise',
              destinationId: 2,
              destinationName: 'Alleppey',
              time: '10:00',
              startTime: '10:00',
              endTime: '13:00',
              durationMins: 180,
              price: 2000,
              rainFriendly: true,
              bookingRequired: true,
            ),
          ],
        ),
      ],
      createdAt: '2026-09-06T12:00:00Z',
    );
  }

  @override
  Future<TripProfile> parsePrompt(String prompt) async {
    return const TripProfile(
      budgetLimit: 55000,
      durationDays: 5,
      travelStyle: 'PREMIUM',
      interests: ['Highland Tea', 'Backwaters'],
      adults: 2,
    );
  }

  @override
  Future<AIPlan> generateItinerary({
    required double budget,
    required int duration,
    required String travelStyle,
    List<String> interests = const [],
    int adults = 2,
    int children = 0,
    String pace = 'MODERATE',
  }) async {
    if (throwOnGenerate) {
      throw Exception('Network timeout connecting to AI engine');
    }
    versionCounter = 1;
    currentMockPlan = _createSamplePlan(1);
    return currentMockPlan!;
  }

  @override
  Future<AIPlan> getPlan(String planId) async {
    return currentMockPlan!;
  }

  @override
  Future<AIPlan> substituteRain({
    required String planId,
    required int dayNumber,
    String? outdoorItemId,
  }) async {
    versionCounter++;
    currentMockPlan = _createSamplePlan(
      versionCounter,
      reason: 'Monsoon Weather Adaptation / Rain substitution',
      rainFriendly: true,
    );
    return currentMockPlan!;
  }

  @override
  Future<AIPlan> customizePlan({
    required String planId,
    required String action,
    required int dayNumber,
    String? timelineEventId,
    Map<String, dynamic>? newEvent,
    String? reason,
  }) async {
    versionCounter++;
    currentMockPlan = _createSamplePlan(
      versionCounter,
      reason: reason ?? 'Applied $action',
      rainFriendly: true,
    );
    return currentMockPlan!;
  }

  @override
  Future<List<PlanVersionSummary>> getPlanVersions(String planId) async {
    return [
      const PlanVersionSummary(
        version: 1,
        changeReason: 'Initial synthesis',
        createdAt: '2026-09-06T12:00:00Z',
        totalPrice: 45475,
      ),
      if (versionCounter >= 2)
        const PlanVersionSummary(
          version: 2,
          changeReason: 'Monsoon Weather Adaptation',
          createdAt: '2026-09-06T12:05:00Z',
          totalPrice: 45475,
        ),
    ];
  }

  @override
  Future<AIPlan> getPlanVersionDetail(String planId, int version) async {
    return _createSamplePlan(version, reason: 'Retrieved version $version');
  }
}

void main() {
  group('AI Travel Architect & Itinerary Builder Tests', () {
    late MockAIPlannerRepository mockRepo;

    setUp(() {
      mockRepo = MockAIPlannerRepository();
    });

    test('TripProfile and PricingBreakdown JSON deserialization and serialization', () {
      const json = {
        'budget_limit': 60000.0,
        'duration_days': 6,
        'travel_style': 'LUXURY',
        'interests': ['Tea', 'Backwaters'],
        'adults': 2,
        'children': 1,
        'pace': 'SLOW',
      };

      final profile = TripProfile.fromJson(json);
      expect(profile.durationDays, 6);
      expect(profile.travelStyle, 'LUXURY');
      expect(profile.budgetLimit, 60000.0);
      expect(profile.interests.length, 2);

      final serialized = profile.toJson();
      expect(serialized['budget_limit'], 60000.0);
      expect(serialized['duration_days'], 6);
    });

    test('Authoritative PricingBreakdown preserves all tax and fee lines', () {
      final pricingJson = {
        'days_count': 5,
        'travelers_count': 2,
        'stays_subtotal': 18000.0,
        'experiences_subtotal': 12000.0,
        'transport_subtotal': 12500.0,
        'subtotal': 42500.0,
        'gst_rate_percent': 5.0,
        'gst_amount': 2125.0,
        'platform_fee_percent': 2.0,
        'platform_fee': 850.0,
        'taxes_and_fees': 2975.0,
        'discount': 500.0,
        'total': 44975.0,
        'currency': 'INR',
      };

      final pricing = PricingBreakdown.fromJson(pricingJson);
      expect(pricing.subtotal, 42500.0);
      expect(pricing.gstAmount, 2125.0);
      expect(pricing.platformFee, 850.0);
      expect(pricing.total, 44975.0);
      expect(pricing.currency, 'INR');
    });

    test('TimelineEvent booking-ready fields', () {
      final eventJson = {
        'id': 'ev_test_1',
        'type': 'EXPERIENCE',
        'title': 'Kathakali Demonstration',
        'destination_id': 1,
        'destination_name': 'Kochi',
        'coordinates': {'lat': 9.9656, 'lng': 76.2421},
        'time': '18:00',
        'start_time': '18:00',
        'end_time': '19:30',
        'duration_mins': 90,
        'travel_duration_mins': 15,
        'experience_id': 101,
        'availability_required': true,
        'price': 800.0,
        'rain_friendly': true,
        'booking_required': true,
        'metadata': {'eco_score': 95},
      };

      final event = TimelineEvent.fromJson(eventJson);
      expect(event.id, 'ev_test_1');
      expect(event.type, 'EXPERIENCE');
      expect(event.lat, 9.9656);
      expect(event.lng, 76.2421);
      expect(event.price, 800.0);
      expect(event.rainFriendly, isTrue);
      expect(event.bookingRequired, isTrue);
      expect(event.availabilityRequired, isTrue);
    });

    testWidgets('AIPlannerScreen extracts intent and generates itinerary', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AIPlannerScreen(repository: mockRepo),
        ),
      );

      // Verify initial UI state
      expect(find.text('AI Travel Architect'), findsOneWidget);
      expect(find.byKey(const Key('ai_prompt_input')), findsOneWidget);
      expect(find.byKey(const Key('ai_parse_prompt_btn')), findsOneWidget);
      expect(find.byKey(const Key('ai_generate_plan_btn')), findsOneWidget);

      // Tap Extract Intent
      await tester.tap(find.byKey(const Key('ai_parse_prompt_btn')));
      await tester.pumpAndSettle();

      // Tap Generate Plan
      await tester.tap(find.byKey(const Key('ai_generate_plan_btn')));
      await tester.pumpAndSettle();

      // Verify generated itinerary card appears
      expect(find.text('Synthesized Itinerary'), findsOneWidget);
      expect(find.text('Premium Kerala 5-Day Explorer'), findsOneWidget);
      expect(find.text('₹45475'), findsOneWidget);
      expect(find.text('Score 95/100'), findsOneWidget);
      expect(find.text('Munnar'), findsWidgets);
      expect(find.byKey(const Key('ai_view_details_btn')), findsOneWidget);
    });

    testWidgets('Navigates to ItineraryDetailsScreen and executes rain substitution (v1 -> v2)', (tester) async {
      final samplePlan = mockRepo._createSamplePlan(1);

      await tester.pumpWidget(
        MaterialApp(
          home: ItineraryDetailsScreen(
            initialPlan: samplePlan,
            repository: mockRepo,
          ),
        ),
      );

      // Verify details screen elements
      expect(find.text('Premium Kerala 5-Day Explorer'), findsOneWidget);
      expect(find.text('Version v1'), findsOneWidget);
      expect(find.text('Lockhart Tea Outdoor Trek'), findsOneWidget);
      expect(find.text('Outdoor'), findsOneWidget);
      expect(find.text('Authoritative Pricing'), findsOneWidget);
      expect(find.text('DJANGO CALCULATED'), findsOneWidget);
      expect(find.text('₹45475'), findsWidgets);

      // Trigger Rain Mode substitution
      final rainBtn = find.byKey(const Key('itinerary_rain_substitute_btn'));
      expect(rainBtn, findsOneWidget);
      await tester.tap(rainBtn);
      await tester.pumpAndSettle();

      // Verify version bump to v2 with rain-adapted experience
      expect(find.text('Version v2'), findsOneWidget);
      expect(find.text('Tea Museum & Heritage Indoor Factory'), findsOneWidget);
      expect(find.text('Rain Friendly'), findsWidgets);

      // Verify Version history sheet
      final historyBtn = find.byKey(const Key('itinerary_versions_button'));
      expect(historyBtn, findsOneWidget);
      await tester.tap(historyBtn);
      await tester.pumpAndSettle();

      expect(find.text('Itinerary Versions'), findsOneWidget);
      expect(find.text('v1'), findsOneWidget);
      expect(find.text('v2'), findsOneWidget);
    });
  });
}

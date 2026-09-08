import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keralink_mobile/features/ai_planner/data/ai_planner_repository.dart';
import 'package:keralink_mobile/features/ai_planner/models/itinerary_models.dart';
import 'package:keralink_mobile/features/ai_planner/presentation/ai_planner_screen.dart';
import 'package:keralink_mobile/features/ai_planner/presentation/itinerary_builder_screen.dart';

class MockBuilderRepository implements IAIPlannerRepository {
  AIPlan currentPlan;
  int versionCounter = 1;
  String? lastOperation;
  Map<String, dynamic> lastParams = {};
  List<PlanVersionSummary> versions = [];

  MockBuilderRepository() : currentPlan = _createInitialPlan(1) {
    versions = [
      PlanVersionSummary(
        version: 1,
        changeReason: 'Initial synthesis',
        createdAt: '2026-09-07T12:00:00Z',
        totalPrice: currentPlan.pricing.total,
        validationStatus: 'VALID',
      ),
    ];
  }

  static AIPlan _createInitialPlan(int version, {String? reason, bool rainSubstituted = false}) {
    return AIPlan(
      planId: 'plan-builder-mock-1',
      version: version,
      validationStatus: 'VALID',
      title: 'Munnar & Alleppey Cultural Odyssey',
      corridorRoute: const ['Munnar', 'Alleppey'],
      durationDays: 2,
      travelStyle: 'PREMIUM',
      changeReason: reason ?? 'Initial synthesis',
      pricing: const PricingBreakdown(
        daysCount: 2,
        travelersCount: 2,
        staysSubtotal: 8000,
        experiencesSubtotal: 4500,
        transportSubtotal: 5000,
        subtotal: 17500,
        gstRatePercent: 5.0,
        gstAmount: 875,
        platformFeePercent: 2.0,
        platformFee: 350,
        taxesAndFees: 1225,
        discount: 0,
        total: 18725,
      ),
      validation: const ValidationReport(
        valid: true,
        errors: [],
        warnings: [],
        score: 96,
        budgetLimit: 30000,
        calculatedTotal: 18725,
      ),
      days: [
        PlanDay(
          dayNumber: 1,
          destinationId: 1,
          destinationName: 'Munnar',
          themeTitle: 'Tea Trails & High Mountain Mist',
          timeline: [
            TimelineEvent(
              id: 'ev_1_1',
              order: 1,
              type: 'EXPERIENCE',
              entityType: 'EXPERIENCE',
              entityId: 10,
              title: rainSubstituted
                  ? 'Indoor Tea Heritage Processing & Tasting'
                  : 'Lockhart Tea Outdoor Estate Trek',
              destinationId: 1,
              destinationName: 'Munnar',
              time: '09:00',
              startTime: '09:00',
              endTime: '12:00',
              durationMins: 180,
              price: 1200,
              rainFriendly: rainSubstituted,
              bookingRequired: true,
            ),
            const TimelineEvent(
              id: 'ev_1_2',
              order: 2,
              type: 'MEAL',
              title: 'Traditional Banana Leaf Sadya',
              destinationId: 1,
              destinationName: 'Munnar',
              time: '12:30',
              startTime: '12:30',
              endTime: '13:30',
              durationMins: 60,
              price: 450,
              rainFriendly: true,
            ),
            const TimelineEvent(
              id: 'ev_1_3',
              order: 3,
              type: 'ATTRACTION',
              entityType: 'ATTRACTION',
              entityId: 20,
              title: 'Mattupetty Dam Viewpoint',
              destinationId: 1,
              destinationName: 'Munnar',
              time: '14:30',
              startTime: '14:30',
              endTime: '16:00',
              durationMins: 90,
              price: 200,
              rainFriendly: false,
            ),
          ],
        ),
        const PlanDay(
          dayNumber: 2,
          destinationId: 2,
          destinationName: 'Alleppey',
          themeTitle: 'Quiet Canals & Shikara Life',
          timeline: [
            TimelineEvent(
              id: 'ev_2_1',
              order: 1,
              type: 'EXPERIENCE',
              entityType: 'EXPERIENCE',
              entityId: 30,
              title: 'Covered Shikara Boat Cruise',
              destinationId: 2,
              destinationName: 'Alleppey',
              time: '10:00',
              startTime: '10:00',
              endTime: '13:00',
              durationMins: 180,
              price: 2500,
              rainFriendly: true,
            ),
          ],
        ),
      ],
      createdAt: '2026-09-07T12:00:00Z',
    );
  }

  @override
  Future<TripProfile> parsePrompt(String prompt) async {
    return const TripProfile(
      budgetLimit: 30000,
      durationDays: 2,
      travelStyle: 'PREMIUM',
      interests: ['Tea', 'Backwaters'],
    );
  }

  @override
  Future<AIPlan> generateItinerary({
    required double budget,
    required int duration,
    required String travelStyle,
    String month = 'October',
    bool monsoonMode = false,
    List<String> interests = const [],
    int adults = 2,
    int children = 0,
    String pace = 'MODERATE',
  }) async {
    return currentPlan;
  }

  @override
  Future<AIPlan> getPlan(String planId) async => currentPlan;

  @override
  Future<AIPlan> substituteRain({
    required String planId,
    required int dayNumber,
    String? outdoorItemId,
  }) async {
    return customizePlan(
      planId: planId,
      operation: 'RAIN_SUBSTITUTE',
      dayNumber: dayNumber,
      eventId: outdoorItemId,
    );
  }

  @override
  Future<AIPlan> customizePlan({
    required String planId,
    String? operation,
    String? action,
    int? dayNumber,
    String? timelineEventId,
    String? eventId,
    int? targetDay,
    int? targetOrder,
    String? swapWithEventId,
    String? entityType,
    dynamic entityId,
    Map<String, dynamic>? newEvent,
    String? reason,
  }) async {
    lastOperation = operation ?? action;
    lastParams = {
      'dayNumber': dayNumber,
      'eventId': eventId ?? timelineEventId,
      'targetDay': targetDay,
      'targetOrder': targetOrder,
      'swapWithEventId': swapWithEventId,
      'entityType': entityType,
      'entityId': entityId,
      'reason': reason,
    };

    versionCounter++;
    final bool isRain = (operation ?? action) == 'RAIN_SUBSTITUTE';

    currentPlan = _createInitialPlan(
      versionCounter,
      reason: reason ?? 'Customized via ${operation ?? action}',
      rainSubstituted: isRain,
    );

    versions.add(PlanVersionSummary(
      version: versionCounter,
      changeReason: currentPlan.changeReason ?? 'Updated plan',
      createdAt: DateTime.now().toIso8601String(),
      totalPrice: currentPlan.pricing.total,
      validationStatus: 'VALID',
    ));

    return currentPlan;
  }

  @override
  Future<List<PlanVersionSummary>> getPlanVersions(String planId) async => versions;

  @override
  Future<AIPlan> getPlanVersionDetail(String planId, int version) async {
    return _createInitialPlan(version, reason: 'Retrieved version $version');
  }

  @override
  Future<ItineraryDiff> getPlanDiff(String planId, {int? fromVersion, int? toVersion}) async {
    return ItineraryDiff(
      fromVersion: fromVersion ?? 1,
      toVersion: toVersion ?? versionCounter,
      added: [
        const DiffItem(eventId: 'cand_1', title: 'Added Pothamedu Sunset', day: 1),
      ],
      removed: const [
        DiffItem(eventId: 'ev_1_2', title: 'Traditional Banana Leaf Sadya', day: 1),
      ],
      moved: const [
        DiffItem(eventId: 'ev_1_1', title: 'Lockhart Tea Trek', fromOrder: 1, toOrder: 2),
      ],
      priceDifference: 450.0,
      distanceDifference: 4.2,
      monsoonCompliant: true,
      summaryText: 'Changes verified: +₹450, +4.2 km',
    );
  }

  @override
  Future<AIPlan> revertPlan(String planId, int targetVersion, {String? reason}) async {
    versionCounter++;
    currentPlan = _createInitialPlan(
      versionCounter,
      reason: reason ?? 'Reverted to v$targetVersion',
    );
    versions.add(PlanVersionSummary(
      version: versionCounter,
      changeReason: currentPlan.changeReason!,
      createdAt: DateTime.now().toIso8601String(),
      totalPrice: currentPlan.pricing.total,
      validationStatus: 'VALID',
    ));
    return currentPlan;
  }

  @override
  Future<List<PlanCandidate>> getCandidates(
    String planId,
    int dayNumber, {
    String? entityType,
    bool rainFriendlyOnly = false,
  }) async {
    return const [
      PlanCandidate(
        id: 101,
        title: 'Tea Tasting & Factory Masterclass',
        entityType: 'EXPERIENCE',
        price: 750,
        rainFriendly: true,
        destinationName: 'Munnar',
        rating: 4.8,
        durationMins: 90,
      ),
      PlanCandidate(
        id: 102,
        title: 'Attukad Waterfalls Viewpoint Trek',
        entityType: 'EXPERIENCE',
        price: 600,
        rainFriendly: false,
        destinationName: 'Munnar',
        rating: 4.7,
        durationMins: 120,
      ),
    ];
  }
}

void main() {
  group('Phase 5 — Itinerary Builder Mobile Tests', () {
    late MockBuilderRepository repository;

    setUp(() {
      repository = MockBuilderRepository();
    });

    testWidgets('AIPlannerScreen navigates to ItineraryBuilderScreen via "Open Day-by-Day Itinerary Builder"', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AIPlannerScreen(repository: repository),
        ),
      );

      // Generate Itinerary
      await tester.tap(find.byKey(const Key('ai_generate_plan_btn')));
      await tester.pumpAndSettle();

      // Check button text matches Phase 5 requirement
      final openBuilderBtn = find.text('Open Day-by-Day Itinerary Builder');
      expect(openBuilderBtn, findsOneWidget);
      await tester.ensureVisible(openBuilderBtn);
      await tester.pumpAndSettle();

      // Tap button to navigate to builder
      await tester.tap(openBuilderBtn);
      await tester.pumpAndSettle();

      // Verify ItineraryBuilderScreen is displayed
      expect(find.text('Itinerary Builder'), findsOneWidget);
      expect(find.byKey(const Key('builder_version_badge')), findsOneWidget);
      expect(find.text('v1'), findsWidgets);
      expect(find.text('VALID'), findsOneWidget);
    });

    testWidgets('ItineraryBuilderScreen renders summary header, corridor, and day tabs', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ItineraryBuilderScreen(
            initialPlan: repository.currentPlan,
            repository: repository,
          ),
        ),
      );

      // Verify header & corridor
      expect(find.text('Itinerary Builder'), findsOneWidget);
      expect(find.text('Munnar & Alleppey Cultural Odyssey'), findsOneWidget);
      expect(find.byKey(const Key('builder_total_price')), findsOneWidget);
      expect(find.text('₹18725'), findsOneWidget);

      // Verify day selector tabs
      expect(find.byKey(const Key('builder_day_tab_1')), findsOneWidget);
      expect(find.byKey(const Key('builder_day_tab_2')), findsOneWidget);

      // Verify Day 1 details
      expect(find.text('Munnar'), findsWidgets);
      expect(find.text('Tea Trails & High Mountain Mist'), findsOneWidget);
      expect(find.text('#1'), findsOneWidget);
      expect(find.text('Lockhart Tea Outdoor Estate Trek'), findsOneWidget);
      expect(find.text('#2'), findsOneWidget);
      expect(find.text('Traditional Banana Leaf Sadya'), findsOneWidget);
      expect(find.text('#3'), findsOneWidget);
      expect(find.text('Mattupetty Dam Viewpoint'), findsOneWidget);
    });

    testWidgets('Switching day tabs renders Day 2 content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ItineraryBuilderScreen(
            initialPlan: repository.currentPlan,
            repository: repository,
          ),
        ),
      );

      // Tap Day 2 Tab
      await tester.tap(find.byKey(const Key('builder_day_tab_2')));
      await tester.pumpAndSettle();

      // Verify Day 2 destination and events
      expect(find.text('Alleppey'), findsWidgets);
      expect(find.text('Quiet Canals & Shikara Life'), findsOneWidget);
      expect(find.text('Covered Shikara Boat Cruise'), findsOneWidget);
    });

    testWidgets('Move down button invokes MOVE_EVENT operation and creates v2', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ItineraryBuilderScreen(
            initialPlan: repository.currentPlan,
            repository: repository,
          ),
        ),
      );

      // Find move down button for first event
      final moveDownBtn = find.byKey(const Key('move_down_ev_1_1'));
      expect(moveDownBtn, findsOneWidget);

      // Tap move down
      await tester.tap(moveDownBtn);
      await tester.pumpAndSettle();

      // Verify repository received MOVE_EVENT
      expect(repository.lastOperation, 'MOVE_EVENT');
      expect(repository.lastParams['eventId'], 'ev_1_1');
      expect(repository.lastParams['targetOrder'], 2);

      // Verify version badge incremented to v2
      expect(find.text('v2'), findsWidgets);
    });

    testWidgets('Remove button opens confirmation dialog, confirms and invokes REMOVE_EVENT', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ItineraryBuilderScreen(
            initialPlan: repository.currentPlan,
            repository: repository,
          ),
        ),
      );

      // Find remove button for second event
      final removeBtn = find.byKey(const Key('remove_ev_1_2'));
      expect(removeBtn, findsOneWidget);

      // Tap remove
      await tester.tap(removeBtn);
      await tester.pumpAndSettle();

      // Verify dialog appears
      expect(find.text('Remove Event?'), findsOneWidget);

      // Tap confirm remove
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      // Verify repository received REMOVE_EVENT
      expect(repository.lastOperation, 'REMOVE_EVENT');
      expect(repository.lastParams['eventId'], 'ev_1_2');
      expect(find.text('v2'), findsWidgets);
    });

    testWidgets('Swap button opens swap picker and invokes SWAP_EVENT', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ItineraryBuilderScreen(
            initialPlan: repository.currentPlan,
            repository: repository,
          ),
        ),
      );

      // Tap swap on event 1
      final swapBtn = find.byKey(const Key('swap_ev_1_1'));
      expect(swapBtn, findsOneWidget);
      await tester.tap(swapBtn);
      await tester.pumpAndSettle();

      // Verify bottom sheet appears with other events
      expect(find.text('Swap "Lockhart Tea Outdoor Estate Trek" with:'), findsOneWidget);
      expect(find.text('Traditional Banana Leaf Sadya'), findsWidgets);

      // Tap event to swap with in bottom sheet
      await tester.tap(find.text('Traditional Banana Leaf Sadya').last);
      await tester.pumpAndSettle();

      // Verify repository received SWAP_EVENT
      expect(repository.lastOperation, 'SWAP_EVENT');
      expect(repository.lastParams['eventId'], 'ev_1_1');
      expect(repository.lastParams['swapWithEventId'], 'ev_1_2');
      expect(find.text('v2'), findsWidgets);
    });

    testWidgets('Rain alternative button triggers RAIN_SUBSTITUTE operation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ItineraryBuilderScreen(
            initialPlan: repository.currentPlan,
            repository: repository,
          ),
        ),
      );

      // Event 1 is outdoor, so rain button should be present
      final rainBtn = find.byKey(const Key('rain_sub_ev_1_1'));
      expect(rainBtn, findsOneWidget);

      await tester.tap(rainBtn);
      await tester.pumpAndSettle();

      // Verify repository received RAIN_SUBSTITUTE
      expect(repository.lastOperation, 'RAIN_SUBSTITUTE');
      expect(repository.lastParams['eventId'], 'ev_1_1');
      expect(find.text('Indoor Tea Heritage Processing & Tasting'), findsOneWidget);
      expect(find.text('v2'), findsWidgets);
    });

    testWidgets('Add experience button opens candidate picker and invokes ADD_EVENT', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ItineraryBuilderScreen(
            initialPlan: repository.currentPlan,
            repository: repository,
          ),
        ),
      );

      // Tap Add Experience button
      final addBtn = find.byKey(const Key('builder_add_event_btn'));
      expect(addBtn, findsOneWidget);
      await tester.ensureVisible(addBtn);
      await tester.pumpAndSettle();

      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      // Verify candidate picker sheet appears
      expect(find.text('Add Verified Experience'), findsOneWidget);
      expect(find.text('Tea Tasting & Factory Masterclass'), findsOneWidget);

      // Tap "Add" on candidate 101
      final candAddBtn = find.byKey(const Key('candidate_add_btn_101'));
      expect(candAddBtn, findsOneWidget);
      await tester.tap(candAddBtn);
      await tester.pumpAndSettle();

      // Verify repository received ADD_EVENT
      expect(repository.lastOperation, 'ADD_EVENT');
      expect(repository.lastParams['entityId'], 101);
      expect(repository.lastParams['entityType'], 'EXPERIENCE');
      expect(find.text('v2'), findsWidgets);
    });

    testWidgets('Diff button opens version diff modal with delta information', (tester) async {
      // First create a v2
      await repository.customizePlan(
        planId: repository.currentPlan.planId,
        operation: 'MOVE_EVENT',
        dayNumber: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ItineraryBuilderScreen(
            initialPlan: repository.currentPlan,
            repository: repository,
          ),
        ),
      );

      // Tap Diff button in AppBar
      final diffBtn = find.byKey(const Key('builder_diff_btn'));
      expect(diffBtn, findsOneWidget);
      await tester.tap(diffBtn);
      await tester.pumpAndSettle();

      // Verify Diff Modal contents
      expect(find.text('Version Diff (v1 → v2)'), findsOneWidget);
      expect(find.text('Changes verified: +₹450, +4.2 km'), findsOneWidget);
      expect(find.text('Price Delta: +₹450'), findsOneWidget);
      expect(find.text('Monsoon Compliant'), findsOneWidget);
      expect(find.text('Added Events (+):'), findsOneWidget);
      expect(find.text('• Day 1: Added Pothamedu Sunset'), findsOneWidget);
      expect(find.text('Removed Events (-):'), findsOneWidget);
      expect(find.text('• Day 1: Traditional Banana Leaf Sadya'), findsOneWidget);
    });

    testWidgets('Version History button opens sheet and executes rollback / revert', (tester) async {
      // Create v2 and v3
      await repository.customizePlan(
        planId: repository.currentPlan.planId,
        operation: 'MOVE_EVENT',
        reason: 'Moved event 1',
      );
      await repository.customizePlan(
        planId: repository.currentPlan.planId,
        operation: 'REMOVE_EVENT',
        reason: 'Removed event 2',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ItineraryBuilderScreen(
            initialPlan: repository.currentPlan,
            repository: repository,
          ),
        ),
      );

      // Current is v3
      expect(find.text('v3'), findsWidgets);

      // Tap history button
      final historyBtn = find.byKey(const Key('builder_history_btn'));
      expect(historyBtn, findsOneWidget);
      await tester.tap(historyBtn);
      await tester.pumpAndSettle();

      // Verify versions sheet
      expect(find.text('Itinerary Version History'), findsOneWidget);
      expect(find.text('v1'), findsOneWidget);
      expect(find.text('v2'), findsOneWidget);
      expect(find.text('v3'), findsWidgets);

      // Revert to v1
      final revertBtnV1 = find.byKey(const Key('revert_btn_v1'));
      expect(revertBtnV1, findsOneWidget);
      await tester.tap(revertBtnV1);
      await tester.pumpAndSettle();

      // Verify revert created new version v4 which restored v1 state
      expect(find.text('v4'), findsWidgets);
    });
  });
}

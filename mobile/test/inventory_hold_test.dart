import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keralink_mobile/features/ai_planner/models/itinerary_models.dart';
import 'package:keralink_mobile/features/ai_planner/presentation/itinerary_builder_screen.dart';
import 'package:keralink_mobile/features/inventory/data/inventory_repository.dart';
import 'package:keralink_mobile/features/inventory/models/inventory_hold_models.dart';
import 'package:keralink_mobile/features/inventory/presentation/inventory_hold_sheet.dart';

import 'itinerary_builder_test.dart' show MockBuilderRepository;

class MockInventoryRepository implements IInventoryRepository {
  int checkAvailabilityCalls = 0;
  int createHoldCalls = 0;
  int holdItineraryCalls = 0;
  int extendHoldCalls = 0;
  int releaseHoldCalls = 0;

  bool shouldFailHold = false;
  String? lastExtendedHoldId;
  String? lastReleasedHoldId;

  @override
  Future<InventoryAvailability> checkAvailability(
    String inventoryType,
    String inventoryId, {
    String? date,
    int quantity = 1,
  }) async {
    checkAvailabilityCalls++;
    return InventoryAvailability(
      inventoryType: inventoryType,
      inventoryId: inventoryId,
      totalCapacity: 10,
      bookedCapacity: 4,
      heldCapacity: 1,
      availableCapacity: 5,
      isAvailable: true,
    );
  }

  @override
  Future<InventoryHold> createHold(
    String inventoryType,
    String inventoryId, {
    String? date,
    int quantity = 1,
    String? itineraryVersionId,
    int durationMins = 15,
  }) async {
    createHoldCalls++;
    return InventoryHold(
      id: 'hold-single-1',
      inventoryType: inventoryType,
      inventoryId: inventoryId,
      quantity: quantity,
      status: 'ACTIVE',
      expiresAt: DateTime.now().add(Duration(minutes: durationMins)),
      remainingSeconds: durationMins * 60,
      isValid: true,
    );
  }

  @override
  Future<InventoryHold> getHold(String holdId) async {
    return InventoryHold(
      id: holdId,
      inventoryType: 'ROOM',
      inventoryId: 'room_deluxe_chalet',
      quantity: 1,
      status: 'ACTIVE',
      expiresAt: DateTime.now().add(const Duration(minutes: 15)),
      remainingSeconds: 900,
      isValid: true,
    );
  }

  @override
  Future<InventoryHold> extendHold(String holdId, {int extraMinutes = 10}) async {
    extendHoldCalls++;
    lastExtendedHoldId = holdId;
    return InventoryHold(
      id: holdId,
      inventoryType: 'ROOM',
      inventoryId: 'room_deluxe_chalet',
      quantity: 1,
      status: 'ACTIVE',
      expiresAt: DateTime.now().add(Duration(minutes: 15 + extraMinutes)),
      remainingSeconds: (15 + extraMinutes) * 60,
      isValid: true,
    );
  }

  @override
  Future<InventoryHold> releaseHold(String holdId) async {
    releaseHoldCalls++;
    lastReleasedHoldId = holdId;
    return InventoryHold(
      id: holdId,
      inventoryType: 'ROOM',
      inventoryId: 'room_deluxe_chalet',
      quantity: 1,
      status: 'RELEASED',
      expiresAt: DateTime.now(),
      remainingSeconds: 0,
      isValid: false,
    );
  }

  @override
  Future<ItineraryHoldResult> holdItinerary({
    required List<Map<String, dynamic>> items,
    String? itineraryVersionId,
    int durationMins = 15,
  }) async {
    holdItineraryCalls++;
    if (shouldFailHold) {
      return const ItineraryHoldResult(
        isSuccess: false,
        totalHeld: 0,
        holds: [],
        status: 'FAILED',
        errorMessage: 'Selected room is sold out for the requested date.',
      );
    }

    final holds = items.asMap().entries.map((e) {
      return InventoryHold(
        id: 'hold-${e.key + 1}',
        inventoryType: e.value['inventory_type'] as String,
        inventoryId: e.value['inventory_id'] as String,
        quantity: (e.value['quantity'] as num?)?.toInt() ?? 1,
        status: 'ACTIVE',
        expiresAt: DateTime.now().add(Duration(minutes: durationMins)),
        remainingSeconds: durationMins * 60,
        isValid: true,
      );
    }).toList();

    return ItineraryHoldResult(
      isSuccess: true,
      totalHeld: holds.length,
      holds: holds,
      status: 'ALL_HELD',
    );
  }
}

AIPlan _createTestPlan() {
  return const AIPlan(
    planId: 'plan-hold-test-1',
    version: 1,
    validationStatus: 'VALID',
    title: 'Munnar & Alleppey Luxury Holiday',
    corridorRoute: ['Munnar', 'Alleppey'],
    durationDays: 2,
    travelStyle: 'PREMIUM',
    createdAt: '2026-09-07T12:00:00Z',
    pricing: PricingBreakdown(
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
    validation: ValidationReport(
      valid: true,
      errors: [],
      warnings: [],
      score: 95,
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
            id: 'ev_hold_1',
            order: 1,
            type: 'EXPERIENCE',
            entityType: 'EXPERIENCE',
            entityId: 10,
            experienceId: 10,
            title: 'Kolukkumalai Sunrise Tea Trek',
            destinationId: 1,
            destinationName: 'Munnar',
            time: '06:00',
            startTime: '06:00',
            endTime: '09:00',
            durationMins: 180,
            price: 1500,
            rainFriendly: false,
            bookingRequired: true,
          ),
          TimelineEvent(
            id: 'ev_hold_2',
            order: 2,
            type: 'STAY',
            entityType: 'STAY',
            entityId: 101,
            accommodationId: 101,
            title: 'Munnar Tea Estate Heritage Villa',
            destinationId: 1,
            destinationName: 'Munnar',
            time: '14:00',
            startTime: '14:00',
            endTime: '15:00',
            durationMins: 60,
            price: 5500,
            rainFriendly: true,
            bookingRequired: true,
          ),
        ],
      ),
    ],
  );
}

void main() {
  group('Inventory Hold Models Serialization', () {
    test('InventoryAvailability.fromJson parses correctly', () {
      final json = {
        'inventory_type': 'ROOM',
        'inventory_id': 'room_deluxe_chalet',
        'total_capacity': 8,
        'booked_capacity': 3,
        'held_capacity': 2,
        'available_capacity': 3,
        'is_available': true,
        'unit_type': 'Room',
      };

      final avail = InventoryAvailability.fromJson(json);
      expect(avail.inventoryType, 'ROOM');
      expect(avail.inventoryId, 'room_deluxe_chalet');
      expect(avail.totalCapacity, 8);
      expect(avail.bookedCapacity, 3);
      expect(avail.heldCapacity, 2);
      expect(avail.availableCapacity, 3);
      expect(avail.isAvailable, true);
    });

    test('InventoryHold.fromJson parses correctly', () {
      final now = DateTime.now().toUtc();
      final json = {
        'id': 'hold-uuid-1234',
        'inventory_type': 'EXPERIENCE',
        'inventory_id': 'exp_bamboo_rafting',
        'quantity': 2,
        'status': 'ACTIVE',
        'expires_at': now.toIso8601String(),
        'remaining_seconds': 890,
      };

      final hold = InventoryHold.fromJson(json);
      expect(hold.id, 'hold-uuid-1234');
      expect(hold.inventoryType, 'EXPERIENCE');
      expect(hold.inventoryId, 'exp_bamboo_rafting');
      expect(hold.quantity, 2);
      expect(hold.status, 'ACTIVE');
      expect(hold.remainingSeconds, 890);
    });

    test('ItineraryHoldResult.fromJson parses batch results', () {
      final json = {
        'success': true,
        'total_held': 2,
        'holds': [
          {
            'id': 'hold-1',
            'inventory_type': 'ROOM',
            'inventory_id': 'room_1',
            'quantity': 1,
            'status': 'ACTIVE',
            'expires_at': DateTime.now().toIso8601String(),
            'remaining_seconds': 900,
          },
        ],
      };

      final result = ItineraryHoldResult.fromJson(json);
      expect(result.isSuccess, true);
      expect(result.totalHeld, 2);
      expect(result.holds.length, 1);
      expect(result.holds.first.id, 'hold-1');
    });
  });

  group('InventoryHoldSheet Widget Tests', () {
    late MockInventoryRepository mockRepo;
    late AIPlan testPlan;

    setUp(() {
      mockRepo = MockInventoryRepository();
      testPlan = _createTestPlan();
    });

    testWidgets('Displays bookable components and checks live availability', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InventoryHoldSheet(
              plan: testPlan,
              repository: mockRepo,
            ),
          ),
        ),
      );

      // Verify header
      expect(find.text('Authoritative Live Availability'), findsOneWidget);
      expect(find.textContaining('Munnar & Alleppey Luxury Holiday'), findsOneWidget);

      await tester.pumpAndSettle();

      // Check that availability calls were made for both components (experience and stay)
      expect(mockRepo.checkAvailabilityCalls, 2);

      // Verify components rendered
      expect(find.text('Kolukkumalai Sunrise Tea Trek'), findsOneWidget);
      expect(find.text('Munnar Tea Estate Heritage Villa'), findsOneWidget);
      expect(find.byKey(const Key('inventory_hold_all_btn')), findsOneWidget);
    });

    testWidgets('Tapping Hold All Components triggers batch hold and starts countdown', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InventoryHoldSheet(
              plan: testPlan,
              repository: mockRepo,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final holdButton = find.byKey(const Key('inventory_hold_all_btn'));
      expect(holdButton, findsOneWidget);

      await tester.tap(holdButton);
      await tester.pumpAndSettle();

      // Verify holdItinerary was invoked
      expect(mockRepo.holdItineraryCalls, 1);

      // Verify active hold banner and timer are displayed
      expect(find.byKey(const Key('active_hold_banner')), findsOneWidget);
      expect(find.text('INVENTORY LOCKED FOR YOU'), findsOneWidget);
      expect(find.byKey(const Key('inventory_countdown_timer')), findsOneWidget);
      expect(find.textContaining('Expires in 15:00'), findsOneWidget);

      // Verify proceed to booking button is visible
      expect(find.byKey(const Key('inventory_proceed_booking_btn')), findsOneWidget);
    });

    testWidgets('Tapping Extend Hold button calls repository and adds 10 minutes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InventoryHoldSheet(
              plan: testPlan,
              repository: mockRepo,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // First hold all
      await tester.tap(find.byKey(const Key('inventory_hold_all_btn')));
      await tester.pumpAndSettle();

      // Tap extend button
      final extendBtn = find.byKey(const Key('inventory_extend_hold_btn'));
      expect(extendBtn, findsOneWidget);

      await tester.tap(extendBtn);
      await tester.pumpAndSettle();

      expect(mockRepo.extendHoldCalls, 1);
      expect(mockRepo.lastExtendedHoldId, 'hold-1');
      expect(find.textContaining('Expires in 25:00'), findsOneWidget);
    });

    testWidgets('Tapping Release Hold button releases locks and resets sheet', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InventoryHoldSheet(
              plan: testPlan,
              repository: mockRepo,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Hold all
      await tester.tap(find.byKey(const Key('inventory_hold_all_btn')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('active_hold_banner')), findsOneWidget);

      // Tap release
      final releaseBtn = find.byKey(const Key('inventory_release_hold_btn'));
      expect(releaseBtn, findsOneWidget);

      await tester.tap(releaseBtn);
      await tester.pumpAndSettle();

      expect(mockRepo.releaseHoldCalls, 2); // 2 components held
      expect(find.byKey(const Key('active_hold_banner')), findsNothing);
      expect(find.byKey(const Key('inventory_hold_all_btn')), findsOneWidget);
    });
  });

  group('ItineraryBuilderScreen Inventory Hold Integration', () {
    testWidgets('Builder screen renders Check Availability & Hold button and opens sheet', (tester) async {
      final mockPlanner = MockBuilderRepository();
      final mockInv = MockInventoryRepository();
      final testPlan = _createTestPlan();

      await tester.pumpWidget(
        MaterialApp(
          home: ItineraryBuilderScreen(
            initialPlan: testPlan,
            repository: mockPlanner,
            inventoryRepository: mockInv,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the CTA button is rendered
      final checkAvailBtn = find.byKey(const Key('builder_check_availability_btn'));
      expect(checkAvailBtn, findsOneWidget);
      expect(find.text('Check Availability & Hold (15 Mins)'), findsOneWidget);

      // Scroll into view and tap the button to open the modal bottom sheet
      await tester.ensureVisible(checkAvailBtn);
      await tester.pumpAndSettle();
      await tester.tap(checkAvailBtn);
      await tester.pumpAndSettle();

      // Verify the sheet is now presented
      expect(find.text('Authoritative Live Availability'), findsOneWidget);
      expect(find.byKey(const Key('inventory_hold_all_btn')), findsOneWidget);
    });
  });
}

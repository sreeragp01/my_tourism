import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keralink_mobile/features/ai_planner/models/itinerary_models.dart';
import 'package:keralink_mobile/features/inventory/data/inventory_repository.dart';
import 'package:keralink_mobile/features/inventory/models/inventory_hold_models.dart';
import 'package:keralink_mobile/features/inventory/presentation/inventory_hold_sheet.dart';
import 'package:keralink_mobile/features/trips/data/trips_repository.dart';
import 'package:keralink_mobile/features/trips/models/trip_models.dart';
import 'package:keralink_mobile/features/trips/presentation/booking_checkout_sheet.dart';
import 'package:keralink_mobile/features/trips/presentation/my_trips_screen.dart';
import 'package:keralink_mobile/features/trips/presentation/trip_detail_screen.dart';

class MockWaveCTripsRepository implements ITripsRepository {
  int createBookingCalls = 0;
  int createPaymentOrderCalls = 0;
  int verifyPaymentCalls = 0;
  int getUserTripsCalls = 0;
  int getTripDetailCalls = 0;

  List<TripSummary> mockTrips = [];

  MockWaveCTripsRepository() {
    mockTrips = [
      const TripSummary(
        id: 'bkg-uuid-1',
        bookingReference: 'KL2609071234',
        tripTitle: 'Munnar & Alleppey Cultural Odyssey',
        startDate: '2026-10-15',
        endDate: '2026-10-17',
        travelersCount: 2,
        status: 'CONFIRMED',
        totalAmount: 18725.0,
        currency: 'INR',
        digitalPassToken: 'KL-PASS-KL2609071234-A1B2C3D4',
        greenTripScore: 92,
        itemsCount: 2,
        corridor: 'Kochi → Munnar → Alappuzha',
      ),
    ];
  }

  @override
  Future<Map<String, dynamic>> createBookingFromHolds({
    required List<String> holdIds,
    required String primaryGuestName,
    required String primaryGuestPhone,
    required String primaryGuestEmail,
    required String idempotencyKey,
    String? tripTitle,
    int travelersCount = 2,
    String? itineraryVersionId,
  }) async {
    createBookingCalls++;
    return {
      'id': 'bkg-new-uuid',
      'booking_reference': 'KL2609079999',
      'status': 'PENDING_PAYMENT',
      'subtotal': 17500.0,
      'tax': 875.0,
      'platform_fee': 350.0,
      'total_amount': 18725.0,
    };
  }

  @override
  Future<PaymentOrderResult> createPaymentOrder({
    required String bookingId,
    required String idempotencyKey,
    String gateway = 'RAZORPAY',
  }) async {
    createPaymentOrderCalls++;
    return const PaymentOrderResult(
      paymentId: 'pay-new-uuid',
      gatewayOrderId: 'order_rzp_mock_1234',
      amount: 18725.0,
      currency: 'INR',
      razorpayKeyId: 'rzp_test_keralink2026',
      bookingReference: 'KL2609079999',
    );
  }

  @override
  Future<PaymentVerificationResult> verifyPayment({
    required String bookingId,
    required String gatewayOrderId,
    required String gatewayPaymentId,
    required String gatewaySignature,
  }) async {
    verifyPaymentCalls++;
    return const PaymentVerificationResult(
      status: 'confirmed',
      bookingReference: 'KL2609079999',
      digitalPassToken: 'KL-PASS-KL2609079999-E5F6G7H8',
      confirmedAt: '2026-09-07T12:00:00Z',
    );
  }

  @override
  Future<List<TripSummary>> getUserTrips() async {
    getUserTripsCalls++;
    return mockTrips;
  }

  @override
  Future<TripDetail> getTripDetail(String bookingReference) async {
    getTripDetailCalls++;
    return TripDetail(
      id: 'bkg-uuid-1',
      bookingReference: bookingReference,
      tripTitle: 'Munnar & Alleppey Cultural Odyssey',
      status: 'CONFIRMED',
      startDate: '2026-10-15',
      endDate: '2026-10-17',
      travelersCount: 2,
      primaryGuestName: 'Sreerag P',
      primaryGuestPhone: '+91 98470 12345',
      primaryGuestEmail: 'sreerag@keralink.travel',
      subtotal: 17500.0,
      tax: 875.0,
      platformFee: 350.0,
      totalAmount: 18725.0,
      currency: 'INR',
      greenTripScore: 92,
      corridor: 'Kochi → Munnar → Alappuzha',
      items: const [
        TripItem(
          id: 'itm-1',
          itemType: 'ROOM',
          title: 'Upper Deck Jacuzzi Suite',
          date: '2026-10-15',
          quantity: 1,
          unitPrice: 8500.0,
          totalPrice: 8500.0,
          isConfirmed: true,
        ),
        TripItem(
          id: 'itm-2',
          itemType: 'EXPERIENCE',
          title: 'Sunrise Shikara Trail',
          date: '2026-10-16',
          quantity: 2,
          unitPrice: 1200.0,
          totalPrice: 2400.0,
          isConfirmed: true,
        ),
      ],
      chauffeur: const ChauffeurInfo(
        name: 'Rajesh Kumar',
        vehicle: 'Toyota Innova Crysta (KL-07-CC-4821)',
        phone: '+91 98470 12345',
      ),
      digitalPass: DigitalPassModel(
        passToken: 'KL-PASS-$bookingReference-MOCK',
        qrData: 'https://keralink.org/pass/$bookingReference',
        verificationUrl: '/api/v1/bookings/pass/$bookingReference/',
        isValid: true,
      ),
    );
  }
}

class MockWaveCInventoryRepository implements IInventoryRepository {
  @override
  Future<InventoryAvailability> checkAvailability(String inventoryType, String inventoryId, {String? date, int quantity = 1}) async {
    return InventoryAvailability(
      inventoryType: inventoryType,
      inventoryId: inventoryId,
      totalCapacity: 5,
      bookedCapacity: 1,
      heldCapacity: 0,
      availableCapacity: 4,
      isAvailable: true,
    );
  }

  @override
  Future<InventoryHold> createHold(String inventoryType, String inventoryId, {String? date, int quantity = 1, String? itineraryVersionId, int durationMins = 15}) async {
    return InventoryHold(
      id: 'hold-1',
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
  Future<InventoryHold> getHold(String holdId) => throw UnimplementedError();

  @override
  Future<InventoryHold> extendHold(String holdId, {int extraMinutes = 10}) => throw UnimplementedError();

  @override
  Future<InventoryHold> releaseHold(String holdId) => throw UnimplementedError();

  @override
  Future<ItineraryHoldResult> holdItinerary({required List<Map<String, dynamic>> items, String? itineraryVersionId, int durationMins = 15}) async {
    final holds = items.map((e) => InventoryHold(
      id: 'hold-mock-1',
      inventoryType: e['inventory_type'] as String,
      inventoryId: e['inventory_id'] as String,
      quantity: 1,
      status: 'ACTIVE',
      expiresAt: DateTime.now().add(const Duration(minutes: 15)),
      remainingSeconds: 900,
      isValid: true,
    )).toList();

    return ItineraryHoldResult(
      holds: holds,
      totalHeld: holds.length,
      status: 'ALL_HELD',
      isSuccess: true,
    );
  }
}

AIPlan _createWaveCTestPlan() {
  return const AIPlan(
    planId: 'plan-wave-c-1',
    version: 2,
    validationStatus: 'VALID',
    title: 'Backwater & Heritage Bliss',
    corridorRoute: ['Kochi', 'Munnar', 'Alappuzha'],
    durationDays: 2,
    travelStyle: 'PREMIUM',
    createdAt: '2026-09-07T12:00:00Z',
    pricing: PricingBreakdown(
      daysCount: 2,
      travelersCount: 2,
      staysSubtotal: 8500,
      experiencesSubtotal: 2400,
      transportSubtotal: 5000,
      subtotal: 15900,
      gstRatePercent: 5.0,
      gstAmount: 795,
      platformFeePercent: 2.0,
      platformFee: 318,
      taxesAndFees: 1113,
      discount: 0,
      total: 17013,
    ),
    validation: ValidationReport(
      valid: true,
      errors: [],
      warnings: [],
      score: 95,
      budgetLimit: 35000,
      calculatedTotal: 17013,
    ),
    days: [
      PlanDay(
        dayNumber: 1,
        destinationId: 1,
        destinationName: 'Alappuzha',
        themeTitle: 'Backwater Serenity',
        timeline: [
          TimelineEvent(
            id: 'ev_c_1',
            order: 1,
            type: 'STAY',
            accommodationId: 1,
            title: 'Upper Deck Jacuzzi Suite',
            destinationId: 1,
            destinationName: 'Alappuzha',
            time: '14:00',
            startTime: '14:00',
            endTime: '15:00',
            durationMins: 60,
            price: 8500,
          ),
          TimelineEvent(
            id: 'ev_c_2',
            order: 2,
            type: 'EXPERIENCE',
            experienceId: 1,
            title: 'Sunrise Shikara Trail',
            destinationId: 1,
            destinationName: 'Alappuzha',
            time: '06:30',
            startTime: '06:30',
            endTime: '09:00',
            durationMins: 150,
            price: 2400,
          ),
        ],
      ),
    ],
  );
}

void main() {
  group('Wave C — Booking Checkout Sheet Tests', () {
    late MockWaveCTripsRepository mockTripsRepo;
    late AIPlan testPlan;
    late List<InventoryHold> testHolds;

    setUp(() {
      mockTripsRepo = MockWaveCTripsRepository();
      testPlan = _createWaveCTestPlan();
      testHolds = [
        InventoryHold(
          id: 'hold-c-1',
          inventoryType: 'ROOM',
          inventoryId: 'room_1',
          quantity: 1,
          status: 'ACTIVE',
          expiresAt: DateTime.now().add(const Duration(minutes: 15)),
          remainingSeconds: 900,
          isValid: true,
        ),
      ];
    });

    testWidgets('Renders guest form, pricing breakdown, and executes checkout', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookingCheckoutSheet(
              plan: testPlan,
              activeHolds: testHolds,
              tripsRepository: mockTripsRepo,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check header and form fields
      expect(find.text('Checkout & Confirm Trip'), findsOneWidget);
      expect(find.byKey(const Key('checkout_guest_name')), findsOneWidget);
      expect(find.byKey(const Key('checkout_guest_phone')), findsOneWidget);
      expect(find.byKey(const Key('checkout_guest_email')), findsOneWidget);

      // Check pricing breakdown
      expect(find.text('Authoritative Pricing Breakdown'), findsOneWidget);
      expect(find.text('Kerala GST (5%)'), findsOneWidget);
      expect(find.text('Platform & Eco Fee (2%)'), findsOneWidget);

      final payBtn = find.byKey(const Key('booking_pay_button'));
      expect(payBtn, findsOneWidget);

      // Tap Pay with Razorpay
      await tester.ensureVisible(payBtn);
      await tester.pumpAndSettle();
      await tester.tap(payBtn);
      await tester.pumpAndSettle();

      // Verify repository methods invoked
      expect(mockTripsRepo.createBookingCalls, 1);
      expect(mockTripsRepo.createPaymentOrderCalls, 1);
      expect(mockTripsRepo.verifyPaymentCalls, 1);
    });
  });

  group('Wave C — My Trips Screen Tests', () {
    late MockWaveCTripsRepository mockTripsRepo;

    setUp(() {
      mockTripsRepo = MockWaveCTripsRepository();
    });

    testWidgets('Displays real trip cards and opens TripDetailScreen on tap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MyTripsScreen(repository: mockTripsRepo),
        ),
      );

      await tester.pumpAndSettle();

      // Check trip card rendered
      expect(mockTripsRepo.getUserTripsCalls, 1);
      expect(find.text('Munnar & Alleppey Cultural Odyssey'), findsOneWidget);
      expect(find.textContaining('CONFIRMED • ECO 92%'), findsOneWidget);
      expect(find.text('KL2609071234'), findsOneWidget);
      expect(find.text('View Pass'), findsOneWidget);

      // Tap View Pass to open detail
      await tester.tap(find.text('View Pass'));
      await tester.pumpAndSettle();

      // Trip detail screen rendered
      expect(mockTripsRepo.getTripDetailCalls, 1);
      expect(find.text('Digital Boarding Pass'), findsOneWidget);
      expect(find.byKey(const Key('trip_qr_image')), findsOneWidget);
    });
  });

  group('Wave C — Trip Detail Screen Tests', () {
    late MockWaveCTripsRepository mockTripsRepo;

    setUp(() {
      mockTripsRepo = MockWaveCTripsRepository();
    });

    testWidgets('Renders QR code, confirmed vouchers, and chauffeur info', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TripDetailScreen(
            bookingReference: 'KL2609071234',
            repository: mockTripsRepo,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Digital boarding pass
      expect(find.byKey(const Key('trip_pass_card')), findsOneWidget);
      expect(find.byKey(const Key('trip_qr_image')), findsOneWidget);
      expect(find.byKey(const Key('trip_pass_token')), findsOneWidget);

      // Chauffeur info
      expect(find.text('Rajesh Kumar'), findsOneWidget);
      expect(find.text('Toyota Innova Crysta (KL-07-CC-4821)'), findsOneWidget);

      // Confirmed vouchers
      expect(find.text('Upper Deck Jacuzzi Suite'), findsOneWidget);
      expect(find.text('Sunrise Shikara Trail'), findsOneWidget);
    });
  });

  group('Wave C — InventoryHoldSheet to Checkout Handoff', () {
    testWidgets('Tapping Proceed to Booking opens BookingCheckoutSheet', (tester) async {
      final mockInv = MockWaveCInventoryRepository();
      final mockTrips = MockWaveCTripsRepository();
      final testPlan = _createWaveCTestPlan();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InventoryHoldSheet(
              plan: testPlan,
              repository: mockInv,
              tripsRepository: mockTrips,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Hold all
      await tester.tap(find.byKey(const Key('inventory_hold_all_btn')));
      await tester.pumpAndSettle();

      // Proceed to Booking button visible
      final proceedBtn = find.byKey(const Key('inventory_proceed_booking_btn'));
      expect(proceedBtn, findsOneWidget);

      // Tap Proceed
      await tester.tap(proceedBtn);
      await tester.pumpAndSettle();

      // Verify BookingCheckoutSheet is presented
      expect(find.text('Checkout & Confirm Trip'), findsOneWidget);
      expect(find.byKey(const Key('booking_pay_button')), findsOneWidget);
    });
  });
}

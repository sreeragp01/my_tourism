import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keralink_mobile/features/transport/data/transport_repository.dart';
import 'package:keralink_mobile/features/transport/models/transport_models.dart';
import 'package:keralink_mobile/features/transport/presentation/cab_booking_screen.dart';
import 'package:keralink_mobile/features/transport/presentation/cab_pass_screen.dart';

class MockTestTransportRepository implements ITransportRepository {
  final List<VehicleCategory> mockVehicles = const [
    VehicleCategory(
      id: 'veh-1',
      name: 'Sedan Prime (Dzire / Etios)',
      vehicleType: 'SEDAN_AC',
      tagline: 'Ideal for couples & solo business travelers',
      passengerCapacity: 4,
      luggageCapacity: 3,
      hasAc: true,
      hasMountainPermit: true,
      heroImage: 'https://images.unsplash.com/photo-1549399542-7e3f8b79c341',
      baseRatePerKm: 18.0,
      dailyRentalRate: 2800.0,
      driverBataPerDay: 500.0,
      features: ['Chilled AC', 'Bluetooth Audio', 'Fastag Enabled'],
      rating: 4.92,
    ),
    VehicleCategory(
      id: 'veh-2',
      name: 'Toyota Innova Crysta Luxury',
      vehicleType: 'SUV_PREMIUM',
      tagline: 'King of Kerala hill-stations and ghat routes',
      passengerCapacity: 7,
      luggageCapacity: 5,
      hasAc: true,
      hasMountainPermit: true,
      heroImage: 'https://images.unsplash.com/photo-1533473359331-0135ef1b58bf',
      baseRatePerKm: 26.0,
      dailyRentalRate: 4200.0,
      driverBataPerDay: 600.0,
      features: ['Captain Seats', 'Dual Zone AC', 'Ghat Certified Driver'],
      rating: 4.98,
    ),
    VehicleCategory(
      id: 'veh-3',
      name: 'Force Tempo Traveller (12-17 Seater)',
      vehicleType: 'TEMPO_TRAVELLER',
      tagline: 'Spacious group and big-family grand tourer',
      passengerCapacity: 14,
      luggageCapacity: 12,
      hasAc: true,
      hasMountainPermit: true,
      heroImage: 'https://images.unsplash.com/photo-1570125909232-eb263c188f7e',
      baseRatePerKm: 34.0,
      dailyRentalRate: 6500.0,
      driverBataPerDay: 800.0,
      features: ['Pushback Seats', 'Individual AC Vents', 'Mic & PA System'],
      rating: 4.95,
    ),
  ];

  final List<AirportRoute> mockCokRoutes = const [
    AirportRoute(
      id: 'rt-1',
      airportCode: 'COK',
      airportName: 'Cochin International Airport (Nedumbassery)',
      destinationName: 'Munnar Hill Station',
      district: 'Idukki',
      distanceKm: 110,
      approxDurationHours: 3.5,
      isGhatRoad: true,
      sedanFare: 3200.0,
      suvCrystaFare: 4500.0,
      tempoFare: 7200.0,
    ),
    AirportRoute(
      id: 'rt-2',
      airportCode: 'COK',
      airportName: 'Cochin International Airport (Nedumbassery)',
      destinationName: 'Alleppey Backwaters',
      district: 'Alappuzha',
      distanceKm: 85,
      approxDurationHours: 2.2,
      isGhatRoad: false,
      sedanFare: 2600.0,
      suvCrystaFare: 3800.0,
      tempoFare: 6000.0,
    ),
  ];

  final List<AirportRoute> mockTrvRoutes = const [
    AirportRoute(
      id: 'rt-3',
      airportCode: 'TRV',
      airportName: 'Thiruvananthapuram International Airport',
      destinationName: 'Varkala Cliff Beach',
      district: 'Thiruvananthapuram',
      distanceKm: 45,
      approxDurationHours: 1.2,
      isGhatRoad: false,
      sedanFare: 1600.0,
      suvCrystaFare: 2400.0,
      tempoFare: 3800.0,
    ),
  ];

  Map<String, dynamic>? lastSubmittedPayload;

  @override
  Future<List<VehicleCategory>> getVehicles() async {
    return mockVehicles;
  }

  @override
  Future<List<AirportRoute>> getAirportRoutes({String? airport}) async {
    if (airport == 'TRV') return mockTrvRoutes;
    return mockCokRoutes;
  }

  @override
  Future<CabBookingResult> createCabBooking(Map<String, dynamic> payload) async {
    lastSubmittedPayload = payload;
    return CabBookingResult(
      bookingReference: 'CAB-2026-TEST',
      travelerName: payload['traveler_name'] as String? ?? 'Sreerag',
      pickupLocation: payload['pickup_location'] as String? ?? 'COK Airport',
      dropLocation: payload['drop_location'] as String? ?? 'Munnar',
      pickupDate: payload['pickup_date'] as String? ?? '2026-11-20',
      pickupTime: payload['pickup_time'] as String? ?? '14:30',
      vehicleName: 'Toyota Innova Crysta Luxury',
      plateNumber: 'KL-07-CD-4589',
      driverName: 'Rajesh Kumar',
      driverPhone: '+91 94470 54321',
      driverWhatsApp: '+919447054321',
      totalFare: (payload['total_fare'] as num?)?.toDouble() ?? 4500.0,
      nameboardText: payload['nameboard_text'] as String? ?? 'Welcome Mr. Sreerag',
    );
  }
}

void main() {
  testWidgets('renders CabBookingScreen with airport selection, route, and vehicle options',
      (WidgetTester tester) async {
    final mockRepo = MockTestTransportRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: CabBookingScreen(repository: mockRepo),
      ),
    );
    await tester.pumpAndSettle();

    // Verify AppBar header
    expect(find.text('Kerala Tourist Cabs & Chauffeurs'), findsOneWidget);
    expect(find.text('Pre-Book Before Landing in Kerala'), findsOneWidget);

    // Verify Airport Chips
    expect(find.byKey(const Key('airport_chip_COK')), findsOneWidget);
    expect(find.byKey(const Key('airport_chip_TRV')), findsOneWidget);

    // Verify Drop Route selected
    expect(find.textContaining('Munnar Hill Station'), findsWidgets);

    // Verify Vehicle Categories rendered
    expect(find.text('Toyota Innova Crysta Luxury'), findsOneWidget);
    expect(find.text('Sedan Prime (Dzire / Etios)'), findsOneWidget);

    // Verify Sticky bottom bar total fare
    expect(find.text('TOTAL ALL-INCLUSIVE'), findsOneWidget);
    expect(find.text('₹4500'), findsWidgets);
    expect(find.byKey(const Key('reserve_cab_button')), findsOneWidget);
  });

  testWidgets('allows switching airport and toggles route correctly',
      (WidgetTester tester) async {
    final mockRepo = MockTestTransportRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: CabBookingScreen(repository: mockRepo),
      ),
    );
    await tester.pumpAndSettle();

    // Tap on TRV airport chip
    await tester.tap(find.byKey(const Key('airport_chip_TRV')));
    await tester.pumpAndSettle();

    // Verify Varkala Cliff Beach route for TRV is loaded
    expect(find.textContaining('Varkala Cliff Beach'), findsWidgets);
  });

  testWidgets('allows switching to Kerala Chauffeur Tour multi-day mode and adjusting days',
      (WidgetTester tester) async {
    final mockRepo = MockTestTransportRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: CabBookingScreen(repository: mockRepo),
      ),
    );
    await tester.pumpAndSettle();

    // Tap on multi-day tour mode
    await tester.tap(find.byKey(const Key('mode_daily_rental')));
    await tester.pumpAndSettle();

    // Verify multi-day itinerary fields
    expect(find.text('Multi-Day Dedicated Chauffeur Itinerary'), findsOneWidget);
    expect(find.text('3 Days'), findsOneWidget);

    // Innova Crysta = (4200 + 600) * 3 = 14400
    expect(find.text('₹14400'), findsWidgets);
  });

  testWidgets('submits booking and navigates to CabPassScreen with driver and pass details',
      (WidgetTester tester) async {
    final mockRepo = MockTestTransportRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: CabBookingScreen(repository: mockRepo),
      ),
    );
    await tester.pumpAndSettle();

    // Fill placard nameboard
    final nameboardField = find.byKey(const Key('nameboard_field'));
    await tester.enterText(nameboardField, 'Welcome Sreerag & Family');

    // Scroll down to traveler contact section
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();

    // Fill traveler name
    final nameField = find.byKey(const Key('traveler_name_field'));
    await tester.enterText(nameField, 'Sreerag Test User');

    // Tap Reserve button (in sticky bottom sheet)
    final reserveBtn = find.byKey(const Key('reserve_cab_button'));
    await tester.tap(reserveBtn);
    await tester.pumpAndSettle();

    // Verify navigation to CabPassScreen
    expect(find.byType(CabPassScreen), findsOneWidget);
    expect(find.text('Chauffeur Booking Pass'), findsOneWidget);
    expect(find.text('Cab Reserved & Confirmed'), findsOneWidget);
    expect(find.text('CAB-2026-TEST'), findsOneWidget);
    expect(find.text('Welcome Sreerag & Family'), findsOneWidget);

    // Scroll down to driver card
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(find.text('Rajesh Kumar'), findsOneWidget);
    expect(find.textContaining('KL-07-CD-4589'), findsOneWidget);
  });

  testWidgets('CabPassScreen displays chauffeur profile, nameboard, and action buttons',
      (WidgetTester tester) async {
    const testBooking = CabBookingResult(
      bookingReference: 'CAB-2026-9999',
      travelerName: 'Dr. Michael Chen',
      pickupLocation: 'Cochin International Airport (COK)',
      dropLocation: 'Tea Valley Resort, Munnar',
      pickupDate: '2026-11-25',
      pickupTime: '15:45',
      vehicleName: 'Toyota Innova Crysta Luxury',
      plateNumber: 'KL-07-CD-4589',
      driverName: 'Rajesh Kumar',
      driverPhone: '+91 94470 54321',
      driverWhatsApp: '+919447054321',
      totalFare: 4500.0,
      nameboardText: 'Welcome Dr. Michael Chen',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: CabPassScreen(booking: testBooking),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('CAB-2026-9999'), findsOneWidget);
    expect(find.text('Welcome Dr. Michael Chen'), findsOneWidget);

    // Scroll to see driver card and buttons
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(find.text('Rajesh Kumar'), findsOneWidget);
    expect(find.text('4.98 ★'), findsOneWidget);
    expect(find.textContaining('POLICE VERIFIED CHAUFFEUR'), findsOneWidget);
    expect(find.text('WhatsApp Driver'), findsOneWidget);
    expect(find.text('Call'), findsOneWidget);
  });
}

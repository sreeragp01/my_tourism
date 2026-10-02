import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keralink_mobile/features/packages/data/package_repository.dart';
import 'package:keralink_mobile/features/packages/models/package_models.dart';
import 'package:keralink_mobile/features/packages/presentation/packages_screen.dart';
import 'package:keralink_mobile/features/packages/presentation/package_detail_screen.dart';

class MockTestPackageRepository implements IPackageRepository {
  final List<TourPackage> mockPackages = [
    const TourPackage(
      id: 'pkg-1',
      title: '3D/2N Munnar Cloud Mist & Kolukkumalai',
      slug: 'munnar-cloud-mist-3d2n',
      category: 'HILL_STATION',
      tagline: 'Highland tea trails and 4x4 sunrise summit',
      durationDays: 3,
      durationNights: 2,
      duration: '3D / 2N',
      startCity: 'Kochi',
      endCity: 'Kochi',
      destinationsCovered: ['Kochi', 'Munnar'],
      pricePerPerson: 8499.00,
      originalPrice: 10500.00,
      savingsPercent: 19,
      heroImage: 'https://example.com/munnar.jpg',
      highlights: ['4x4 Jeep Safari', 'Tea tasting'],
      inclusions: ['Resort stay', 'Buffet breakfast'],
      exclusions: ['Flight tickets'],
      itinerary: [
        PackageDayItinerary(
          day: 1,
          title: 'Kochi to Munnar',
          description: 'Ghat drive and waterfalls',
          meals: 'Dinner',
          stay: 'Tea Valley Resort',
        ),
        PackageDayItinerary(
          day: 2,
          title: 'Kolukkumalai Sunrise',
          description: 'Cloud mist safari',
          meals: 'Breakfast',
          stay: 'Tea Valley Resort',
        ),
      ],
      rating: 4.95,
      reviewCount: 64,
      isFeatured: true,
      operator: OperatorProfile(
        name: 'Munnar Highland Holidays',
        phone: '+91 94471 23456',
        whatsapp: '+919447123456',
        license: 'DTPC Idukki Accredited',
        isVerified: true,
      ),
    ),
    const TourPackage(
      id: 'pkg-2',
      title: '2D/1N Alleppey Houseboat & Village Canoe',
      slug: 'alleppey-houseboat-2d1n',
      category: 'BACKWATERS',
      tagline: 'Private luxury Kettuvallam',
      durationDays: 2,
      durationNights: 1,
      duration: '2D / 1N',
      startCity: 'Alappuzha',
      endCity: 'Alappuzha',
      destinationsCovered: ['Alappuzha', 'Vembanad'],
      pricePerPerson: 7499.00,
      originalPrice: 9200.00,
      savingsPercent: 18,
      heroImage: 'https://example.com/houseboat.jpg',
      highlights: ['Karimeen Pollichathu', 'Sunset canoe'],
      inclusions: ['All meals', 'Houseboat stay'],
      exclusions: ['Transfers'],
      itinerary: [
        PackageDayItinerary(
          day: 1,
          title: 'Cruise Embarkation',
          description: 'Vembanad Lake cruise',
          meals: 'Lunch & Dinner',
          stay: 'Private Houseboat',
        ),
      ],
      rating: 4.98,
      reviewCount: 92,
      isFeatured: true,
      operator: OperatorProfile(
        name: 'Great Backwaters Tourism Co.',
        phone: '+91 98470 54321',
        whatsapp: '+919847054321',
        license: 'Kerala Tourism Diamond Certified',
        isVerified: true,
      ),
    ),
  ];

  @override
  Future<List<TourPackage>> getPackages({String? category, String? query, double? maxPrice}) async {
    var res = mockPackages;
    if (category != null && category != 'ALL') {
      res = res.where((p) => p.category == category).toList();
    }
    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      res = res.where((p) => p.title.toLowerCase().contains(q)).toList();
    }
    return res;
  }

  @override
  Future<TourPackage> getPackageDetail(String slug) async {
    return mockPackages.firstWhere((p) => p.slug == slug);
  }

  @override
  Future<Map<String, dynamic>> inquirePackage(String slug, Map<String, dynamic> payload) async {
    return {
      'success': true,
      'whatsapp_url': 'https://wa.me/919447123456?text=Interested',
      'operator_name': 'Munnar Highland Holidays',
    };
  }

  @override
  Future<Map<String, dynamic>> recordWhatsAppClick(String slug, Map<String, dynamic> payload) async {
    return {
      'whatsapp_url': 'https://wa.me/919447123456?text=WhatsApp',
      'operator_name': 'Munnar Highland Holidays',
    };
  }
}

void main() {
  group('Tour Packages & Local Operators Feature Tests', () {
    late MockTestPackageRepository repo;

    setUp(() {
      repo = MockTestPackageRepository();
    });

    testWidgets('PackagesScreen renders header, categories, and package cards', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PackagesScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('Tour Packages & Operators'), findsOneWidget);
      expect(find.text('Direct from DTPC & Kerala Tourism verified companies'), findsOneWidget);

      // Verify Search Bar and Chips
      expect(find.byKey(const Key('packages_search_input')), findsOneWidget);
      expect(find.byKey(const Key('cat_chip_ALL')), findsOneWidget);
      expect(find.byKey(const Key('cat_chip_HILL_STATION')), findsOneWidget);
      expect(find.byKey(const Key('cat_chip_BACKWATERS')), findsOneWidget);

      // Verify Package Cards
      expect(find.text('3D/2N Munnar Cloud Mist & Kolukkumalai'), findsOneWidget);
      expect(find.text('Munnar Highland Holidays'), findsOneWidget);
      expect(find.text('₹8499'), findsOneWidget);

      // Scroll to view subsequent package card
      await tester.drag(find.byType(ListView).last, const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(find.text('2D/1N Alleppey Houseboat & Village Canoe'), findsOneWidget);
    });

    testWidgets('PackagesScreen category filtering updates results', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PackagesScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on Backwaters Chip
      await tester.tap(find.byKey(const Key('cat_chip_BACKWATERS')));
      await tester.pumpAndSettle();

      // Munnar should be filtered out, Alleppey remains
      expect(find.text('2D/1N Alleppey Houseboat & Village Canoe'), findsOneWidget);
      expect(find.text('3D/2N Munnar Cloud Mist & Kolukkumalai'), findsNothing);
    });

    testWidgets('PackageDetailScreen renders itinerary, operator, and action buttons', (tester) async {
      final samplePkg = repo.mockPackages.first;

      await tester.pumpWidget(
        MaterialApp(
          home: PackageDetailScreen(
            package: samplePkg,
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Title & Operator
      expect(find.text('3D/2N Munnar Cloud Mist & Kolukkumalai'), findsOneWidget);
      expect(find.text('Munnar Highland Holidays'), findsOneWidget);
      expect(find.text('DTPC Idukki Accredited'), findsOneWidget);

      // Highlights & Itinerary
      expect(find.text('Trip Highlights'), findsOneWidget);
      expect(find.text('Day-by-Day Itinerary'), findsOneWidget);
      expect(find.text('DAY 1'), findsOneWidget);
      expect(find.text('Kochi to Munnar'), findsOneWidget);
      expect(find.text('DAY 2'), findsOneWidget);
      expect(find.text('Kolukkumalai Sunrise'), findsOneWidget);

      // Action Buttons
      expect(find.byKey(const Key('chat_whatsapp_btn')), findsOneWidget);
      expect(find.byKey(const Key('call_operator_btn')), findsOneWidget);
      expect(find.byKey(const Key('book_package_btn')), findsOneWidget);

      // Open WhatsApp Inquiry Modal
      await tester.tap(find.byKey(const Key('chat_whatsapp_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Connect with Operator'), findsOneWidget);
      expect(find.text('Direct inquiry to Munnar Highland Holidays'), findsOneWidget);

      // Submit inquiry
      await tester.tap(find.byKey(const Key('submit_inquiry_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Opening WhatsApp with Munnar Highland Holidays...'), findsOneWidget);
    });

    testWidgets('PackageDetailScreen opens Call Operator dialog and Book confirmation', (tester) async {
      final samplePkg = repo.mockPackages.first;

      await tester.pumpWidget(
        MaterialApp(
          home: PackageDetailScreen(
            package: samplePkg,
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Test Call Button
      await tester.tap(find.byKey(const Key('call_operator_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Accredited Tour Operator Helpline:'), findsOneWidget);
      expect(find.text('+91 94471 23456'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Test Book Button
      await tester.tap(find.byKey(const Key('book_package_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Confirm Package Booking'), findsOneWidget);
      await tester.tap(find.byKey(const Key('confirm_package_booking_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Package reserved successfully! Digital voucher created.'), findsOneWidget);
    });
  });
}

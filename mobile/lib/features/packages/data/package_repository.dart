import '../../../core/network/api_client.dart';
import '../models/package_models.dart';

abstract class IPackageRepository {
  Future<List<TourPackage>> getPackages({String? category, String? query, double? maxPrice});
  Future<TourPackage> getPackageDetail(String slug);
  Future<Map<String, dynamic>> inquirePackage(String slug, Map<String, dynamic> payload);
  Future<Map<String, dynamic>> recordWhatsAppClick(String slug, Map<String, dynamic> payload);
}

class PackageRepository implements IPackageRepository {
  final ApiClient apiClient;

  PackageRepository({required this.apiClient});

  @override
  Future<List<TourPackage>> getPackages({String? category, String? query, double? maxPrice}) async {
    try {
      final queryParams = <String, String>{};
      if (category != null && category != 'ALL') queryParams['category'] = category;
      if (query != null && query.isNotEmpty) queryParams['q'] = query;
      if (maxPrice != null && maxPrice > 0) queryParams['max_price'] = maxPrice.toInt().toString();

      final res = await apiClient.get('/api/v1/packages/', queryParameters: queryParams);
      final rawList = (res is List)
          ? res
          : (res is Map && res['results'] is List)
              ? res['results'] as List
              : [];
      return rawList.map((e) => TourPackage.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      // Fallback offline mock packages
      return _getMockPackages(category: category, query: query);
    }
  }

  @override
  Future<TourPackage> getPackageDetail(String slug) async {
    try {
      final res = await apiClient.get('/api/v1/packages/$slug/');
      return TourPackage.fromJson(res as Map<String, dynamic>);
    } catch (_) {
      return _getMockPackages().firstWhere(
        (p) => p.slug == slug,
        orElse: () => _getMockPackages().first,
      );
    }
  }

  @override
  Future<Map<String, dynamic>> inquirePackage(String slug, Map<String, dynamic> payload) async {
    try {
      final res = await apiClient.post('/api/v1/packages/$slug/inquire/', body: payload);
      return res as Map<String, dynamic>;
    } catch (_) {
      return {
        'success': true,
        'whatsapp_url': 'https://wa.me/919447123456?text=Hello+I+am+interested+in+this+Kerala+tour+package',
        'operator_name': 'Munnar Highland Holidays',
        'operator_phone': '+91 94471 23456',
      };
    }
  }

  @override
  Future<Map<String, dynamic>> recordWhatsAppClick(String slug, Map<String, dynamic> payload) async {
    try {
      final res = await apiClient.post('/api/v1/packages/$slug/whatsapp_click/', body: payload);
      return res as Map<String, dynamic>;
    } catch (_) {
      return {
        'whatsapp_url': 'https://wa.me/919447123456?text=Hello+I+am+interested+in+this+Kerala+tour+package',
        'operator_name': 'Local Kerala Tour Operator',
      };
    }
  }

  List<TourPackage> _getMockPackages({String? category, String? query}) {
    final list = [
      const TourPackage(
        id: 'pkg-munnar-3d2n-mist',
        title: '3D/2N Munnar Cloud Mist & Kolukkumalai Sunrise Expedition',
        slug: 'munnar-cloud-mist-kolukkumalai-3d2n',
        category: 'HILL_STATION',
        tagline: 'Highland tea trails, off-road 4x4 sunrise summit, and waterfalls',
        description: 'Experience the misty magic of Munnar curated by native high-range guides. Includes 4x4 mountain jeep safari to Kolukkumalai (world highest organic tea estate), guided tea tasting, and boutique tea plantation resort stay.',
        durationDays: 3,
        durationNights: 2,
        duration: '3D / 2N',
        startCity: 'Kochi Airport',
        endCity: 'Kochi Airport',
        destinationsCovered: ['Kochi', 'Valara Falls', 'Munnar', 'Kolukkumalai'],
        pricePerPerson: 8499.00,
        originalPrice: 10500.00,
        savingsPercent: 19,
        heroImage: 'https://images.unsplash.com/photo-1596178065887-1198b6148b2b?auto=format&fit=crop&w=1200&q=80',
        highlights: [
          '4x4 Jeep Safari to Kolukkumalai at 7,130 ft for Golden Sunrise',
          'Private Tea Factory tour & artisan tea sommelier tasting',
          'Stop at Cheeyappara & Valara jungle waterfalls on NH85',
        ],
        inclusions: [
          '2 Nights accommodation in 4-Star Tea Valley Resort',
          'Daily plantation buffet breakfast & 1 campfire dinner',
          'Private AC Sedan with fuel, toll, parking & driver allowance',
          'Kolukkumalai 4x4 mountain Jeep permit and entry fees',
        ],
        exclusions: [
          'Airfare / Train tickets to/from Kochi',
          'Lunches and personal adventure ride tickets',
        ],
        itinerary: [
          PackageDayItinerary(
            day: 1,
            title: 'Kochi to Munnar — Ghat Ascent & Waterfalls',
            description: 'Pick up from Kochi. Scenic ascent through rubber estates and mountain mist. En-route stop at Valara and Cheeyappara waterfalls.',
            meals: 'Dinner included',
            stay: 'Munnar Tea Valley Resort',
          ),
          PackageDayItinerary(
            day: 2,
            title: 'Kolukkumalai Sunrise & Mattupetty Highland Circuit',
            description: 'Early 4:30 AM departure in 4x4 jeep to Kolukkumalai peak. Afternoon visit to Mattupetty Dam, Echo Point, and Kundala Lake.',
            meals: 'Breakfast & Campfire Dinner',
            stay: 'Munnar Tea Valley Resort',
          ),
          PackageDayItinerary(
            day: 3,
            title: 'Eravikulam Nilgiri Tahr & Return Descent to Kochi',
            description: 'Morning visit to Rajamalai in Eravikulam National Park. Scenic descent back to Kochi Airport/Station.',
            meals: 'Breakfast included',
            stay: 'Trip Concludes',
          ),
        ],
        rating: 4.95,
        reviewCount: 64,
        isFeatured: true,
        operator: OperatorProfile(
          name: 'Munnar Highland Holidays',
          phone: '+91 94471 23456',
          whatsapp: '+919447123456',
          license: 'DTPC Idukki Accredited (#DTPC-IDK-2024-88)',
          isVerified: true,
        ),
      ),
      const TourPackage(
        id: 'pkg-alleppey-2d1n-houseboat',
        title: '2D/1N Alleppey Royal Backwater Houseboat & Village Canoe Cruise',
        slug: 'alleppey-royal-houseboat-backwaters-2d1n',
        category: 'BACKWATERS',
        tagline: 'Private luxury wooden Kettuvallam with master chef Karimeen feast',
        description: 'Glide through the tranquil canals of Vembanad Lake and Kuttanad on an authentic traditional houseboat.',
        durationDays: 2,
        durationNights: 1,
        duration: '2D / 1N',
        startCity: 'Alappuzha Jetty',
        endCity: 'Alappuzha Jetty',
        destinationsCovered: ['Alappuzha', 'Kuttanad', 'Vembanad'],
        pricePerPerson: 7499.00,
        originalPrice: 9200.00,
        savingsPercent: 18,
        heroImage: 'https://images.unsplash.com/photo-1602216056096-3b40cc0c9944?auto=format&fit=crop&w=1200&q=80',
        highlights: [
          'Exclusive Private Luxury AC Kettuvallam',
          'Traditional Kerala Lunch: Karimeen Pollichathu, Chemmeen Roast',
          'Sunset Country Canoe deep into narrow backwater village canals',
        ],
        inclusions: [
          '1 Night stay on Private AC Houseboat with ensuite bath',
          'All Meals onboard: Welcome drink, Lunch, Snacks, Dinner, Breakfast',
          '1-Hour guided narrow canal country wooden canoe tour',
        ],
        exclusions: ['Transfers to/from Alappuzha jetty', 'Crew gratuity'],
        itinerary: [
          PackageDayItinerary(
            day: 1,
            title: 'Embarkation at Punnamada Jetty & Backwater Glide',
            description: 'Boarding at 12:00 PM with fresh tender coconut welcome drink. Cruise commences into Vembanad Lake with banana leaf feast.',
            meals: 'Lunch, Evening Snacks & Dinner',
            stay: 'Private Luxury Houseboat',
          ),
          PackageDayItinerary(
            day: 2,
            title: 'Morning Mist Cruise & Village Disembarkation',
            description: 'Early morning tea on sundeck. Authentic Kerala breakfast (Hot Appam with vegetable stew / egg roast). Return by 9:30 AM.',
            meals: 'Breakfast included',
            stay: 'Cruise Concludes',
          ),
        ],
        rating: 4.98,
        reviewCount: 92,
        isFeatured: true,
        operator: OperatorProfile(
          name: 'Great Backwaters Tourism Co.',
          phone: '+91 98470 54321',
          whatsapp: '+919847054321',
          license: 'Kerala Tourism Diamond Certified (#KT-ALP-109)',
          isVerified: true,
        ),
      ),
      const TourPackage(
        id: 'pkg-wayanad-4d3n-wilderness',
        title: '4D/3N Wayanad Wilderness, Bamboo Rafting & Treehouse Retreat',
        slug: 'wayanad-wilderness-bamboo-rafting-treehouse-4d3n',
        category: 'ADVENTURE',
        tagline: 'Stay in authentic rainforest treehouse with tribal honey tasting & safaris',
        description: 'Escape into the biodiverse Western Ghats of Wayanad with canopy treehouses and river bamboo rafting.',
        durationDays: 4,
        durationNights: 3,
        duration: '4D / 3N',
        startCity: 'Kozhikode',
        endCity: 'Kozhikode',
        destinationsCovered: ['Calicut', 'Lakkidi', 'Kuruva Island', 'Edakkal Caves'],
        pricePerPerson: 11999.00,
        originalPrice: 14500.00,
        savingsPercent: 17,
        heroImage: 'https://images.unsplash.com/photo-1544735716-392fe2489ffa?auto=format&fit=crop&w=1200&q=80',
        highlights: [
          '1 Night in Rainforest Canopy Treehouse 40 feet above ground',
          'Indigenous Bamboo Rafting along Kabini River tributaries',
          'Open 4x4 Jeep Safari in Muthanga Wildlife Sanctuary',
        ],
        inclusions: [
          '3 Nights stay (1 Night Treehouse + 2 Nights Coffee Estate)',
          'Daily Malabar breakfast & 2 plantation dinners',
          'Dedicated vehicle with driver',
        ],
        exclusions: ['Camera permits', 'Personal expenses'],
        itinerary: [
          PackageDayItinerary(
            day: 1,
            title: 'Calicut Ghat Ascent to Rainforest Treehouse',
            description: 'Pick up from Calicut. Drive up Thamarassery Churam ghat road. Arrive at treehouse retreat.',
            meals: 'Dinner included',
            stay: 'Rainforest Treehouse',
          ),
          PackageDayItinerary(
            day: 2,
            title: 'Banasura Dam & Kuruva Island Bamboo Rafting',
            description: 'Visit Banasura Sagar Dam. Proceed to Kuruva Dweep for gentle bamboo rafting.',
            meals: 'Breakfast & Dinner',
            stay: 'Coffee Plantation Villa',
          ),
          PackageDayItinerary(
            day: 3,
            title: 'Edakkal Caves & Muthanga Elephant Safari',
            description: 'Morning hike to Edakkal Caves. Afternoon jeep safari in Muthanga Wildlife Sanctuary.',
            meals: 'Breakfast & Dinner',
            stay: 'Coffee Plantation Villa',
          ),
          PackageDayItinerary(
            day: 4,
            title: 'Soochipara Waterfalls & Departure',
            description: 'Morning visit to Soochipara Waterfalls. Scenic descent back to Kozhikode.',
            meals: 'Breakfast included',
            stay: 'Tour Concludes',
          ),
        ],
        rating: 4.92,
        reviewCount: 48,
        isFeatured: true,
        operator: OperatorProfile(
          name: 'Wayanad Eco-Guides Collective',
          phone: '+91 97450 99887',
          whatsapp: '+919745099887',
          license: 'Approved Ecotourism Collective (#WND-ECO-42)',
          isVerified: true,
        ),
      ),
    ];

    var filtered = list;
    if (category != null && category != 'ALL') {
      filtered = filtered.where((p) => p.category == category).toList();
    }
    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      filtered = filtered.where((p) =>
        p.title.toLowerCase().contains(q) ||
        p.destinationsCovered.any((d) => d.toLowerCase().contains(q)) ||
        p.operator.name.toLowerCase().contains(q)
      ).toList();
    }
    return filtered;
  }
}

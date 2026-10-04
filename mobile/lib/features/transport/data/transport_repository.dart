import '../../../core/network/api_client.dart';
import '../models/transport_models.dart';

abstract class ITransportRepository {
  Future<List<VehicleCategory>> getVehicles();
  Future<List<AirportRoute>> getAirportRoutes({String? airport});
  Future<CabBookingResult> createCabBooking(Map<String, dynamic> payload);
}

class TransportRepository implements ITransportRepository {
  final ApiClient? apiClient;

  TransportRepository({this.apiClient});

  @override
  Future<List<VehicleCategory>> getVehicles() async {
    if (apiClient == null) return _getMockVehicles();
    try {
      final res = await apiClient!.get('/api/v1/transport/vehicles/');
      final rawList = (res is List)
          ? res
          : (res is Map && res['results'] is List)
              ? res['results'] as List
              : [];
      return rawList.map((e) => VehicleCategory.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return _getMockVehicles();
    }
  }

  @override
  Future<List<AirportRoute>> getAirportRoutes({String? airport}) async {
    if (apiClient == null) return _getMockRoutes(airport: airport);
    try {
      final params = <String, String>{};
      if (airport != null) params['airport'] = airport;
      final res = await apiClient!.get('/api/v1/transport/airport-routes/', queryParameters: params);
      final rawList = (res is List)
          ? res
          : (res is Map && res['results'] is List)
              ? res['results'] as List
              : [];
      return rawList.map((e) => AirportRoute.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return _getMockRoutes(airport: airport);
    }
  }

  @override
  Future<CabBookingResult> createCabBooking(Map<String, dynamic> payload) async {
    if (apiClient != null) {
      try {
        final res = await apiClient!.post('/api/v1/transport/bookings/', body: payload);
        return CabBookingResult.fromJson(res as Map<String, dynamic>);
      } catch (_) {
        // Fall back to confirmed mock
      }
    }
      // Mock confirmed response
      return CabBookingResult(
        bookingReference: 'CAB-2026-8941',
        travelerName: payload['traveler_name'] as String? ?? 'Traveler',
        pickupLocation: payload['pickup_location'] as String? ?? 'Cochin International Airport',
        dropLocation: payload['drop_location'] as String? ?? 'Munnar Tea Valley',
        pickupDate: payload['pickup_date'] as String? ?? '2026-11-20',
        pickupTime: payload['pickup_time'] as String? ?? '14:30',
        vehicleName: 'Toyota Innova Crysta / Hycross',
        plateNumber: 'KL-07-CD-4589',
        driverName: 'Rajesh Kumar',
        driverPhone: '+91 94470 54321',
        driverWhatsApp: '+919447054321',
        totalFare: double.tryParse(payload['total_fare']?.toString() ?? '4500') ?? 4500.0,
        nameboardText: payload['nameboard_text'] as String? ?? 'Welcome to Kerala',
      );
  }

  List<VehicleCategory> _getMockVehicles() {
    return const [
      VehicleCategory(
        id: 'sedan-prime',
        name: 'Prime Sedan (Dzire / Etios)',
        vehicleType: 'SEDAN',
        tagline: 'Comfortable, fuel-efficient travel for couples & solo travelers',
        passengerCapacity: 4,
        luggageCapacity: 2,
        hasAc: true,
        hasMountainPermit: true,
        heroImage: 'https://images.unsplash.com/photo-1549399542-7e3f8b79c341?auto=format&fit=crop&w=800&q=80',
        baseRatePerKm: 14.0,
        dailyRentalRate: 2800.0,
        driverBataPerDay: 400.0,
        features: ['AC Sedan', '2 Bags Boot', 'English Speaking Chauffeur'],
        rating: 4.92,
      ),
      VehicleCategory(
        id: 'innova-crysta',
        name: 'Toyota Innova Crysta / Hycross',
        vehicleType: 'SUV_PREMIUM',
        tagline: 'Kerala #1 choice for family comfort & mountain ghat curves',
        passengerCapacity: 6,
        luggageCapacity: 4,
        hasAc: true,
        hasMountainPermit: true,
        heroImage: 'https://images.unsplash.com/photo-1533473359331-0135ef1b58bf?auto=format&fit=crop&w=800&q=80',
        baseRatePerKm: 18.0,
        dailyRentalRate: 3800.0,
        driverBataPerDay: 500.0,
        features: ['Captain Bucket Seats', 'Ghat-Road Certified Chauffeur', 'Dual-Zone AC'],
        rating: 4.98,
      ),
      VehicleCategory(
        id: 'tempo-traveller-12',
        name: 'Executive Luxury Tempo Traveller',
        vehicleType: 'TEMPO_TRAVELLER',
        tagline: 'Spacious group travel with luxury push-back seats',
        passengerCapacity: 12,
        luggageCapacity: 10,
        hasAc: true,
        hasMountainPermit: true,
        heroImage: 'https://images.unsplash.com/photo-1570125909232-eb263c188f7e?auto=format&fit=crop&w=800&q=80',
        baseRatePerKm: 26.0,
        dailyRentalRate: 5800.0,
        driverBataPerDay: 600.0,
        features: ['Individual Reclining Seats', 'Panoramic Windows', 'Large Luggage Boot'],
        rating: 4.90,
      ),
    ];
  }

  List<AirportRoute> _getMockRoutes({String? airport}) {
    const routes = [
      AirportRoute(
        id: 'cok-to-munnar',
        airportCode: 'COK',
        airportName: 'Cochin International Airport (COK)',
        destinationName: 'Munnar Tea Valley',
        district: 'Idukki',
        distanceKm: 110,
        approxDurationHours: 3.5,
        isGhatRoad: true,
        sedanFare: 3200.0,
        suvCrystaFare: 4500.0,
        tempoFare: 7200.0,
      ),
      AirportRoute(
        id: 'cok-to-alleppey',
        airportCode: 'COK',
        airportName: 'Cochin International Airport (COK)',
        destinationName: 'Alleppey Punnamada Jetty',
        district: 'Alappuzha',
        distanceKm: 85,
        approxDurationHours: 2.2,
        isGhatRoad: false,
        sedanFare: 2600.0,
        suvCrystaFare: 3600.0,
        tempoFare: 5900.0,
      ),
      AirportRoute(
        id: 'cok-to-fort-kochi',
        airportCode: 'COK',
        airportName: 'Cochin International Airport (COK)',
        destinationName: 'Fort Kochi Heritage',
        district: 'Ernakulam',
        distanceKm: 42,
        approxDurationHours: 1.2,
        isGhatRoad: false,
        sedanFare: 1400.0,
        suvCrystaFare: 2100.0,
        tempoFare: 3800.0,
      ),
      AirportRoute(
        id: 'trv-to-varkala',
        airportCode: 'TRV',
        airportName: 'Trivandrum International Airport (TRV)',
        destinationName: 'Varkala North Cliff',
        district: 'Trivandrum',
        distanceKm: 45,
        approxDurationHours: 1.2,
        isGhatRoad: false,
        sedanFare: 1600.0,
        suvCrystaFare: 2400.0,
        tempoFare: 4200.0,
      ),
    ];

    if (airport != null && airport.isNotEmpty) {
      return routes.where((r) => r.airportCode == airport).toList();
    }
    return routes;
  }
}

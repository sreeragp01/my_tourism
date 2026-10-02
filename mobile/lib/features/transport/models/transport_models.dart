class VehicleCategory {
  final String id;
  final String name;
  final String vehicleType;
  final String tagline;
  final int passengerCapacity;
  final int luggageCapacity;
  final bool hasAc;
  final bool hasMountainPermit;
  final String heroImage;
  final double baseRatePerKm;
  final double dailyRentalRate;
  final double driverBataPerDay;
  final List<String> features;
  final double rating;

  const VehicleCategory({
    required this.id,
    required this.name,
    required this.vehicleType,
    required this.tagline,
    required this.passengerCapacity,
    required this.luggageCapacity,
    this.hasAc = true,
    this.hasMountainPermit = true,
    required this.heroImage,
    required this.baseRatePerKm,
    required this.dailyRentalRate,
    required this.driverBataPerDay,
    this.features = const [],
    this.rating = 4.95,
  });

  factory VehicleCategory.fromJson(Map<String, dynamic> json) {
    final rawFeat = json['features'] as List<dynamic>? ?? [];
    return VehicleCategory(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Tourist Cab',
      vehicleType: json['vehicle_type'] as String? ?? 'SUV_PREMIUM',
      tagline: json['tagline'] as String? ?? '',
      passengerCapacity: (json['passenger_capacity'] as num?)?.toInt() ?? 4,
      luggageCapacity: (json['luggage_capacity'] as num?)?.toInt() ?? 3,
      hasAc: json['has_ac'] as bool? ?? true,
      hasMountainPermit: json['has_mountain_permit'] as bool? ?? true,
      heroImage: json['hero_image'] as String? ?? '',
      baseRatePerKm: (json['base_rate_per_km'] as num?)?.toDouble() ?? 18.0,
      dailyRentalRate: (json['daily_rental_rate'] as num?)?.toDouble() ?? 3800.0,
      driverBataPerDay: (json['driver_bata_per_day'] as num?)?.toDouble() ?? 500.0,
      features: rawFeat.map((e) => e.toString()).toList(),
      rating: (json['rating'] as num?)?.toDouble() ?? 4.95,
    );
  }
}

class AirportRoute {
  final String id;
  final String airportCode;
  final String airportName;
  final String destinationName;
  final String district;
  final int distanceKm;
  final double approxDurationHours;
  final bool isGhatRoad;
  final double sedanFare;
  final double suvCrystaFare;
  final double tempoFare;

  const AirportRoute({
    required this.id,
    required this.airportCode,
    required this.airportName,
    required this.destinationName,
    required this.district,
    required this.distanceKm,
    required this.approxDurationHours,
    required this.isGhatRoad,
    required this.sedanFare,
    required this.suvCrystaFare,
    required this.tempoFare,
  });

  factory AirportRoute.fromJson(Map<String, dynamic> json) {
    return AirportRoute(
      id: json['id'] as String? ?? '',
      airportCode: json['airport_code'] as String? ?? 'COK',
      airportName: json['airport_name'] as String? ?? '',
      destinationName: json['destination_name'] as String? ?? '',
      district: json['district'] as String? ?? '',
      distanceKm: (json['distance_km'] as num?)?.toInt() ?? 100,
      approxDurationHours: (json['approx_duration_hours'] as num?)?.toDouble() ?? 3.0,
      isGhatRoad: json['is_ghat_road'] as bool? ?? false,
      sedanFare: (json['sedan_fare'] as num?)?.toDouble() ?? 3000.0,
      suvCrystaFare: (json['suv_crysta_fare'] as num?)?.toDouble() ?? 4500.0,
      tempoFare: (json['tempo_fare'] as num?)?.toDouble() ?? 7000.0,
    );
  }
}

class CabBookingResult {
  final String bookingReference;
  final String travelerName;
  final String pickupLocation;
  final String dropLocation;
  final String pickupDate;
  final String pickupTime;
  final String vehicleName;
  final String plateNumber;
  final String driverName;
  final String driverPhone;
  final String driverWhatsApp;
  final double totalFare;
  final String nameboardText;

  const CabBookingResult({
    required this.bookingReference,
    required this.travelerName,
    required this.pickupLocation,
    required this.dropLocation,
    required this.pickupDate,
    required this.pickupTime,
    required this.vehicleName,
    required this.plateNumber,
    required this.driverName,
    required this.driverPhone,
    required this.driverWhatsApp,
    required this.totalFare,
    this.nameboardText = '',
  });

  factory CabBookingResult.fromJson(Map<String, dynamic> json) {
    final vehicleDetails = json['vehicle_details'] as Map<String, dynamic>? ?? {};
    final driverDetails = json['driver_details'] as Map<String, dynamic>? ?? {};

    return CabBookingResult(
      bookingReference: json['booking_reference'] as String? ?? 'CAB-2026-0001',
      travelerName: json['traveler_name'] as String? ?? 'Traveler',
      pickupLocation: json['pickup_location'] as String? ?? '',
      dropLocation: json['drop_location'] as String? ?? '',
      pickupDate: json['pickup_date'] as String? ?? '',
      pickupTime: json['pickup_time'] as String? ?? '',
      vehicleName: vehicleDetails['name'] as String? ?? 'Toyota Innova Crysta',
      plateNumber: vehicleDetails['plate_number'] as String? ?? 'KL-07-CD-4589',
      driverName: driverDetails['name'] as String? ?? 'Rajesh Kumar',
      driverPhone: driverDetails['phone'] as String? ?? '+91 94470 54321',
      driverWhatsApp: driverDetails['whatsapp'] as String? ?? '+919447054321',
      totalFare: (json['total_fare'] as num?)?.toDouble() ?? 0.0,
      nameboardText: json['nameboard_text'] as String? ?? '',
    );
  }
}

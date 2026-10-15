class AdminStats {
  final int totalUsers;
  final int activeUsers;
  final int totalBookings;
  final double grossGmv;
  final int totalPackages;
  final int totalDrivers;
  final int totalDestinations;

  const AdminStats({
    required this.totalUsers,
    required this.activeUsers,
    required this.totalBookings,
    required this.grossGmv,
    required this.totalPackages,
    required this.totalDrivers,
    required this.totalDestinations,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      totalUsers: (json['total_users'] as num?)?.toInt() ?? 0,
      activeUsers: (json['active_users'] as num?)?.toInt() ?? 0,
      totalBookings: (json['total_bookings'] as num?)?.toInt() ?? 0,
      grossGmv: (json['gross_gmv'] as num?)?.toDouble() ?? 0.0,
      totalPackages: (json['total_packages'] as num?)?.toInt() ?? 0,
      totalDrivers: (json['total_drivers'] as num?)?.toInt() ?? 0,
      totalDestinations: (json['total_destinations'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminUser {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String phone;
  final List<String> roles;
  final bool isActive;
  final bool isStaff;
  final String createdAt;
  final int ecoScore;
  final String ecoTier;
  final int tripsCompleted;

  const AdminUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.roles,
    required this.isActive,
    required this.isStaff,
    required this.createdAt,
    required this.ecoScore,
    required this.ecoTier,
    required this.tripsCompleted,
  });

  String get fullName {
    final name = '$firstName $lastName'.trim();
    return name.isNotEmpty ? name : email.split('@').first;
  }

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      roles: (json['roles'] as List?)?.map((e) => e.toString()).toList() ?? const ['CUSTOMER'],
      isActive: json['is_active'] == true,
      isStaff: json['is_staff'] == true,
      createdAt: json['created_at']?.toString() ?? '',
      ecoScore: (json['eco_score'] as num?)?.toInt() ?? 0,
      ecoTier: json['eco_tier']?.toString() ?? 'Seedling Traveler',
      tripsCompleted: (json['trips_completed'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminDriver {
  final String id;
  final String name;
  final String phone;
  final String whatsapp;
  final String licenseNumber;
  final String vehicleType;
  final String vehiclePlateNumber;
  final String district;
  final double rating;
  final int tripsCompleted;
  final bool isVerified;
  final bool isAvailable;

  const AdminDriver({
    required this.id,
    required this.name,
    required this.phone,
    required this.whatsapp,
    required this.licenseNumber,
    required this.vehicleType,
    required this.vehiclePlateNumber,
    required this.district,
    required this.rating,
    required this.tripsCompleted,
    required this.isVerified,
    required this.isAvailable,
  });

  factory AdminDriver.fromJson(Map<String, dynamic> json) {
    return AdminDriver(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      whatsapp: json['whatsapp']?.toString() ?? '',
      licenseNumber: json['license_number']?.toString() ?? '',
      vehicleType: json['vehicle_type']?.toString() ?? 'SUV_PREMIUM',
      vehiclePlateNumber: json['vehicle_plate_number']?.toString() ?? '',
      district: json['district']?.toString() ?? 'Ernakulam',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.95,
      tripsCompleted: (json['trips_completed'] as num?)?.toInt() ?? 0,
      isVerified: json['is_verified'] == true,
      isAvailable: json['is_available'] == true,
    );
  }
}

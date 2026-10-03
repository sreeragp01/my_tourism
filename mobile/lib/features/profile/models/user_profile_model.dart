class BadgeItem {
  final String id;
  final String title;
  final String icon;
  final String description;
  final String earnedAt;

  const BadgeItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.description,
    required this.earnedAt,
  });

  factory BadgeItem.fromJson(Map<String, dynamic> json) {
    return BadgeItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      icon: json['icon']?.toString() ?? 'star',
      description: json['description']?.toString() ?? '',
      earnedAt: json['earned_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'icon': icon,
        'description': description,
        'earned_at': earnedAt,
      };
}

class OfflinePackageItem {
  final String id;
  final String name;
  final String size;
  final bool isDownloaded;
  final String includes;

  const OfflinePackageItem({
    required this.id,
    required this.name,
    required this.size,
    required this.isDownloaded,
    required this.includes,
  });

  OfflinePackageItem copyWith({bool? isDownloaded}) {
    return OfflinePackageItem(
      id: id,
      name: name,
      size: size,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      includes: includes,
    );
  }

  factory OfflinePackageItem.fromJson(Map<String, dynamic> json) {
    return OfflinePackageItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      size: json['size']?.toString() ?? '',
      isDownloaded: json['is_downloaded'] == true,
      includes: json['includes']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'size': size,
        'is_downloaded': isDownloaded,
        'includes': includes,
      };
}

class UserProfile {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String phone;
  final String? avatarUrl;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final List<String> roles;

  // ICE & Safety Hub integration
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String bloodGroup;
  final String medicalNotes;

  // AI Planner Personalization
  final String dietaryPreference;
  final String travelPace;
  final bool accessibilityRequired;

  // Eco-Tourism Passport
  final int ecoScore;
  final String ecoTier;
  final int tripsCompleted;
  final int evMiles;
  final double carbonOffsetKg;
  final List<BadgeItem> badges;

  // Offline Corridor Packages
  final List<OfflinePackageItem> offlinePackages;

  const UserProfile({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.avatarUrl,
    this.isEmailVerified = true,
    this.isPhoneVerified = true,
    this.roles = const ['CUSTOMER'],
    required this.emergencyContactName,
    required this.emergencyContactPhone,
    required this.bloodGroup,
    required this.medicalNotes,
    required this.dietaryPreference,
    required this.travelPace,
    this.accessibilityRequired = false,
    required this.ecoScore,
    required this.ecoTier,
    required this.tripsCompleted,
    required this.evMiles,
    required this.carbonOffsetKg,
    required this.badges,
    required this.offlinePackages,
  });

  String get fullName => '$firstName $lastName'.trim();

  UserProfile copyWith({
    String? firstName,
    String? lastName,
    String? phone,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? bloodGroup,
    String? medicalNotes,
    String? dietaryPreference,
    String? travelPace,
    bool? accessibilityRequired,
    List<OfflinePackageItem>? offlinePackages,
  }) {
    return UserProfile(
      id: id,
      email: email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl,
      isEmailVerified: isEmailVerified,
      isPhoneVerified: isPhoneVerified,
      roles: roles,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      medicalNotes: medicalNotes ?? this.medicalNotes,
      dietaryPreference: dietaryPreference ?? this.dietaryPreference,
      travelPace: travelPace ?? this.travelPace,
      accessibilityRequired: accessibilityRequired ?? this.accessibilityRequired,
      ecoScore: ecoScore,
      ecoTier: ecoTier,
      tripsCompleted: tripsCompleted,
      evMiles: evMiles,
      carbonOffsetKg: carbonOffsetKg,
      badges: badges,
      offlinePackages: offlinePackages ?? this.offlinePackages,
    );
  }

  factory UserProfile.mockDefault() {
    return const UserProfile(
      id: 'd0a1b2c3-4d5e-6f7a-8b9c-0d1e2f3a4b5c',
      email: 'sreerag@keralink.travel',
      firstName: 'Sreerag',
      lastName: 'P.',
      phone: '+91 98765 43210',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
      isEmailVerified: true,
      isPhoneVerified: true,
      roles: ['CUSTOMER'],
      emergencyContactName: 'Ananya S. (Sister)',
      emergencyContactPhone: '+91 94471 23456',
      bloodGroup: 'O+ Positive',
      medicalNotes: 'No major allergies. Carries mild asthma inhaler.',
      dietaryPreference: 'Traditional Kerala Sadya (Veg)',
      travelPace: 'Balanced (2-3 stops/day)',
      accessibilityRequired: false,
      ecoScore: 92,
      ecoTier: 'Backwater Guardian',
      tripsCompleted: 3,
      evMiles: 142,
      carbonOffsetKg: 58.4,
      badges: [
        BadgeItem(
          id: 'munnar_mist',
          title: 'Munnar Mist Explorer',
          icon: 'landscape',
          description: 'Navigated high-altitude tea trails of Lockhart Valley',
          earnedAt: 'Aug 2026',
        ),
        BadgeItem(
          id: 'backwater_guardian',
          title: 'Backwater Guardian',
          icon: 'sailing',
          description: 'Completed zero-plastic solar houseboat journey in Kumarakom',
          earnedAt: 'Sep 2026',
        ),
        BadgeItem(
          id: 'spice_route',
          title: 'Spice Route Trekker',
          icon: 'eco',
          description: 'Supported organic cardamom farmers in Thekkady',
          earnedAt: 'Sep 2026',
        ),
      ],
      offlinePackages: [
        OfflinePackageItem(
          id: 'pkg_munnar',
          name: 'Munnar & Lockhart Valley Corridor',
          size: '42 MB',
          isDownloaded: true,
          includes: 'Ghat route topo, offline SOS checkpoints, nearest CHC clinics',
        ),
        OfflinePackageItem(
          id: 'pkg_wayanad',
          name: 'Wayanad Ghat & Forest Pass',
          size: '38 MB',
          isDownloaded: false,
          includes: 'Thamarassery Churam hairpin map, wildlife sanctuary emergency contacts',
        ),
      ],
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final prof = json['profile'] is Map<String, dynamic> ? json['profile'] as Map<String, dynamic> : json;

    return UserProfile(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? 'Traveler',
      lastName: json['last_name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString(),
      isEmailVerified: json['is_email_verified'] == true,
      isPhoneVerified: json['is_phone_verified'] == true,
      roles: (json['roles'] as List?)?.map((e) => e.toString()).toList() ?? const ['CUSTOMER'],
      emergencyContactName: prof['emergency_contact_name']?.toString() ?? 'Emergency Contact',
      emergencyContactPhone: prof['emergency_contact_phone']?.toString() ?? '+91 112',
      bloodGroup: prof['blood_group']?.toString() ?? 'Unknown',
      medicalNotes: prof['medical_notes']?.toString() ?? '',
      dietaryPreference: prof['dietary_preference']?.toString() ?? 'Traditional Kerala Sadya (Veg)',
      travelPace: prof['travel_pace']?.toString() ?? 'Balanced (2-3 stops/day)',
      accessibilityRequired: prof['accessibility_required'] == true,
      ecoScore: (prof['eco_score'] as num?)?.toInt() ?? 92,
      ecoTier: prof['eco_tier']?.toString() ?? 'Eco Voyager',
      tripsCompleted: (prof['trips_completed'] as num?)?.toInt() ?? 3,
      evMiles: (prof['ev_miles'] as num?)?.toInt() ?? 142,
      carbonOffsetKg: (prof['carbon_offset_kg'] as num?)?.toDouble() ?? 58.4,
      badges: (prof['badges'] as List?)?.map((b) => BadgeItem.fromJson(b as Map<String, dynamic>)).toList() ??
          UserProfile.mockDefault().badges,
      offlinePackages: (prof['offline_packages'] as List?)
              ?.map((p) => OfflinePackageItem.fromJson(p as Map<String, dynamic>))
              .toList() ??
          UserProfile.mockDefault().offlinePackages,
    );
  }
}

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

class TravelerDocumentItem {
  final String id;
  final String type; // 'AADHAAR', 'PASSPORT', 'DRIVING_LICENSE', 'PERMIT', 'INSURANCE'
  final String title;
  final String documentNumber;
  final String status; // 'VERIFIED', 'PENDING', 'ACTIVE'
  final String issueDate;
  final String? fileUrl;

  const TravelerDocumentItem({
    required this.id,
    required this.type,
    required this.title,
    required this.documentNumber,
    required this.status,
    required this.issueDate,
    this.fileUrl,
  });

  TravelerDocumentItem copyWith({
    String? title,
    String? documentNumber,
    String? status,
    String? issueDate,
    String? fileUrl,
  }) {
    return TravelerDocumentItem(
      id: id,
      type: type,
      title: title ?? this.title,
      documentNumber: documentNumber ?? this.documentNumber,
      status: status ?? this.status,
      issueDate: issueDate ?? this.issueDate,
      fileUrl: fileUrl ?? this.fileUrl,
    );
  }

  factory TravelerDocumentItem.fromJson(Map<String, dynamic> json) {
    return TravelerDocumentItem(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'AADHAAR',
      title: json['title']?.toString() ?? 'Government ID',
      documentNumber: json['document_number']?.toString() ?? '',
      status: json['status']?.toString() ?? 'VERIFIED',
      issueDate: json['issue_date']?.toString() ?? '2026',
      fileUrl: json['file_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'document_number': documentNumber,
        'status': status,
        'issue_date': issueDate,
        if (fileUrl != null) 'file_url': fileUrl,
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

  // Verification & Travel Documents
  final List<TravelerDocumentItem> documents;

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
    this.documents = const [],
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
    List<TravelerDocumentItem>? documents,
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
      documents: documents ?? this.documents,
    );
  }

  static List<TravelerDocumentItem> defaultDocuments() => const [
        TravelerDocumentItem(
          id: 'doc_aadhaar',
          type: 'AADHAAR',
          title: 'Government Aadhaar / National ID',
          documentNumber: '•••• •••• 8421',
          status: 'VERIFIED',
          issueDate: 'UIDAI Verified',
        ),
        TravelerDocumentItem(
          id: 'doc_dl',
          type: 'DRIVING_LICENSE',
          title: 'Motor & EV Driving License',
          documentNumber: 'KL-07-2023-0094182',
          status: 'VERIFIED',
          issueDate: 'Valid till 2038',
        ),
        TravelerDocumentItem(
          id: 'doc_forest_permit',
          type: 'PERMIT',
          title: 'Kerala Forest Eco-Permit',
          documentNumber: 'KL-ECO-2026-T78',
          status: 'ACTIVE',
          issueDate: 'Season 2026',
        ),
      ];

  factory UserProfile.mockDefault() {
    return UserProfile(
      id: 'd0a1b2c3-4d5e-6f7a-8b9c-0d1e2f3a4b5c',
      email: 'traveler@keralink.travel',
      firstName: 'Traveler',
      lastName: '',
      phone: '',
      avatarUrl: null,
      isEmailVerified: true,
      isPhoneVerified: true,
      roles: const ['CUSTOMER'],
      emergencyContactName: '',
      emergencyContactPhone: '',
      bloodGroup: '',
      medicalNotes: '',
      dietaryPreference: 'Traditional Kerala Sadya (Veg)',
      travelPace: 'Balanced (2-3 stops/day)',
      accessibilityRequired: false,
      ecoScore: 92,
      ecoTier: 'Seedling Traveler',
      tripsCompleted: 3,
      evMiles: 142,
      carbonOffsetKg: 58.4,
      badges: const [],
      offlinePackages: const [],
      documents: defaultDocuments(),
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final prof = json['profile'] is Map ? json['profile'] as Map : json;

    List<BadgeItem> parseBadges() {
      try {
        final raw = prof['badges'] as List?;
        if (raw != null) {
          return raw
              .map((b) => BadgeItem.fromJson(Map<String, dynamic>.from(b as Map)))
              .toList();
        }
      } catch (_) {}
      return UserProfile.mockDefault().badges;
    }

    List<OfflinePackageItem> parseOfflinePackages() {
      try {
        final raw = prof['offline_packages'] as List?;
        if (raw != null) {
          return raw
              .map((p) => OfflinePackageItem.fromJson(Map<String, dynamic>.from(p as Map)))
              .toList();
        }
      } catch (_) {}
      return UserProfile.mockDefault().offlinePackages;
    }

    List<TravelerDocumentItem> parseDocuments() {
      try {
        final raw = prof['documents'] as List?;
        if (raw != null && raw.isNotEmpty) {
          return raw
              .map((d) => TravelerDocumentItem.fromJson(Map<String, dynamic>.from(d as Map)))
              .toList();
        }
      } catch (_) {}
      return defaultDocuments();
    }

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
      badges: parseBadges(),
      offlinePackages: parseOfflinePackages(),
      documents: parseDocuments(),
    );
  }
}

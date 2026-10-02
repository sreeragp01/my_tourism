class OperatorProfile {
  final String name;
  final String phone;
  final String whatsapp;
  final String license;
  final bool isVerified;

  const OperatorProfile({
    required this.name,
    required this.phone,
    required this.whatsapp,
    required this.license,
    this.isVerified = true,
  });

  factory OperatorProfile.fromJson(Map<String, dynamic> json) {
    return OperatorProfile(
      name: json['name'] as String? ?? 'Kerala Tour Co.',
      phone: json['phone'] as String? ?? '',
      whatsapp: json['whatsapp'] as String? ?? '',
      license: json['license'] as String? ?? 'DTPC Accredited',
      isVerified: json['is_verified'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'whatsapp': whatsapp,
    'license': license,
    'is_verified': isVerified,
  };
}

class PackageDayItinerary {
  final int day;
  final String title;
  final String description;
  final String meals;
  final String stay;

  const PackageDayItinerary({
    required this.day,
    required this.title,
    required this.description,
    required this.meals,
    required this.stay,
  });

  factory PackageDayItinerary.fromJson(Map<String, dynamic> json) {
    return PackageDayItinerary(
      day: (json['day'] as num?)?.toInt() ?? 1,
      title: json['title'] as String? ?? 'Day Exploration',
      description: json['description'] as String? ?? '',
      meals: json['meals'] as String? ?? 'Breakfast included',
      stay: json['stay'] as String? ?? 'Resort Stay',
    );
  }

  Map<String, dynamic> toJson() => {
    'day': day,
    'title': title,
    'description': description,
    'meals': meals,
    'stay': stay,
  };
}

class TourPackage {
  final String id;
  final String title;
  final String slug;
  final String category;
  final String tagline;
  final String description;
  final int durationDays;
  final int durationNights;
  final String duration;
  final String startCity;
  final String endCity;
  final List<String> destinationsCovered;
  final double pricePerPerson;
  final double? originalPrice;
  final int savingsPercent;
  final String heroImage;
  final List<String> galleryImages;
  final List<String> highlights;
  final List<String> inclusions;
  final List<String> exclusions;
  final List<PackageDayItinerary> itinerary;
  final double rating;
  final int reviewCount;
  final bool isFeatured;
  final OperatorProfile operator;

  const TourPackage({
    required this.id,
    required this.title,
    required this.slug,
    required this.category,
    required this.tagline,
    this.description = '',
    required this.durationDays,
    required this.durationNights,
    required this.duration,
    required this.startCity,
    required this.endCity,
    required this.destinationsCovered,
    required this.pricePerPerson,
    this.originalPrice,
    this.savingsPercent = 0,
    required this.heroImage,
    this.galleryImages = const [],
    this.highlights = const [],
    this.inclusions = const [],
    this.exclusions = const [],
    this.itinerary = const [],
    this.rating = 4.9,
    this.reviewCount = 12,
    this.isFeatured = false,
    required this.operator,
  });

  factory TourPackage.fromJson(Map<String, dynamic> json) {
    final rawDest = json['destinations_covered'] as List<dynamic>? ?? [];
    final rawGall = json['gallery_images'] as List<dynamic>? ?? [];
    final rawHigh = json['highlights'] as List<dynamic>? ?? [];
    final rawInc = json['inclusions'] as List<dynamic>? ?? [];
    final rawExc = json['exclusions'] as List<dynamic>? ?? [];
    final rawItin = json['itinerary'] as List<dynamic>? ?? [];

    return TourPackage(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      category: json['category'] as String? ?? 'HILL_STATION',
      tagline: json['tagline'] as String? ?? '',
      description: json['description'] as String? ?? '',
      durationDays: (json['duration_days'] as num?)?.toInt() ?? 3,
      durationNights: (json['duration_nights'] as num?)?.toInt() ?? 2,
      duration: json['duration'] as String? ?? '3D / 2N',
      startCity: json['start_city'] as String? ?? 'Kochi',
      endCity: json['end_city'] as String? ?? 'Kochi',
      destinationsCovered: rawDest.map((e) => e.toString()).toList(),
      pricePerPerson: (json['price_per_person'] as num?)?.toDouble() ?? 0.0,
      originalPrice: (json['original_price'] as num?)?.toDouble(),
      savingsPercent: (json['savings_percent'] as num?)?.toInt() ?? 0,
      heroImage: json['hero_image'] as String? ?? '',
      galleryImages: rawGall.map((e) => e.toString()).toList(),
      highlights: rawHigh.map((e) => e.toString()).toList(),
      inclusions: rawInc.map((e) => e.toString()).toList(),
      exclusions: rawExc.map((e) => e.toString()).toList(),
      itinerary: rawItin.map((i) => PackageDayItinerary.fromJson(i as Map<String, dynamic>)).toList(),
      rating: (json['rating'] as num?)?.toDouble() ?? 4.9,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      isFeatured: json['is_featured'] as bool? ?? false,
      operator: OperatorProfile.fromJson(json['operator'] as Map<String, dynamic>? ?? {}),
    );
  }
}

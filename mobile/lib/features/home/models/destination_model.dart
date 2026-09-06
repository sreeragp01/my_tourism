class Attraction {
  final String id;
  final String name;
  final String category;
  final String description;
  final String image;
  final double latitude;
  final double longitude;
  final int typicalDurationMins;
  final bool rainFriendly;

  const Attraction({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.image,
    required this.latitude,
    required this.longitude,
    this.typicalDurationMins = 90,
    this.rainFriendly = false,
  });

  factory Attraction.fromJson(Map<String, dynamic> json) {
    return Attraction(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? 'SIGHTSEEING',
      description: json['description']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      typicalDurationMins: json['typical_duration_mins'] ?? 90,
      rainFriendly: json['rain_friendly'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'description': description,
        'image': image,
        'latitude': latitude,
        'longitude': longitude,
        'typical_duration_mins': typicalDurationMins,
        'rain_friendly': rainFriendly,
      };
}

class Destination {
  final String id;
  final String name;
  final String slug;
  final String district;
  final String tagline;
  final String description;
  final String heroImage;
  final List<String> galleryImages;
  final double latitude;
  final double longitude;
  final String bestSeason;
  final List<String> tags;
  final Map<String, double> preferences;
  final bool familyFriendly;
  final bool seniorFriendly;
  final int averageStayDays;
  final List<Attraction> attractions;

  const Destination({
    required this.id,
    required this.name,
    required this.slug,
    required this.district,
    required this.tagline,
    required this.description,
    required this.heroImage,
    this.galleryImages = const [],
    required this.latitude,
    required this.longitude,
    this.bestSeason = 'October to March',
    this.tags = const [],
    this.preferences = const {},
    this.familyFriendly = true,
    this.seniorFriendly = true,
    this.averageStayDays = 2,
    this.attractions = const [],
  });

  factory Destination.fromJson(Map<String, dynamic> json) {
    final prefsRaw = json['preferences'] as Map<String, dynamic>? ?? {};
    final prefs = prefsRaw.map((k, v) => MapEntry(k, (v as num).toDouble()));

    return Destination(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      tagline: json['tagline']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      heroImage: json['hero_image']?.toString() ?? '',
      galleryImages: (json['gallery_images'] as List?)?.map((e) => e.toString()).toList() ?? [],
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      bestSeason: json['best_season']?.toString() ?? 'October to March',
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      preferences: prefs,
      familyFriendly: json['family_friendly'] == true,
      seniorFriendly: json['senior_friendly'] == true,
      averageStayDays: json['average_stay_days'] ?? 2,
      attractions: (json['attractions'] as List?)
              ?.map((e) => Attraction.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'district': district,
        'tagline': tagline,
        'description': description,
        'hero_image': heroImage,
        'gallery_images': galleryImages,
        'latitude': latitude,
        'longitude': longitude,
        'best_season': bestSeason,
        'tags': tags,
        'preferences': preferences,
        'family_friendly': familyFriendly,
        'senior_friendly': seniorFriendly,
        'average_stay_days': averageStayDays,
        'attractions': attractions.map((a) => a.toJson()).toList(),
      };
}

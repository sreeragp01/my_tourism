class GpsPoint {
  final double latitude;
  final double longitude;
  final String? name;

  const GpsPoint({
    required this.latitude,
    required this.longitude,
    this.name,
  });

  factory GpsPoint.fromJson(Map<String, dynamic> json) {
    return GpsPoint(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      name: json['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    if (name != null) 'name': name,
  };
}

class RouteResult {
  final double distanceKm;
  final int durationMinutes;
  final bool isGhatRoad;
  final List<String> advisories;
  final List<GpsPoint> polylinePoints;
  final int hairpinsCount;
  final String summary;

  const RouteResult({
    required this.distanceKm,
    required this.durationMinutes,
    required this.isGhatRoad,
    required this.advisories,
    required this.polylinePoints,
    this.hairpinsCount = 0,
    required this.summary,
  });

  factory RouteResult.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['polyline_points'] as List<dynamic>? ?? [];
    final points = rawPoints.map((p) => GpsPoint.fromJson(p as Map<String, dynamic>)).toList();
    final rawAdvisories = json['advisories'] as List<dynamic>? ?? [];

    return RouteResult(
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 0,
      isGhatRoad: json['is_ghat_road'] as bool? ?? false,
      advisories: rawAdvisories.map((a) => a.toString()).toList(),
      polylinePoints: points,
      hairpinsCount: (json['hairpins_count'] as num?)?.toInt() ?? 0,
      summary: json['summary'] as String? ?? 'Scenic Kerala Route',
    );
  }
}

class NearbyPlace {
  final String id;
  final String title;
  final String type; // ATTRACTION, EXPERIENCE, FOOD
  final String category;
  final double distanceKm;
  final double latitude;
  final double longitude;
  final bool rainFriendly;
  final double rating;
  final double? pricePerPerson;
  final String? meetingPoint;
  final String? image;

  const NearbyPlace({
    required this.id,
    required this.title,
    required this.type,
    required this.category,
    required this.distanceKm,
    required this.latitude,
    required this.longitude,
    required this.rainFriendly,
    this.rating = 4.8,
    this.pricePerPerson,
    this.meetingPoint,
    this.image,
  });

  factory NearbyPlace.fromJson(Map<String, dynamic> json) {
    return NearbyPlace(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? json['name'] as String? ?? 'Kerala Attraction',
      type: json['type'] as String? ?? 'ATTRACTION',
      category: json['category'] as String? ?? 'GENERAL',
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      rainFriendly: json['rain_friendly'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
      pricePerPerson: (json['price_per_person'] as num?)?.toDouble(),
      meetingPoint: json['meeting_point'] as String?,
      image: json['image'] as String?,
    );
  }
}

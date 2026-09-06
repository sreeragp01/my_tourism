class Accommodation {
  final String id;
  final String destinationId;
  final String name;
  final String type;
  final String tagline;
  final String description;
  final String heroImage;
  final int starRating;
  final double basePricePerNight;
  final int ecoGreenScore;
  final List<String> amenities;
  final int aiSuitabilityScore;

  const Accommodation({
    required this.id,
    required this.destinationId,
    required this.name,
    required this.type,
    required this.tagline,
    required this.description,
    required this.heroImage,
    required this.starRating,
    required this.basePricePerNight,
    required this.ecoGreenScore,
    this.amenities = const [],
    this.aiSuitabilityScore = 90,
  });

  factory Accommodation.fromJson(Map<String, dynamic> json) {
    return Accommodation(
      id: json['id'] as String? ?? '',
      destinationId: json['destination_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'BOUTIQUE_RESORT',
      tagline: json['tagline'] as String? ?? '',
      description: json['description'] as String? ?? '',
      heroImage: json['hero_image'] as String? ?? '',
      starRating: (json['star_rating'] as num?)?.toInt() ?? 4,
      basePricePerNight: (json['base_price_per_night'] as num?)?.toDouble() ?? 0.0,
      ecoGreenScore: (json['eco_green_score'] as num?)?.toInt() ?? 80,
      amenities: (json['amenities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      aiSuitabilityScore: (json['ai_suitability_score'] as num?)?.toInt() ?? 90,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'destination_id': destinationId,
      'name': name,
      'type': type,
      'tagline': tagline,
      'description': description,
      'hero_image': heroImage,
      'star_rating': starRating,
      'base_price_per_night': basePricePerNight,
      'eco_green_score': ecoGreenScore,
      'amenities': amenities,
      'ai_suitability_score': aiSuitabilityScore,
    };
  }
}

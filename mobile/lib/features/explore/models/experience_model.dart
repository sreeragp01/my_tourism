class Experience {
  final String id;
  final String orgId;
  final String destinationId;
  final String title;
  final String category;
  final String description;
  final double pricePerPerson;
  final double durationHours;
  final int maxGroupSize;
  final String heroImage;
  final List<String> includedItems;
  final String meetingPoint;
  final String hostName;
  final String hostRole;
  final double rating;
  final int reviewCount;
  final bool verified;
  final bool rainFriendly;
  final String? rainAlternativeId;
  final Map<String, dynamic> explanation;

  const Experience({
    required this.id,
    required this.orgId,
    required this.destinationId,
    required this.title,
    required this.category,
    required this.description,
    required this.pricePerPerson,
    required this.durationHours,
    this.maxGroupSize = 10,
    required this.heroImage,
    this.includedItems = const [],
    required this.meetingPoint,
    required this.hostName,
    required this.hostRole,
    this.rating = 4.9,
    this.reviewCount = 0,
    this.verified = true,
    this.rainFriendly = false,
    this.rainAlternativeId,
    this.explanation = const {},
  });

  factory Experience.fromJson(Map<String, dynamic> json) {
    return Experience(
      id: json['id']?.toString() ?? '',
      orgId: json['org_id']?.toString() ?? '',
      destinationId: json['destination_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString() ?? 'CULTURE',
      description: json['description']?.toString() ?? '',
      pricePerPerson: (json['price_per_person'] as num?)?.toDouble() ?? 0.0,
      durationHours: (json['duration_hours'] as num?)?.toDouble() ?? 1.0,
      maxGroupSize: json['max_group_size'] ?? 10,
      heroImage: json['hero_image']?.toString() ?? '',
      includedItems: (json['included_items'] as List?)?.map((e) => e.toString()).toList() ?? [],
      meetingPoint: json['meeting_point']?.toString() ?? '',
      hostName: json['host_name']?.toString() ?? '',
      hostRole: json['host_role']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.9,
      reviewCount: json['review_count'] ?? 0,
      verified: json['verified'] == true,
      rainFriendly: json['rain_friendly'] == true,
      rainAlternativeId: json['rain_alternative_id']?.toString(),
      explanation: json['explanation'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'org_id': orgId,
        'destination_id': destinationId,
        'title': title,
        'category': category,
        'description': description,
        'price_per_person': pricePerPerson,
        'duration_hours': durationHours,
        'max_group_size': maxGroupSize,
        'hero_image': heroImage,
        'included_items': includedItems,
        'meeting_point': meetingPoint,
        'host_name': hostName,
        'host_role': hostRole,
        'rating': rating,
        'review_count': reviewCount,
        'verified': verified,
        'rain_friendly': rainFriendly,
        'rain_alternative_id': rainAlternativeId,
        'explanation': explanation,
      };
}

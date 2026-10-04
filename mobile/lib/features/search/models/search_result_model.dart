import '../../home/models/destination_model.dart';
import '../../explore/models/experience_model.dart';
import '../../explore/models/accommodation_model.dart';

class SearchFilter {
  final String query;
  final String? destination;
  final String? category;
  final String type;
  final double? minPrice;
  final double? maxPrice;
  final bool? rainFriendly;
  final bool? familyFriendly;
  final double? minRating;
  final double? lat;
  final double? lng;
  final double? radiusKm;
  final int page;
  final int pageSize;

  const SearchFilter({
    this.query = '',
    this.destination,
    this.category,
    this.type = 'all',
    this.minPrice,
    this.maxPrice,
    this.rainFriendly,
    this.familyFriendly,
    this.minRating,
    this.lat,
    this.lng,
    this.radiusKm,
    this.page = 1,
    this.pageSize = 20,
  });

  SearchFilter copyWith({
    String? query,
    String? destination,
    String? category,
    String? type,
    double? minPrice,
    double? maxPrice,
    bool? rainFriendly,
    bool? familyFriendly,
    double? minRating,
    double? lat,
    double? lng,
    double? radiusKm,
    int? page,
    int? pageSize,
  }) {
    return SearchFilter(
      query: query ?? this.query,
      destination: destination ?? this.destination,
      category: category ?? this.category,
      type: type ?? this.type,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      rainFriendly: rainFriendly ?? this.rainFriendly,
      familyFriendly: familyFriendly ?? this.familyFriendly,
      minRating: minRating ?? this.minRating,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      radiusKm: radiusKm ?? this.radiusKm,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  Map<String, String> toQueryParams() {
    final params = <String, String>{};
    if (query.trim().isNotEmpty) params['q'] = query.trim();
    if (destination != null && destination!.isNotEmpty) params['destination'] = destination!;
    if (category != null && category!.isNotEmpty && category != 'ALL') params['category'] = category!;
    if (type.isNotEmpty && type != 'all') params['type'] = type;
    if (minPrice != null) params['min_price'] = minPrice!.toStringAsFixed(0);
    if (maxPrice != null) params['max_price'] = maxPrice!.toStringAsFixed(0);
    if (rainFriendly != null) params['rain_friendly'] = rainFriendly.toString();
    if (familyFriendly != null) params['family_friendly'] = familyFriendly.toString();
    if (minRating != null) params['min_rating'] = minRating!.toStringAsFixed(1);
    if (lat != null) params['lat'] = lat!.toStringAsFixed(4);
    if (lng != null) params['lng'] = lng!.toStringAsFixed(4);
    if (radiusKm != null) params['radius_km'] = radiusKm!.toStringAsFixed(1);
    params['page'] = page.toString();
    params['page_size'] = pageSize.toString();
    return params;
  }
}

class SearchResults {
  final String query;
  final int totalCount;
  final int page;
  final int pageSize;
  final bool hasNext;
  final List<Destination> destinations;
  final List<Experience> experiences;
  final List<Accommodation> accommodations;
  final List<Attraction> attractions;

  const SearchResults({
    required this.query,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.hasNext,
    this.destinations = const [],
    this.experiences = const [],
    this.accommodations = const [],
    this.attractions = const [],
  });

  bool get isEmpty =>
      destinations.isEmpty &&
      experiences.isEmpty &&
      accommodations.isEmpty &&
      attractions.isEmpty;

  SearchResults append(SearchResults next) {
    return SearchResults(
      query: next.query.isNotEmpty ? next.query : query,
      totalCount: next.totalCount,
      page: next.page,
      pageSize: next.pageSize,
      hasNext: next.hasNext,
      destinations: [...destinations, ...next.destinations],
      experiences: [...experiences, ...next.experiences],
      accommodations: [...accommodations, ...next.accommodations],
      attractions: [...attractions, ...next.attractions],
    );
  }

  SearchResults copyWith({
    String? query,
    int? totalCount,
    int? page,
    int? pageSize,
    bool? hasNext,
    List<Destination>? destinations,
    List<Experience>? experiences,
    List<Accommodation>? accommodations,
    List<Attraction>? attractions,
  }) {
    return SearchResults(
      query: query ?? this.query,
      totalCount: totalCount ?? this.totalCount,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      hasNext: hasNext ?? this.hasNext,
      destinations: destinations ?? this.destinations,
      experiences: experiences ?? this.experiences,
      accommodations: accommodations ?? this.accommodations,
      attractions: attractions ?? this.attractions,
    );
  }

  factory SearchResults.empty() {
    return const SearchResults(
      query: '',
      totalCount: 0,
      page: 1,
      pageSize: 20,
      hasNext: false,
    );
  }

  factory SearchResults.fromJson(Map<String, dynamic> json) {
    final destList = (json['destinations'] as List<dynamic>?)
            ?.map((e) => Destination.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    final expList = (json['experiences'] as List<dynamic>?)
            ?.map((e) => Experience.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    final accList = (json['accommodations'] as List<dynamic>?)
            ?.map((e) => Accommodation.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    final attList = (json['attractions'] as List<dynamic>?)
            ?.map((e) => Attraction.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    return SearchResults(
      query: json['query'] as String? ?? '',
      totalCount: (json['total_count'] as num?)?.toInt() ??
          (destList.length + expList.length + accList.length + attList.length),
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['page_size'] as num?)?.toInt() ?? 20,
      hasNext: json['has_next'] as bool? ?? false,
      destinations: destList,
      experiences: expList,
      accommodations: accList,
      attractions: attList,
    );
  }
}

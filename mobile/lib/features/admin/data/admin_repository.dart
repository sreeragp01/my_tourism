import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/admin_models.dart';

class AdminRepository {
  final ApiClient apiClient;

  AdminRepository({required this.apiClient});

  /// Fetch Central Command platform KPIs
  Future<AdminStats> getStats() async {
    final response = await apiClient.get(ApiConstants.adminStats);
    return AdminStats.fromJson(response as Map<String, dynamic>);
  }

  /// Fetch registered users list with monetization details
  Future<List<AdminUser>> getUsers() async {
    final response = await apiClient.get(ApiConstants.adminUsers);
    if (response is Map<String, dynamic>) {
      final list = response['results'] as List? ?? [];
      return list.map((e) => AdminUser.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// Toggle user active status
  Future<bool> toggleUserStatus(String userId) async {
    final response = await apiClient.post(
      ApiConstants.adminUserAction(userId),
      body: {'action': 'TOGGLE_STATUS'},
    );
    if (response is Map<String, dynamic>) {
      return response['status'] == 'ok';
    }
    return false;
  }

  /// Fetch all tour packages
  Future<List<Map<String, dynamic>>> getPackages() async {
    final response = await apiClient.get(ApiConstants.packages);
    if (response is List) {
      return response.cast<Map<String, dynamic>>();
    } else if (response is Map<String, dynamic> && response['results'] is List) {
      return (response['results'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Create a new tour package
  Future<bool> createPackage({
    required String title,
    required String category,
    required String tagline,
    required String description,
    required int durationDays,
    required int durationNights,
    required String startCity,
    required String endCity,
    required List<String> destinationsCovered,
    required double pricePerPerson,
    required String heroImage,
    required String operatorName,
    required String operatorPhone,
    required String operatorWhatsapp,
    List<String> highlights = const [],
    List<String> inclusions = const [],
  }) async {
    final body = {
      'title': title,
      'category': category,
      'tagline': tagline,
      'description': description,
      'duration_days': durationDays,
      'duration_nights': durationNights,
      'start_city': startCity,
      'end_city': endCity,
      'destinations_covered': destinationsCovered,
      'price_per_person': pricePerPerson,
      'hero_image': heroImage,
      'operator_name': operatorName,
      'operator_phone': operatorPhone,
      'operator_whatsapp': operatorWhatsapp,
      'highlights': highlights,
      'inclusions': inclusions,
    };

    final response = await apiClient.post(ApiConstants.packages, body: body);
    return response != null;
  }

  /// Fetch registered drivers
  Future<List<AdminDriver>> getDrivers() async {
    final response = await apiClient.get(ApiConstants.transportDrivers);
    if (response is List) {
      return response.map((e) => AdminDriver.fromJson(e as Map<String, dynamic>)).toList();
    } else if (response is Map<String, dynamic> && response['results'] is List) {
      return (response['results'] as List)
          .map((e) => AdminDriver.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Create a new driver / chauffeur
  Future<bool> createDriver({
    required String name,
    required String phone,
    required String whatsapp,
    required String licenseNumber,
    required String vehicleType,
    required String vehiclePlateNumber,
    required String district,
  }) async {
    final body = {
      'name': name,
      'phone': phone,
      'whatsapp': whatsapp,
      'license_number': licenseNumber,
      'vehicle_type': vehicleType,
      'vehicle_plate_number': vehiclePlateNumber,
      'district': district,
      'is_verified': true,
      'is_available': true,
    };

    final response = await apiClient.post(ApiConstants.transportDrivers, body: body);
    return response != null;
  }

  /// Fetch destinations
  Future<List<Map<String, dynamic>>> getDestinations() async {
    final response = await apiClient.get(ApiConstants.destinations);
    if (response is List) {
      return response.cast<Map<String, dynamic>>();
    } else if (response is Map<String, dynamic> && response['results'] is List) {
      return (response['results'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Create a new package location / destination
  Future<bool> createDestination({
    required String name,
    required String district,
    required String tagline,
    required String description,
    required double latitude,
    required double longitude,
    required String bestSeason,
    required String heroImage,
    List<String> tags = const [],
  }) async {
    final body = {
      'name': name,
      'district': district,
      'tagline': tagline,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'best_season': bestSeason,
      'hero_image': heroImage,
      'tags': tags,
    };

    final response = await apiClient.post(ApiConstants.destinations, body: body);
    return response != null;
  }
}

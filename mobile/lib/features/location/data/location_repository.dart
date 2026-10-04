import 'package:keralink_mobile/core/constants/api_constants.dart';
import 'package:keralink_mobile/core/network/api_client.dart';
import '../models/location_models.dart';

abstract class ILocationRepository {
  Future<TravelerLocationItem> sendLocationUpdate(LocationUpdateModel update);
  Future<TravelerLocationItem?> getCurrentLocation();
  Future<List<TravelerLocationItem>> getTripLocationHistory(String bookingReference);
}

class LocationRepository implements ILocationRepository {
  final ApiClient apiClient;

  LocationRepository({required this.apiClient});

  @override
  Future<TravelerLocationItem> sendLocationUpdate(LocationUpdateModel update) async {
    final response = await apiClient.post(
      ApiConstants.locationUpdate,
      body: update.toJson(),
    );
    return TravelerLocationItem.fromJson(response);
  }

  @override
  Future<TravelerLocationItem?> getCurrentLocation() async {
    final response = await apiClient.get(ApiConstants.locationCurrent);
    if (response == null || response['found'] == false) return null;
    return TravelerLocationItem.fromJson(response);
  }

  @override
  Future<List<TravelerLocationItem>> getTripLocationHistory(String bookingReference) async {
    final response = await apiClient.get(ApiConstants.tripLocations(bookingReference));
    if (response is List) {
      return response.map((l) => TravelerLocationItem.fromJson(l as Map<String, dynamic>)).toList();
    }
    return [];
  }
}

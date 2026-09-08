import 'package:keralink_mobile/core/constants/api_constants.dart';
import 'package:keralink_mobile/core/network/api_client.dart';
import '../models/map_models.dart';

abstract class IMapRepository {
  Future<RouteResult> getRoute({
    required double startLat,
    required double startLon,
    required double endLat,
    required double endLon,
  });

  Future<List<NearbyPlace>> getNearby({
    required double lat,
    required double lon,
    double radiusKm = 35.0,
    String? category,
  });

  Future<String> reverseGeocode({required double lat, required double lon});
}

class MapRepository implements IMapRepository {
  final ApiClient apiClient;

  MapRepository({required this.apiClient});

  @override
  Future<RouteResult> getRoute({
    required double startLat,
    required double startLon,
    required double endLat,
    required double endLon,
  }) async {
    final response = await apiClient.get(
      ApiConstants.mapsRoute,
      queryParameters: {
        'start_lat': startLat.toString(),
        'start_lon': startLon.toString(),
        'end_lat': endLat.toString(),
        'end_lon': endLon.toString(),
      },
    );
    return RouteResult.fromJson(response);
  }

  @override
  Future<List<NearbyPlace>> getNearby({
    required double lat,
    required double lon,
    double radiusKm = 35.0,
    String? category,
  }) async {
    final queryParams = {
      'lat': lat.toString(),
      'lon': lon.toString(),
      'radius_km': radiusKm.toString(),
    };
    if (category != null) {
      queryParams['category'] = category;
    }

    final response = await apiClient.get(
      ApiConstants.mapsNearby,
      queryParameters: queryParams,
    );

    if (response is List) {
      return response.map((p) => NearbyPlace.fromJson(p as Map<String, dynamic>)).toList();
    }
    if (response is Map && response['results'] is List) {
      return (response['results'] as List)
          .map((p) => NearbyPlace.fromJson(p as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<String> reverseGeocode({required double lat, required double lon}) async {
    final response = await apiClient.get(
      ApiConstants.mapsGeocode,
      queryParameters: {
        'lat': lat.toString(),
        'lon': lon.toString(),
      },
    );
    return response['landmark'] as String? ?? 'Kerala Western Ghats Corridor';
  }
}

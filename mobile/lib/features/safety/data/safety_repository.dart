import 'package:keralink_mobile/core/constants/api_constants.dart';
import 'package:keralink_mobile/core/network/api_client.dart';
import '../models/safety_models.dart';

abstract class ISafetyRepository {
  Future<List<EmergencyContact>> getEmergencyContacts();
  Future<SafetyAlertResult> triggerSos({
    String? bookingReference,
    double? latitude,
    double? longitude,
    String? locationName,
    String alertType = 'SOS_112',
  });
  Future<TripShareResult> createTripShareToken(String bookingReference, {int expiryHours = 24});
  Future<bool> revokeTripShareToken(String token);
  Future<PublicSharedTrip> getPublicTripShare(String token);
}

class SafetyRepository implements ISafetyRepository {
  final ApiClient apiClient;

  SafetyRepository({required this.apiClient});

  @override
  Future<List<EmergencyContact>> getEmergencyContacts() async {
    final response = await apiClient.get(ApiConstants.safetyDirectory);
    final rawList = response['emergency_numbers'] as List<dynamic>? ?? [];
    return rawList.map((c) => EmergencyContact.fromJson(c as Map<String, dynamic>)).toList();
  }

  @override
  Future<SafetyAlertResult> triggerSos({
    String? bookingReference,
    double? latitude,
    double? longitude,
    String? locationName,
    String alertType = 'SOS_112',
  }) async {
    final response = await apiClient.post(
      ApiConstants.safetySos,
      body: {
        if (bookingReference != null) 'booking_reference': bookingReference,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (locationName != null) 'location_name': locationName,
        'alert_type': alertType,
      },
    );
    return SafetyAlertResult.fromJson(response);
  }

  @override
  Future<TripShareResult> createTripShareToken(String bookingReference, {int expiryHours = 24}) async {
    final response = await apiClient.post(
      ApiConstants.safetyShare,
      body: {
        'booking_reference': bookingReference,
        'expiry_hours': expiryHours,
      },
    );
    return TripShareResult.fromJson(response);
  }

  @override
  Future<bool> revokeTripShareToken(String token) async {
    final response = await apiClient.post(ApiConstants.safetyShareRevoke(token), body: {});
    return response['revoked'] as bool? ?? false;
  }

  @override
  Future<PublicSharedTrip> getPublicTripShare(String token) async {
    final response = await apiClient.get(ApiConstants.safetySharedPublic(token));
    return PublicSharedTrip.fromJson(response);
  }
}

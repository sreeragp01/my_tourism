import 'package:keralink_mobile/core/constants/api_constants.dart';
import 'package:keralink_mobile/core/network/api_client.dart';
import '../models/notification_models.dart';

abstract class INotificationRepository {
  Future<List<NotificationModel>> getNotifications();
  Future<int> markAsRead({String? notificationId});
  Future<NotificationPreferences> getPreferences();
  Future<NotificationPreferences> updatePreferences(NotificationPreferences prefs);
  Future<ProximityCheckResult> checkProximity({
    required double latitude,
    required double longitude,
    String? bookingReference,
    List<Map<String, dynamic>>? waypoints,
  });
}

class NotificationRepository implements INotificationRepository {
  final ApiClient apiClient;

  NotificationRepository({required this.apiClient});

  @override
  Future<List<NotificationModel>> getNotifications() async {
    final response = await apiClient.get(ApiConstants.notifications);
    final rawList = response['notifications'] as List<dynamic>? ?? [];
    return rawList.map((n) => NotificationModel.fromJson(n as Map<String, dynamic>)).toList();
  }

  @override
  Future<int> markAsRead({String? notificationId}) async {
    final response = await apiClient.post(
      ApiConstants.notifications,
      body: {if (notificationId != null) 'notification_id': notificationId},
    );
    return (response['marked_read'] as num?)?.toInt() ?? 0;
  }

  @override
  Future<NotificationPreferences> getPreferences() async {
    final response = await apiClient.get(ApiConstants.notificationPreferences);
    return NotificationPreferences.fromJson(response);
  }

  @override
  Future<NotificationPreferences> updatePreferences(NotificationPreferences prefs) async {
    final response = await apiClient.put(
      ApiConstants.notificationPreferences,
      body: prefs.toJson(),
    );
    return NotificationPreferences.fromJson(response);
  }

  @override
  Future<ProximityCheckResult> checkProximity({
    required double latitude,
    required double longitude,
    String? bookingReference,
    List<Map<String, dynamic>>? waypoints,
  }) async {
    final response = await apiClient.post(
      ApiConstants.proximityCheck,
      body: {
        'latitude': latitude,
        'longitude': longitude,
        if (bookingReference != null) 'booking_reference': bookingReference,
        if (waypoints != null) 'waypoints': waypoints,
      },
    );
    return ProximityCheckResult.fromJson(response);
  }
}

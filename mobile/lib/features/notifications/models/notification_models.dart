class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type; // PROXIMITY, WEATHER_ALERT, SCHEDULE_UPDATE, SAFETY_ALERT, TRIP_MILESTONE
  final Map<String, dynamic> data;
  final bool isRead;
  final String createdAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.data = const {},
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? 'Trip Notification',
      message: json['message'] as String? ?? '',
      type: json['notification_type'] as String? ?? json['type'] as String? ?? 'SCHEDULE_UPDATE',
      data: json['data'] as Map<String, dynamic>? ?? {},
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] as String? ?? 'Just now',
    );
  }
}

class NotificationPreferences {
  final bool proximityEnabled;
  final bool weatherAlertsEnabled;
  final bool scheduleUpdatesEnabled;
  final bool safetyAlertsEnabled;

  const NotificationPreferences({
    this.proximityEnabled = true,
    this.weatherAlertsEnabled = true,
    this.scheduleUpdatesEnabled = true,
    this.safetyAlertsEnabled = true,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      proximityEnabled: json['proximity_enabled'] as bool? ?? true,
      weatherAlertsEnabled: json['weather_alerts_enabled'] as bool? ?? true,
      scheduleUpdatesEnabled: json['schedule_updates_enabled'] as bool? ?? true,
      safetyAlertsEnabled: json['safety_alerts_enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'proximity_enabled': proximityEnabled,
    'weather_alerts_enabled': weatherAlertsEnabled,
    'schedule_updates_enabled': scheduleUpdatesEnabled,
    'safety_alerts_enabled': safetyAlertsEnabled,
  };

  NotificationPreferences copyWith({
    bool? proximityEnabled,
    bool? weatherAlertsEnabled,
    bool? scheduleUpdatesEnabled,
    bool? safetyAlertsEnabled,
  }) {
    return NotificationPreferences(
      proximityEnabled: proximityEnabled ?? this.proximityEnabled,
      weatherAlertsEnabled: weatherAlertsEnabled ?? this.weatherAlertsEnabled,
      scheduleUpdatesEnabled: scheduleUpdatesEnabled ?? this.scheduleUpdatesEnabled,
      safetyAlertsEnabled: safetyAlertsEnabled ?? this.safetyAlertsEnabled,
    );
  }
}

class ProximityCheckResult {
  final int evaluatedCount;
  final String? nearestWaypointName;
  final double? nearestDistanceMeters;
  final List<Map<String, dynamic>> triggeredEvents;

  const ProximityCheckResult({
    required this.evaluatedCount,
    this.nearestWaypointName,
    this.nearestDistanceMeters,
    this.triggeredEvents = const [],
  });

  factory ProximityCheckResult.fromJson(Map<String, dynamic> json) {
    final rawTriggered = json['triggered_events'] as List<dynamic>? ?? [];
    return ProximityCheckResult(
      evaluatedCount: (json['evaluated_count'] as num?)?.toInt() ?? 0,
      nearestWaypointName: json['nearest_waypoint']?['name'] as String?,
      nearestDistanceMeters: (json['nearest_waypoint']?['distance_meters'] as num?)?.toDouble(),
      triggeredEvents: rawTriggered.map((e) => e as Map<String, dynamic>).toList(),
    );
  }
}

class LocationUpdateModel {
  final double latitude;
  final double longitude;
  final double accuracy;
  final double? speed;
  final double? heading;
  final String? bookingReference;

  const LocationUpdateModel({
    required this.latitude,
    required this.longitude,
    this.accuracy = 10.0,
    this.speed,
    this.heading,
    this.bookingReference,
  });

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'accuracy': accuracy,
    if (speed != null) 'speed': speed,
    if (heading != null) 'heading': heading,
    if (bookingReference != null) 'booking_reference': bookingReference,
  };
}

class TravelerLocationItem {
  final String id;
  final double latitude;
  final double longitude;
  final double accuracy;
  final double? speed;
  final double? heading;
  final String landmark;
  final String timestamp;

  const TravelerLocationItem({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    this.speed,
    this.heading,
    required this.landmark,
    required this.timestamp,
  });

  factory TravelerLocationItem.fromJson(Map<String, dynamic> json) {
    return TravelerLocationItem(
      id: json['id']?.toString() ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 10.0,
      speed: (json['speed'] as num?)?.toDouble(),
      heading: (json['heading'] as num?)?.toDouble(),
      landmark: json['landmark'] as String? ?? 'Lockhart Tea Valley, Munnar',
      timestamp: json['timestamp'] as String? ?? 'Just now',
    );
  }
}

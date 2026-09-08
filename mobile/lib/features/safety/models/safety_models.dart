class EmergencyContact {
  final String name;
  final String number;
  final bool tollFree;
  final String type;
  final String description;

  const EmergencyContact({
    required this.name,
    required this.number,
    required this.tollFree,
    required this.type,
    required this.description,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      name: json['name'] as String? ?? 'Emergency Helpline',
      number: json['number'] as String? ?? '112',
      tollFree: json['toll_free'] as bool? ?? true,
      type: json['type'] as String? ?? 'EMERGENCY',
      description: json['description'] as String? ?? 'Immediate 24x7 response',
    );
  }
}

class SafetyAlertResult {
  final String alertId;
  final String alertType;
  final String status;
  final String locationName;
  final List<String> instructions;

  const SafetyAlertResult({
    required this.alertId,
    required this.alertType,
    required this.status,
    required this.locationName,
    required this.instructions,
  });

  factory SafetyAlertResult.fromJson(Map<String, dynamic> json) {
    final rawInst = json['instructions'] as List<dynamic>? ?? [];
    return SafetyAlertResult(
      alertId: json['alert_id']?.toString() ?? '',
      alertType: json['alert_type'] as String? ?? 'SOS_112',
      status: json['status'] as String? ?? 'TRIGGERED',
      locationName: json['location']?['location_name'] as String? ?? 'Current Location',
      instructions: rawInst.map((i) => i.toString()).toList(),
    );
  }
}

class TripShareResult {
  final String token;
  final String bookingReference;
  final String expiresAt;
  final String shareUrl;
  final bool isValid;

  const TripShareResult({
    required this.token,
    required this.bookingReference,
    required this.expiresAt,
    required this.shareUrl,
    required this.isValid,
  });

  factory TripShareResult.fromJson(Map<String, dynamic> json) {
    return TripShareResult(
      token: json['token'] as String? ?? '',
      bookingReference: json['booking_reference'] as String? ?? '',
      expiresAt: json['expires_at'] as String? ?? '',
      shareUrl: json['share_url'] as String? ?? '',
      isValid: json['is_valid'] as bool? ?? true,
    );
  }
}

class PublicSharedTrip {
  final bool valid;
  final String? tripTitle;
  final String? maskedReference;
  final String? startDate;
  final String? endDate;
  final String? status;
  final String? latestLandmark;
  final List<Map<String, dynamic>> itinerary;

  const PublicSharedTrip({
    required this.valid,
    this.tripTitle,
    this.maskedReference,
    this.startDate,
    this.endDate,
    this.status,
    this.latestLandmark,
    this.itinerary = const [],
  });

  factory PublicSharedTrip.fromJson(Map<String, dynamic> json) {
    final valid = json['valid'] as bool? ?? false;
    if (!valid) return const PublicSharedTrip(valid: false);

    final rawItin = json['itinerary'] as List<dynamic>? ?? [];
    return PublicSharedTrip(
      valid: true,
      tripTitle: json['trip_title'] as String?,
      maskedReference: json['masked_reference'] as String?,
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
      status: json['status'] as String?,
      latestLandmark: json['latest_location']?['landmark'] as String?,
      itinerary: rawItin.map((item) => item as Map<String, dynamic>).toList(),
    );
  }
}

class TripProfile {
  final double budgetLimit;
  final int durationDays;
  final String travelStyle;
  final List<String> interests;
  final int adults;
  final int children;
  final String pace;
  final List<String> extractedKeywords;

  const TripProfile({
    required this.budgetLimit,
    required this.durationDays,
    required this.travelStyle,
    this.interests = const [],
    this.adults = 2,
    this.children = 0,
    this.pace = 'MODERATE',
    this.extractedKeywords = const [],
  });

  factory TripProfile.fromJson(Map<String, dynamic> json) {
    return TripProfile(
      budgetLimit: (json['budget_limit'] as num?)?.toDouble() ?? 50000.0,
      durationDays: (json['duration_days'] as num?)?.toInt() ?? 5,
      travelStyle: (json['travel_style'] as String?)?.toUpperCase() ?? 'PREMIUM',
      interests: (json['interests'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      adults: (json['adults'] as num?)?.toInt() ?? 2,
      children: (json['children'] as num?)?.toInt() ?? 0,
      pace: (json['pace'] as String?) ?? 'MODERATE',
      extractedKeywords: (json['extracted_keywords'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'budget_limit': budgetLimit,
    'duration_days': durationDays,
    'travel_style': travelStyle,
    'interests': interests,
    'adults': adults,
    'children': children,
    'pace': pace,
  };
}

class PricingBreakdown {
  final int daysCount;
  final int travelersCount;
  final double staysSubtotal;
  final double experiencesSubtotal;
  final double transportSubtotal;
  final double subtotal;
  final double gstRatePercent;
  final double gstAmount;
  final double platformFeePercent;
  final double platformFee;
  final double taxesAndFees;
  final double discount;
  final double total;
  final String currency;

  const PricingBreakdown({
    required this.daysCount,
    required this.travelersCount,
    required this.staysSubtotal,
    required this.experiencesSubtotal,
    required this.transportSubtotal,
    required this.subtotal,
    required this.gstRatePercent,
    required this.gstAmount,
    required this.platformFeePercent,
    required this.platformFee,
    required this.taxesAndFees,
    required this.discount,
    required this.total,
    this.currency = 'INR',
  });

  factory PricingBreakdown.fromJson(Map<String, dynamic> json) {
    return PricingBreakdown(
      daysCount: (json['days_count'] as num?)?.toInt() ?? 1,
      travelersCount: (json['travelers_count'] as num?)?.toInt() ?? 1,
      staysSubtotal: (json['stays_subtotal'] as num?)?.toDouble() ?? 0.0,
      experiencesSubtotal: (json['experiences_subtotal'] as num?)?.toDouble() ?? 0.0,
      transportSubtotal: (json['transport_subtotal'] as num?)?.toDouble() ?? 0.0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      gstRatePercent: (json['gst_rate_percent'] as num?)?.toDouble() ?? 5.0,
      gstAmount: (json['gst_amount'] as num?)?.toDouble() ?? 0.0,
      platformFeePercent: (json['platform_fee_percent'] as num?)?.toDouble() ?? 2.0,
      platformFee: (json['platform_fee'] as num?)?.toDouble() ?? 0.0,
      taxesAndFees: (json['taxes_and_fees'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      currency: (json['currency'] as String?) ?? 'INR',
    );
  }

  Map<String, dynamic> toJson() => {
    'days_count': daysCount,
    'travelers_count': travelersCount,
    'stays_subtotal': staysSubtotal,
    'experiences_subtotal': experiencesSubtotal,
    'transport_subtotal': transportSubtotal,
    'subtotal': subtotal,
    'gst_rate_percent': gstRatePercent,
    'gst_amount': gstAmount,
    'platform_fee_percent': platformFeePercent,
    'platform_fee': platformFee,
    'taxes_and_fees': taxesAndFees,
    'discount': discount,
    'total': total,
    'currency': currency,
  };
}

class ValidationReport {
  final bool valid;
  final List<String> errors;
  final List<String> warnings;
  final int score;
  final double budgetLimit;
  final double calculatedTotal;

  const ValidationReport({
    required this.valid,
    required this.errors,
    required this.warnings,
    required this.score,
    required this.budgetLimit,
    required this.calculatedTotal,
  });

  factory ValidationReport.fromJson(Map<String, dynamic> json) {
    return ValidationReport(
      valid: json['valid'] as bool? ?? true,
      errors: (json['errors'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      warnings: (json['warnings'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      score: (json['score'] as num?)?.toInt() ?? 100,
      budgetLimit: (json['budget_limit'] as num?)?.toDouble() ?? 0.0,
      calculatedTotal: (json['calculated_total'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class TimelineEvent {
  final String id;
  final String type; // 'EXPERIENCE', 'MEAL', 'STAY', 'TRANSFER'
  final String title;
  final dynamic destinationId;
  final String destinationName;
  final double? lat;
  final double? lng;
  final String time;
  final String startTime;
  final String endTime;
  final int durationMins;
  final int travelDurationMins;
  final int? experienceId;
  final int? accommodationId;
  final bool availabilityRequired;
  final double price;
  final bool rainFriendly;
  final bool bookingRequired;
  final Map<String, dynamic> metadata;

  const TimelineEvent({
    required this.id,
    required this.type,
    required this.title,
    this.destinationId,
    this.destinationName = '',
    this.lat,
    this.lng,
    required this.time,
    required this.startTime,
    required this.endTime,
    this.durationMins = 60,
    this.travelDurationMins = 0,
    this.experienceId,
    this.accommodationId,
    this.availabilityRequired = false,
    this.price = 0.0,
    this.rainFriendly = true,
    this.bookingRequired = false,
    this.metadata = const {},
  });

  factory TimelineEvent.fromJson(Map<String, dynamic> json) {
    double? lat;
    double? lng;
    if (json['coordinates'] is Map<String, dynamic>) {
      lat = (json['coordinates']['lat'] as num?)?.toDouble();
      lng = (json['coordinates']['lng'] as num?)?.toDouble();
    }

    return TimelineEvent(
      id: json['id']?.toString() ?? '',
      type: (json['type'] as String?)?.toUpperCase() ?? 'EXPERIENCE',
      title: json['title'] as String? ?? 'Scheduled Event',
      destinationId: json['destination_id'],
      destinationName: json['destination_name'] as String? ?? '',
      lat: lat,
      lng: lng,
      time: json['time'] as String? ?? '09:00',
      startTime: json['start_time'] as String? ?? json['time'] as String? ?? '09:00',
      endTime: json['end_time'] as String? ?? '10:00',
      durationMins: (json['duration_mins'] as num?)?.toInt() ?? 60,
      travelDurationMins: (json['travel_duration_mins'] as num?)?.toInt() ?? 0,
      experienceId: (json['experience_id'] as num?)?.toInt(),
      accommodationId: (json['accommodation_id'] as num?)?.toInt(),
      availabilityRequired: json['availability_required'] as bool? ?? false,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      rainFriendly: json['rain_friendly'] as bool? ?? true,
      bookingRequired: json['booking_required'] as bool? ?? false,
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'title': title,
    'destination_id': destinationId,
    'destination_name': destinationName,
    'coordinates': {'lat': lat, 'lng': lng},
    'time': time,
    'start_time': startTime,
    'end_time': endTime,
    'duration_mins': durationMins,
    'travel_duration_mins': travelDurationMins,
    'experience_id': experienceId,
    'accommodation_id': accommodationId,
    'availability_required': availabilityRequired,
    'price': price,
    'rain_friendly': rainFriendly,
    'booking_required': bookingRequired,
    'metadata': metadata,
  };
}

class PlanDay {
  final int dayNumber;
  final dynamic destinationId;
  final String destinationName;
  final String themeTitle;
  final List<TimelineEvent> timeline;

  const PlanDay({
    required this.dayNumber,
    this.destinationId,
    required this.destinationName,
    required this.themeTitle,
    required this.timeline,
  });

  factory PlanDay.fromJson(Map<String, dynamic> json) {
    final rawTimeline = json['timeline'] as List<dynamic>? ?? [];
    return PlanDay(
      dayNumber: (json['day_number'] as num?)?.toInt() ?? 1,
      destinationId: json['destination_id'],
      destinationName: json['destination_name'] as String? ?? 'Kerala Region',
      themeTitle: json['theme_title'] as String? ?? 'Highland & Lagoon Corridor',
      timeline: rawTimeline
          .map((e) => TimelineEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'day_number': dayNumber,
    'destination_id': destinationId,
    'destination_name': destinationName,
    'theme_title': themeTitle,
    'timeline': timeline.map((e) => e.toJson()).toList(),
  };
}

class AIPlan {
  final String planId;
  final int version;
  final String title;
  final List<String> corridorRoute;
  final int durationDays;
  final String travelStyle;
  final String? changeReason;
  final PricingBreakdown pricing;
  final ValidationReport validation;
  final List<PlanDay> days;
  final String createdAt;

  const AIPlan({
    required this.planId,
    required this.version,
    required this.title,
    required this.corridorRoute,
    required this.durationDays,
    required this.travelStyle,
    this.changeReason,
    required this.pricing,
    required this.validation,
    required this.days,
    required this.createdAt,
  });

  factory AIPlan.fromJson(Map<String, dynamic> json) {
    final rawDays = json['days'] as List<dynamic>? ?? [];
    final rawRoute = json['corridor_route'] as List<dynamic>? ?? [];

    return AIPlan(
      planId: json['plan_id']?.toString() ?? '',
      version: (json['version'] as num?)?.toInt() ?? 1,
      title: json['title'] as String? ?? 'Kerala Experiential Itinerary',
      corridorRoute: rawRoute.map((e) => e.toString()).toList(),
      durationDays: (json['duration_days'] as num?)?.toInt() ?? 1,
      travelStyle: (json['travel_style'] as String?)?.toUpperCase() ?? 'PREMIUM',
      changeReason: json['change_reason'] as String?,
      pricing: PricingBreakdown.fromJson(
        (json['pricing'] as Map<String, dynamic>?) ?? {},
      ),
      validation: ValidationReport.fromJson(
        (json['validation'] as Map<String, dynamic>?) ?? {},
      ),
      days: rawDays
          .map((e) => PlanDay.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'plan_id': planId,
    'version': version,
    'title': title,
    'corridor_route': corridorRoute,
    'duration_days': durationDays,
    'travel_style': travelStyle,
    if (changeReason != null) 'change_reason': changeReason,
    'pricing': pricing.toJson(),
    'days': days.map((e) => e.toJson()).toList(),
    'created_at': createdAt,
  };
}

class PlanVersionSummary {
  final int version;
  final String changeReason;
  final String createdAt;
  final double totalPrice;

  const PlanVersionSummary({
    required this.version,
    required this.changeReason,
    required this.createdAt,
    required this.totalPrice,
  });

  factory PlanVersionSummary.fromJson(Map<String, dynamic> json) {
    return PlanVersionSummary(
      version: (json['version'] as num?)?.toInt() ?? 1,
      changeReason: json['change_reason'] as String? ?? 'Initial synthesis',
      createdAt: json['created_at'] as String? ?? '',
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

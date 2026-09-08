class TripProfile {
  final double budgetLimit;
  final int durationDays;
  final String travelStyle;
  final String month;
  final bool monsoonMode;
  final List<String> interests;
  final int adults;
  final int children;
  final String pace;
  final List<String> extractedKeywords;

  const TripProfile({
    required this.budgetLimit,
    required this.durationDays,
    required this.travelStyle,
    this.month = 'October',
    this.monsoonMode = false,
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
      month: (json['month'] as String?) ?? 'October',
      monsoonMode: json['monsoon_mode'] == true,
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
    'month': month,
    'monsoon_mode': monsoonMode,
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
    final subtotal = (json['subtotal'] as num?)?.toDouble() ?? 0.0;
    final stays = ((json['stays_subtotal'] ?? json['stays_total']) as num?)?.toDouble() ?? 0.0;
    final exps = ((json['experiences_subtotal'] ?? json['experiences_total']) as num?)?.toDouble() ?? 0.0;
    final trans = ((json['transport_subtotal'] ?? json['transport_total']) as num?)?.toDouble() ?? 0.0;
    final gst = ((json['gst_amount'] ?? json['taxes']) as num?)?.toDouble() ?? 0.0;
    final fee = ((json['platform_fee'] ?? json['platform_fees']) as num?)?.toDouble() ?? 0.0;
    final taxesAndFees = ((json['taxes_and_fees']) as num?)?.toDouble() ?? (gst + fee);
    final total = (json['total'] as num?)?.toDouble() ?? (subtotal + taxesAndFees);

    return PricingBreakdown(
      daysCount: (json['days_count'] as num?)?.toInt() ?? 1,
      travelersCount: (json['travelers_count'] as num?)?.toInt() ?? 1,
      staysSubtotal: stays,
      experiencesSubtotal: exps,
      transportSubtotal: trans,
      subtotal: subtotal,
      gstRatePercent: (json['gst_rate_percent'] as num?)?.toDouble() ?? 5.0,
      gstAmount: gst,
      platformFeePercent: (json['platform_fee_percent'] as num?)?.toDouble() ?? 2.0,
      platformFee: fee,
      taxesAndFees: taxesAndFees,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      total: total,
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
    final isValid = json['valid'] as bool? ?? json['is_valid'] as bool? ?? true;
    final violations = (json['violations'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final errors = (json['errors'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? (!isValid ? violations : []);
    final warnings = (json['warnings'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? (isValid ? violations : []);
    final score = ((json['score'] ?? json['validation_score']) as num?)?.toInt() ?? 100;

    return ValidationReport(
      valid: isValid,
      errors: errors,
      warnings: warnings,
      score: score,
      budgetLimit: (json['budget_limit'] as num?)?.toDouble() ?? 0.0,
      calculatedTotal: (json['calculated_total'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class TimelineEvent {
  final String id;
  final int order;
  final String type; // 'EXPERIENCE', 'MEAL', 'STAY', 'TRANSFER', 'ATTRACTION'
  final String? entityType; // 'EXPERIENCE', 'ATTRACTION', 'ACCOMMODATION'
  final dynamic entityId;
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
    this.order = 1,
    required this.type,
    this.entityType,
    this.entityId,
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

    final rawPrice = json['price'] ?? json['cost'];
    final priceVal = (rawPrice is num)
        ? rawPrice.toDouble()
        : double.tryParse(rawPrice?.toString() ?? '') ?? 0.0;

    final expId = json['experience_id'];
    final expIdInt = (expId is num)
        ? expId.toInt()
        : int.tryParse(expId?.toString() ?? '');

    final accId = json['accommodation_id'];
    final accIdInt = (accId is num)
        ? accId.toInt()
        : int.tryParse(accId?.toString() ?? '');

    final rawDuration = json['duration_mins'];
    final durationVal = (rawDuration is num)
        ? rawDuration.toInt()
        : int.tryParse(rawDuration?.toString() ?? '') ?? 60;

    final rawOrder = json['order'];
    final orderVal = (rawOrder is num)
        ? rawOrder.toInt()
        : int.tryParse(rawOrder?.toString() ?? '') ?? 1;

    return TimelineEvent(
      id: json['id']?.toString() ?? '',
      order: orderVal,
      type: (json['type'] as String?)?.toUpperCase() ?? 'EXPERIENCE',
      entityType: json['entity_type'] as String?,
      entityId: json['entity_id'] ?? json['experience_id'] ?? json['accommodation_id'],
      title: json['title'] as String? ?? 'Scheduled Event',
      destinationId: json['destination_id'],
      destinationName: json['destination_name'] as String? ?? json['location_name'] as String? ?? '',
      lat: lat,
      lng: lng,
      time: json['time'] as String? ?? '09:00',
      startTime: json['start_time'] as String? ?? json['time'] as String? ?? '09:00',
      endTime: json['end_time'] as String? ?? '10:00',
      durationMins: durationVal,
      travelDurationMins: (json['travel_duration_mins'] as num?)?.toInt() ?? 0,
      experienceId: expIdInt,
      accommodationId: accIdInt,
      availabilityRequired: json['availability_required'] as bool? ?? false,
      price: priceVal,
      rainFriendly: json['rain_friendly'] as bool? ?? true,
      bookingRequired: json['booking_required'] as bool? ?? false,
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'order': order,
    'type': type,
    if (entityType != null) 'entity_type': entityType,
    if (entityId != null) 'entity_id': entityId,
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

  TimelineEvent copyWith({
    String? id,
    int? order,
    String? type,
    String? entityType,
    dynamic entityId,
    String? title,
    dynamic destinationId,
    String? destinationName,
    double? lat,
    double? lng,
    String? time,
    String? startTime,
    String? endTime,
    int? durationMins,
    int? travelDurationMins,
    int? experienceId,
    int? accommodationId,
    bool? availabilityRequired,
    double? price,
    bool? rainFriendly,
    bool? bookingRequired,
    Map<String, dynamic>? metadata,
  }) {
    return TimelineEvent(
      id: id ?? this.id,
      order: order ?? this.order,
      type: type ?? this.type,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      title: title ?? this.title,
      destinationId: destinationId ?? this.destinationId,
      destinationName: destinationName ?? this.destinationName,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      time: time ?? this.time,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMins: durationMins ?? this.durationMins,
      travelDurationMins: travelDurationMins ?? this.travelDurationMins,
      experienceId: experienceId ?? this.experienceId,
      accommodationId: accommodationId ?? this.accommodationId,
      availabilityRequired: availabilityRequired ?? this.availabilityRequired,
      price: price ?? this.price,
      rainFriendly: rainFriendly ?? this.rainFriendly,
      bookingRequired: bookingRequired ?? this.bookingRequired,
      metadata: metadata ?? this.metadata,
    );
  }
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

  PlanDay copyWith({
    int? dayNumber,
    dynamic destinationId,
    String? destinationName,
    String? themeTitle,
    List<TimelineEvent>? timeline,
  }) {
    return PlanDay(
      dayNumber: dayNumber ?? this.dayNumber,
      destinationId: destinationId ?? this.destinationId,
      destinationName: destinationName ?? this.destinationName,
      themeTitle: themeTitle ?? this.themeTitle,
      timeline: timeline ?? this.timeline,
    );
  }
}

class AIPlan {
  final String planId;
  final int version;
  final String validationStatus; // 'VALID', 'WARNINGS', 'INVALID'
  final String title;
  final List<String> corridorRoute;
  final int durationDays;
  final String travelStyle;
  final String month;
  final bool monsoonMode;
  final int greenTripScore;
  final double totalDistanceKm;
  final String? changeReason;
  final PricingBreakdown pricing;
  final ValidationReport validation;
  final List<PlanDay> days;
  final String createdAt;

  const AIPlan({
    required this.planId,
    required this.version,
    this.validationStatus = 'VALID',
    required this.title,
    required this.corridorRoute,
    required this.durationDays,
    required this.travelStyle,
    this.month = 'October',
    this.monsoonMode = false,
    this.greenTripScore = 88,
    this.totalDistanceKm = 0.0,
    this.changeReason,
    required this.pricing,
    required this.validation,
    required this.days,
    required this.createdAt,
  });

  factory AIPlan.fromJson(Map<String, dynamic> json) {
    final rawDays = json['days'] as List<dynamic>? ?? [];
    final rawRoute = json['corridor_route'] as List<dynamic>? ?? [];
    final profile = json['profile'] as Map<String, dynamic>? ?? {};

    String status = json['validation_status'] as String? ?? '';
    if (status.isEmpty) {
      final validReport = json['validation'];
      if (validReport is Map<String, dynamic>) {
        if (validReport['valid'] == false || validReport['is_valid'] == false) {
          status = 'INVALID';
        } else if ((validReport['warnings'] as List?)?.isNotEmpty == true || (validReport['violations'] as List?)?.isNotEmpty == true) {
          status = 'WARNINGS';
        } else {
          status = 'VALID';
        }
      } else {
        status = 'VALID';
      }
    }

    final rawVersion = json['version_number'] ?? json['current_version'] ?? json['version'];
    final versionVal = (rawVersion is num)
        ? rawVersion.toInt()
        : int.tryParse(rawVersion?.toString() ?? '') ?? 1;

    final rawDuration = json['duration_days'] ?? profile['duration_days'];
    final durationVal = (rawDuration is num)
        ? rawDuration.toInt()
        : (int.tryParse(rawDuration?.toString() ?? '') ?? (rawDays.isNotEmpty ? rawDays.length : 1));

    return AIPlan(
      planId: json['plan_id']?.toString() ?? '',
      version: versionVal,
      validationStatus: status,
      title: json['title'] as String? ?? 'Kerala Experiential Itinerary',
      corridorRoute: rawRoute.map((e) => e.toString()).toList(),
      durationDays: durationVal,
      travelStyle: (json['travel_style'] ?? profile['travel_style'] as String?)?.toUpperCase() ?? 'PREMIUM',
      month: (json['month'] ?? profile['month'] as String?) ?? 'October',
      monsoonMode: json['monsoon_mode'] == true || profile['monsoon_mode'] == true,
      greenTripScore: (json['green_trip_score'] as num?)?.toInt() ?? 88,
      totalDistanceKm: (json['total_distance_km'] as num?)?.toDouble() ?? 0.0,
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
    'validation_status': validationStatus,
    'title': title,
    'corridor_route': corridorRoute,
    'duration_days': durationDays,
    'travel_style': travelStyle,
    if (changeReason != null) 'change_reason': changeReason,
    'pricing': pricing.toJson(),
    'days': days.map((e) => e.toJson()).toList(),
    'created_at': createdAt,
  };

  AIPlan copyWith({
    String? planId,
    int? version,
    String? validationStatus,
    String? title,
    List<String>? corridorRoute,
    int? durationDays,
    String? travelStyle,
    String? month,
    bool? monsoonMode,
    int? greenTripScore,
    double? totalDistanceKm,
    String? changeReason,
    PricingBreakdown? pricing,
    ValidationReport? validation,
    List<PlanDay>? days,
    String? createdAt,
  }) {
    return AIPlan(
      planId: planId ?? this.planId,
      version: version ?? this.version,
      validationStatus: validationStatus ?? this.validationStatus,
      title: title ?? this.title,
      corridorRoute: corridorRoute ?? this.corridorRoute,
      durationDays: durationDays ?? this.durationDays,
      travelStyle: travelStyle ?? this.travelStyle,
      month: month ?? this.month,
      monsoonMode: monsoonMode ?? this.monsoonMode,
      greenTripScore: greenTripScore ?? this.greenTripScore,
      totalDistanceKm: totalDistanceKm ?? this.totalDistanceKm,
      changeReason: changeReason ?? this.changeReason,
      pricing: pricing ?? this.pricing,
      validation: validation ?? this.validation,
      days: days ?? this.days,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class PlanVersionSummary {
  final int version;
  final String changeReason;
  final String createdAt;
  final double totalPrice;
  final String validationStatus;

  const PlanVersionSummary({
    required this.version,
    required this.changeReason,
    required this.createdAt,
    required this.totalPrice,
    this.validationStatus = 'VALID',
  });

  factory PlanVersionSummary.fromJson(Map<String, dynamic> json) {
    return PlanVersionSummary(
      version: (json['version'] as num?)?.toInt() ?? 1,
      changeReason: json['change_reason'] as String? ?? 'Initial synthesis',
      createdAt: json['created_at'] as String? ?? '',
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
      validationStatus: json['validation_status'] as String? ?? 'VALID',
    );
  }
}

class DiffItem {
  final String eventId;
  final String title;
  final int day;
  final int? fromDay;
  final int? toDay;
  final int? fromOrder;
  final int? toOrder;

  const DiffItem({
    required this.eventId,
    required this.title,
    this.day = 1,
    this.fromDay,
    this.toDay,
    this.fromOrder,
    this.toOrder,
  });

  factory DiffItem.fromJson(Map<String, dynamic> json) {
    return DiffItem(
      eventId: json['event_id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      day: (json['day'] as num?)?.toInt() ?? (json['to_day'] as num?)?.toInt() ?? 1,
      fromDay: (json['from_day'] as num?)?.toInt(),
      toDay: (json['to_day'] as num?)?.toInt(),
      fromOrder: (json['from_order'] as num?)?.toInt(),
      toOrder: (json['to_order'] as num?)?.toInt(),
    );
  }
}

class ItineraryDiff {
  final int fromVersion;
  final int toVersion;
  final List<DiffItem> added;
  final List<DiffItem> removed;
  final List<DiffItem> moved;
  final double priceDifference;
  final double distanceDifference;
  final bool monsoonCompliant;
  final String summaryText;

  const ItineraryDiff({
    required this.fromVersion,
    required this.toVersion,
    this.added = const [],
    this.removed = const [],
    this.moved = const [],
    this.priceDifference = 0.0,
    this.distanceDifference = 0.0,
    this.monsoonCompliant = true,
    this.summaryText = '',
  });

  factory ItineraryDiff.fromJson(Map<String, dynamic> json) {
    final diff = (json['diff'] as Map<String, dynamic>?) ?? json;
    final addedList = (diff['added'] as List<dynamic>?)
            ?.map((e) => DiffItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final removedList = (diff['removed'] as List<dynamic>?)
            ?.map((e) => DiffItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final movedList = (diff['moved'] as List<dynamic>?)
            ?.map((e) => DiffItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    double priceDiff = 0.0;
    if (diff['price'] is Map<String, dynamic>) {
      priceDiff = (diff['price']['delta'] as num?)?.toDouble() ?? 0.0;
    } else if (diff['price_difference'] != null) {
      priceDiff = (diff['price_difference'] as num?)?.toDouble() ?? 0.0;
    }

    double distDiff = 0.0;
    if (diff['distance'] is Map<String, dynamic>) {
      distDiff = (diff['distance']['delta_km'] as num?)?.toDouble() ?? 0.0;
    } else if (diff['distance_difference'] != null) {
      distDiff = (diff['distance_difference'] as num?)?.toDouble() ?? 0.0;
    }

    bool monsoon = true;
    if (diff['safety'] is Map<String, dynamic>) {
      monsoon = diff['safety']['monsoon_compliant'] != false;
    } else if (diff['monsoon_compliant'] != null) {
      monsoon = diff['monsoon_compliant'] == true;
    }

    return ItineraryDiff(
      fromVersion: (json['from_version'] as num?)?.toInt() ?? 1,
      toVersion: (json['to_version'] as num?)?.toInt() ?? 2,
      added: addedList,
      removed: removedList,
      moved: movedList,
      priceDifference: priceDiff,
      distanceDifference: distDiff,
      monsoonCompliant: monsoon,
      summaryText: diff['summary_text'] as String? ?? 'Changes calculated',
    );
  }
}

class PlanCandidate {
  final dynamic id;
  final String title;
  final String entityType; // 'EXPERIENCE', 'ATTRACTION', 'ACCOMMODATION'
  final double price;
  final bool rainFriendly;
  final String destinationName;
  final double rating;
  final int durationMins;

  const PlanCandidate({
    required this.id,
    required this.title,
    required this.entityType,
    required this.price,
    this.rainFriendly = true,
    this.destinationName = '',
    this.rating = 4.5,
    this.durationMins = 60,
  });

  factory PlanCandidate.fromJson(Map<String, dynamic> json) {
    return PlanCandidate(
      id: json['id'],
      title: json['title'] as String? ?? json['name'] as String? ?? '',
      entityType: (json['entity_type'] as String?)?.toUpperCase() ?? 'EXPERIENCE',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      rainFriendly: json['rain_friendly'] == true,
      destinationName: json['destination_name'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
      durationMins: (json['duration_mins'] as num?)?.toInt() ?? 60,
    );
  }
}


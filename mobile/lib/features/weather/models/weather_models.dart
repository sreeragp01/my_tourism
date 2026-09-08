class MonsoonRisk {
  final String riskLevel; // SAFE, CAUTION, UNSAFE
  final int riskScore;
  final String advisory;
  final String badgeColor;
  final bool isGhatCorridor;
  final int rainProbabilityPercent;
  final bool monsoonModeRecommended;

  const MonsoonRisk({
    required this.riskLevel,
    required this.riskScore,
    required this.advisory,
    required this.badgeColor,
    required this.isGhatCorridor,
    required this.rainProbabilityPercent,
    this.monsoonModeRecommended = false,
  });

  factory MonsoonRisk.fromJson(Map<String, dynamic> json) {
    return MonsoonRisk(
      riskLevel: json['risk_level'] as String? ?? 'SAFE',
      riskScore: (json['risk_score'] as num?)?.toInt() ?? 15,
      advisory: json['advisory'] as String? ?? 'Clear conditions across the travel corridor.',
      badgeColor: json['badge_color'] as String? ?? '#10B981',
      isGhatCorridor: json['is_ghat_corridor'] as bool? ?? false,
      rainProbabilityPercent: (json['rain_probability_percent'] as num?)?.toInt() ?? 20,
      monsoonModeRecommended: json['monsoon_mode_recommended'] as bool? ?? false,
    );
  }
}

class WeatherReport {
  final String destination;
  final int temperatureCelsius;
  final String condition;
  final int rainProbabilityPercent;
  final String recommendation;
  final MonsoonRisk risk;

  const WeatherReport({
    required this.destination,
    required this.temperatureCelsius,
    required this.condition,
    required this.rainProbabilityPercent,
    required this.recommendation,
    required this.risk,
  });

  factory WeatherReport.fromJson(Map<String, dynamic> json) {
    final rawRisk = json['risk'] as Map<String, dynamic>? ?? {};
    return WeatherReport(
      destination: json['destination'] as String? ?? 'Munnar Hills',
      temperatureCelsius: (json['temperature_celsius'] as num?)?.toInt() ?? 19,
      condition: json['condition'] as String? ?? 'MIST_RAIN',
      rainProbabilityPercent: (json['rain_probability_percent'] as num?)?.toInt() ?? 60,
      recommendation: json['recommendation'] as String? ?? 'Ghat road caution in effect.',
      risk: MonsoonRisk.fromJson(rawRisk),
    );
  }
}

class RainSubstitute {
  final String alternativeTitle;
  final String category;
  final bool rainFriendly;
  final double pricePerPerson;
  final String reason;

  const RainSubstitute({
    required this.alternativeTitle,
    required this.category,
    required this.rainFriendly,
    required this.pricePerPerson,
    required this.reason,
  });

  factory RainSubstitute.fromJson(Map<String, dynamic> json) {
    return RainSubstitute(
      alternativeTitle: json['alternative_title'] as String? ?? json['title'] as String? ?? 'Indoor Cultural Activity',
      category: json['category'] as String? ?? 'CULTURE',
      rainFriendly: json['rain_friendly'] as bool? ?? true,
      pricePerPerson: (json['price_per_person'] as num?)?.toDouble() ?? 1200.0,
      reason: json['reason'] as String? ?? '100% sheltered indoor experience.',
    );
  }
}

class ActivityWeatherValidation {
  final String activityType;
  final String destination;
  final bool isOutdoor;
  final int rainProbability;
  final String status;
  final bool requiresSubstitution;
  final RainSubstitute? substitute;

  const ActivityWeatherValidation({
    required this.activityType,
    required this.destination,
    required this.isOutdoor,
    required this.rainProbability,
    required this.status,
    required this.requiresSubstitution,
    this.substitute,
  });

  factory ActivityWeatherValidation.fromJson(Map<String, dynamic> json) {
    final rawSub = json['substitute'] as Map<String, dynamic>?;
    return ActivityWeatherValidation(
      activityType: json['activity_type'] as String? ?? 'ACTIVITY',
      destination: json['destination'] as String? ?? 'munnar',
      isOutdoor: json['is_outdoor'] as bool? ?? false,
      rainProbability: (json['rain_probability'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'SAFE',
      requiresSubstitution: json['requires_substitution'] as bool? ?? false,
      substitute: rawSub != null ? RainSubstitute.fromJson(rawSub) : null,
    );
  }
}

import 'package:keralink_mobile/core/constants/api_constants.dart';
import 'package:keralink_mobile/core/network/api_client.dart';
import '../models/itinerary_models.dart';

abstract class IAIPlannerRepository {
  Future<TripProfile> parsePrompt(String prompt);
  Future<AIPlan> generateItinerary({
    required double budget,
    required int duration,
    required String travelStyle,
    List<String> interests = const [],
    int adults = 2,
    int children = 0,
    String pace = 'MODERATE',
  });
  Future<AIPlan> getPlan(String planId);
  Future<AIPlan> substituteRain({
    required String planId,
    required int dayNumber,
    String? outdoorItemId,
  });
  Future<AIPlan> customizePlan({
    required String planId,
    required String action,
    required int dayNumber,
    String? timelineEventId,
    Map<String, dynamic>? newEvent,
    String? reason,
  });
  Future<List<PlanVersionSummary>> getPlanVersions(String planId);
  Future<AIPlan> getPlanVersionDetail(String planId, int version);
}

class AIPlannerRepository implements IAIPlannerRepository {
  final ApiClient apiClient;

  AIPlannerRepository({required this.apiClient});

  @override
  Future<TripProfile> parsePrompt(String prompt) async {
    try {
      final response = await apiClient.post(
        ApiConstants.parsePrompt,
        body: {'prompt': prompt},
        requiresAuth: false,
      );

      final Map<String, dynamic> data = response is Map<String, dynamic>
          ? (response['data'] is Map<String, dynamic> ? response['data'] : response)
          : {};

      return TripProfile.fromJson(data);
    } catch (_) {
      // Deterministic offline fallback parser
      return _fallbackParsePrompt(prompt);
    }
  }

  @override
  Future<AIPlan> generateItinerary({
    required double budget,
    required int duration,
    required String travelStyle,
    List<String> interests = const [],
    int adults = 2,
    int children = 0,
    String pace = 'MODERATE',
  }) async {
    try {
      final response = await apiClient.post(
        ApiConstants.generateItinerary,
        body: {
          'budget_limit': budget,
          'duration_days': duration,
          'travel_style': travelStyle,
          'interests': interests,
          'adults': adults,
          'children': children,
          'pace': pace,
        },
        requiresAuth: false,
      );

      final Map<String, dynamic> data = response is Map<String, dynamic>
          ? (response['data'] is Map<String, dynamic> ? response['data'] : response)
          : {};

      return AIPlan.fromJson(data);
    } catch (_) {
      // Deterministic offline fallback plan
      return _generateOfflineFallbackPlan(
        budget: budget,
        duration: duration,
        travelStyle: travelStyle,
        adults: adults,
      );
    }
  }

  @override
  Future<AIPlan> getPlan(String planId) async {
    final response = await apiClient.get(
      ApiConstants.aiPlan(planId),
      requiresAuth: false,
    );
    final Map<String, dynamic> data = response is Map<String, dynamic>
        ? (response['data'] is Map<String, dynamic> ? response['data'] : response)
        : {};
    return AIPlan.fromJson(data);
  }

  @override
  Future<AIPlan> substituteRain({
    required String planId,
    required int dayNumber,
    String? outdoorItemId,
  }) async {
    final response = await apiClient.post(
      ApiConstants.aiPlanSubstituteRain(planId),
      body: {
        'day_number': dayNumber,
        if (outdoorItemId != null) 'outdoor_item_id': outdoorItemId,
      },
      requiresAuth: false,
    );

    final Map<String, dynamic> data = response is Map<String, dynamic>
        ? (response['data'] is Map<String, dynamic> ? response['data'] : response)
        : {};
    return AIPlan.fromJson(data);
  }

  @override
  Future<AIPlan> customizePlan({
    required String planId,
    required String action,
    required int dayNumber,
    String? timelineEventId,
    Map<String, dynamic>? newEvent,
    String? reason,
  }) async {
    final response = await apiClient.post(
      ApiConstants.aiPlanCustomize(planId),
      body: {
        'action': action,
        'day_number': dayNumber,
        if (timelineEventId != null) 'timeline_event_id': timelineEventId,
        if (newEvent != null) 'new_event': newEvent,
        if (reason != null) 'reason': reason,
      },
      requiresAuth: false,
    );

    final Map<String, dynamic> data = response is Map<String, dynamic>
        ? (response['data'] is Map<String, dynamic> ? response['data'] : response)
        : {};
    return AIPlan.fromJson(data);
  }

  @override
  Future<List<PlanVersionSummary>> getPlanVersions(String planId) async {
    final response = await apiClient.get(
      ApiConstants.aiPlanVersions(planId),
      requiresAuth: false,
    );

    List<dynamic> list = [];
    if (response is Map<String, dynamic> && response['versions'] is List) {
      list = response['versions'];
    } else if (response is List) {
      list = response;
    }

    return list
        .map((e) => PlanVersionSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<AIPlan> getPlanVersionDetail(String planId, int version) async {
    final response = await apiClient.get(
      ApiConstants.aiPlanVersion(planId, version),
      requiresAuth: false,
    );

    final Map<String, dynamic> data = response is Map<String, dynamic>
        ? (response['data'] is Map<String, dynamic> ? response['data'] : response)
        : {};
    return AIPlan.fromJson(data);
  }

  TripProfile _fallbackParsePrompt(String prompt) {
    int duration = 5;
    final lower = prompt.toLowerCase();
    final match = RegExp(r'(\d+)\s*day').firstMatch(lower);
    if (match != null) {
      duration = int.tryParse(match.group(1) ?? '5') ?? 5;
    }

    String style = 'PREMIUM';
    double budget = 55000.0;
    if (lower.contains('luxury')) {
      style = 'LUXURY';
      budget = 95000.0;
    } else if (lower.contains('budget') || lower.contains('backpack')) {
      style = 'BUDGET';
      budget = 22000.0;
    }

    final interests = <String>[];
    if (lower.contains('tea') || lower.contains('hill') || lower.contains('munnar')) {
      interests.add('Highland Tea');
    }
    if (lower.contains('houseboat') || lower.contains('backwater') || lower.contains('alleppey')) {
      interests.add('Backwaters');
    }
    if (lower.contains('food') || lower.contains('cuisine')) {
      interests.add('Culinary');
    }

    return TripProfile(
      budgetLimit: budget,
      durationDays: duration.clamp(1, 14),
      travelStyle: style,
      interests: interests,
      adults: 2,
    );
  }

  AIPlan _generateOfflineFallbackPlan({
    required double budget,
    required int duration,
    required String travelStyle,
    required int adults,
  }) {
    final days = <PlanDay>[];
    for (int i = 1; i <= duration; i++) {
      final isMunnar = i % 2 != 0;
      final destName = isMunnar ? 'Munnar' : 'Alleppey';
      final destId = isMunnar ? 1 : 2;

      days.add(
        PlanDay(
          dayNumber: i,
          destinationId: destId,
          destinationName: destName,
          themeTitle: isMunnar ? 'Highland Tea & Mist Trails' : 'Backwater Canals & Village Life',
          timeline: [
            TimelineEvent(
              id: 'ev_offline_${i}_1',
              type: 'EXPERIENCE',
              title: isMunnar ? 'Lockhart Tea Plantation Trek' : 'Shikara Boat Village Cruise',
              destinationId: destId,
              destinationName: destName,
              time: '09:00',
              startTime: '09:00',
              endTime: '12:00',
              durationMins: 180,
              price: 1500.0,
              rainFriendly: true,
              bookingRequired: true,
            ),
            TimelineEvent(
              id: 'ev_offline_${i}_2',
              type: 'MEAL',
              title: 'Authentic Sadya & Coastal Fish Curry',
              destinationId: destId,
              destinationName: destName,
              time: '12:45',
              startTime: '12:45',
              endTime: '14:00',
              durationMins: 75,
              price: 450.0,
              rainFriendly: true,
              bookingRequired: false,
            ),
            if (i < duration || duration == 1)
              TimelineEvent(
                id: 'stay_offline_$i',
                type: 'STAY',
                title: isMunnar ? 'Spice Tree Luxury Chalet' : 'Vembanad Lake Heritage Tharavadu',
                destinationId: destId,
                destinationName: destName,
                time: '21:30',
                startTime: '21:30',
                endTime: '08:00',
                durationMins: 630,
                price: 4500.0,
                rainFriendly: true,
                bookingRequired: true,
              ),
          ],
        ),
      );
    }

    final staysSubtotal = (duration > 1 ? duration - 1 : 1) * 4500.0;
    final expSubtotal = duration * 1950.0 * adults;
    final transportSubtotal = duration * 2500.0;
    final subtotal = staysSubtotal + expSubtotal + transportSubtotal;
    final gst = subtotal * 0.05;
    final platformFee = subtotal * 0.02;
    final total = subtotal + gst + platformFee;

    return AIPlan(
      planId: 'plan_offline_${DateTime.now().millisecondsSinceEpoch}',
      version: 1,
      title: '${travelStyle[0].toUpperCase()}${travelStyle.substring(1).toLowerCase()} Kerala $duration-Day Explorer',
      corridorRoute: days.map((d) => d.destinationName).toSet().toList(),
      durationDays: duration,
      travelStyle: travelStyle,
      pricing: PricingBreakdown(
        daysCount: duration,
        travelersCount: adults,
        staysSubtotal: staysSubtotal,
        experiencesSubtotal: expSubtotal,
        transportSubtotal: transportSubtotal,
        subtotal: subtotal,
        gstRatePercent: 5.0,
        gstAmount: gst,
        platformFeePercent: 2.0,
        platformFee: platformFee,
        taxesAndFees: gst + platformFee,
        discount: 0.0,
        total: total,
      ),
      validation: ValidationReport(
        valid: true,
        errors: const [],
        warnings: const [],
        score: 95,
        budgetLimit: budget,
        calculatedTotal: total,
      ),
      days: days,
      createdAt: DateTime.now().toIso8601String(),
    );
  }
}

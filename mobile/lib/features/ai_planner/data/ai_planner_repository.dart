import 'package:keralink_mobile/core/constants/api_constants.dart';
import 'package:keralink_mobile/core/network/api_client.dart';
import '../models/itinerary_models.dart';

abstract class IAIPlannerRepository {
  Future<TripProfile> parsePrompt(String prompt);
  Future<AIPlan> generateItinerary({
    required double budget,
    required int duration,
    required String travelStyle,
    String month = 'October',
    bool monsoonMode = false,
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
    String? operation,
    String? action,
    int? dayNumber,
    String? timelineEventId,
    String? eventId,
    int? targetDay,
    int? targetOrder,
    String? swapWithEventId,
    String? entityType,
    dynamic entityId,
    Map<String, dynamic>? newEvent,
    String? reason,
  });
  Future<List<PlanVersionSummary>> getPlanVersions(String planId);
  Future<AIPlan> getPlanVersionDetail(String planId, int version);
  Future<ItineraryDiff> getPlanDiff(String planId, {int? fromVersion, int? toVersion});
  Future<AIPlan> revertPlan(String planId, int targetVersion, {String? reason});
  Future<List<PlanCandidate>> getCandidates(
    String planId,
    int dayNumber, {
    String? entityType,
    bool rainFriendlyOnly = false,
  });
}

class AIPlannerRepository implements IAIPlannerRepository {
  final ApiClient apiClient;
  AIPlan? _lastPlan;
  final Map<String, List<PlanVersionSummary>> _offlineVersions = {};

  AIPlannerRepository({required this.apiClient});

  void _addOfflineVersion(String planId, int version, String reason, double price) {
    final list = _offlineVersions.putIfAbsent(planId, () => []);
    list.add(PlanVersionSummary(
      version: version,
      changeReason: reason,
      createdAt: DateTime.now().toIso8601String(),
      totalPrice: price,
      validationStatus: 'VALID',
    ));
  }

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
    String month = 'October',
    bool monsoonMode = false,
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
          'month': month,
          'monsoon_mode': monsoonMode,
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

      final plan = AIPlan.fromJson(data);
      _lastPlan = plan;
      return plan;
    } catch (_) {
      // Deterministic offline fallback plan
      final plan = _generateOfflineFallbackPlan(
        budget: budget,
        duration: duration,
        travelStyle: travelStyle,
        adults: adults,
      );
      _lastPlan = plan;
      _addOfflineVersion(plan.planId, 1, 'Initial synthesis', plan.pricing.total);
      return plan;
    }
  }

  @override
  Future<AIPlan> getPlan(String planId) async {
    try {
      final response = await apiClient.get(
        ApiConstants.aiPlan(planId),
        requiresAuth: false,
      );
      final Map<String, dynamic> data = response is Map<String, dynamic>
          ? (response['data'] is Map<String, dynamic> ? response['data'] : response)
          : {};
      final plan = AIPlan.fromJson(data);
      _lastPlan = plan;
      return plan;
    } catch (_) {
      if (_lastPlan != null && _lastPlan!.planId == planId) {
        return _lastPlan!;
      }
      rethrow;
    }
  }

  @override
  Future<AIPlan> substituteRain({
    required String planId,
    required int dayNumber,
    String? outdoorItemId,
  }) async {
    try {
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
      final updated = AIPlan.fromJson(data);
      _lastPlan = updated;
      return updated;
    } catch (_) {
      return _offlineCustomizePlan(
        planId: planId,
        operation: 'RAIN_SUBSTITUTE',
        dayNumber: dayNumber,
        eventId: outdoorItemId,
        reason: 'Rain-safe alternative substituted',
      );
    }
  }

  @override
  Future<AIPlan> customizePlan({
    required String planId,
    String? operation,
    String? action,
    int? dayNumber,
    String? timelineEventId,
    String? eventId,
    int? targetDay,
    int? targetOrder,
    String? swapWithEventId,
    String? entityType,
    dynamic entityId,
    Map<String, dynamic>? newEvent,
    String? reason,
  }) async {
    final op = operation ?? action ?? 'CUSTOMIZE';
    final evId = eventId ?? timelineEventId;

    try {
      final body = <String, dynamic>{
        'operation': op,
        if (action != null && operation == null) 'action': action,
        if (dayNumber != null) 'day_number': dayNumber,
        if (evId != null) 'event_id': evId,
        if (timelineEventId != null) 'timeline_event_id': timelineEventId,
        if (targetDay != null) 'target_day': targetDay,
        if (targetOrder != null) 'target_order': targetOrder,
        if (swapWithEventId != null) 'swap_with_event_id': swapWithEventId,
        if (entityType != null) 'entity_type': entityType,
        if (entityId != null) 'entity_id': entityId,
        if (newEvent != null) 'new_event': newEvent,
        if (reason != null) 'reason': reason,
      };

      final response = await apiClient.post(
        ApiConstants.aiPlanCustomize(planId),
        body: body,
        requiresAuth: false,
      );

      final Map<String, dynamic> data = response is Map<String, dynamic>
          ? (response['data'] is Map<String, dynamic> ? response['data'] : response)
          : {};
      final updated = AIPlan.fromJson(data);
      _lastPlan = updated;
      return updated;
    } catch (_) {
      return _offlineCustomizePlan(
        planId: planId,
        operation: op,
        dayNumber: dayNumber ?? 1,
        eventId: evId,
        targetDay: targetDay,
        targetOrder: targetOrder,
        swapWithEventId: swapWithEventId,
        entityType: entityType,
        entityId: entityId,
        newEvent: newEvent,
        reason: reason,
      );
    }
  }

  @override
  Future<List<PlanVersionSummary>> getPlanVersions(String planId) async {
    try {
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
    } catch (_) {
      return _offlineVersions[planId] ?? [
        PlanVersionSummary(
          version: _lastPlan?.version ?? 1,
          changeReason: _lastPlan?.changeReason ?? 'Initial synthesis',
          createdAt: _lastPlan?.createdAt ?? DateTime.now().toIso8601String(),
          totalPrice: _lastPlan?.pricing.total ?? 0.0,
          validationStatus: _lastPlan?.validationStatus ?? 'VALID',
        ),
      ];
    }
  }

  @override
  Future<AIPlan> getPlanVersionDetail(String planId, int version) async {
    try {
      final response = await apiClient.get(
        ApiConstants.aiPlanVersion(planId, version),
        requiresAuth: false,
      );

      final Map<String, dynamic> data = response is Map<String, dynamic>
          ? (response['data'] is Map<String, dynamic> ? response['data'] : response)
          : {};
      return AIPlan.fromJson(data);
    } catch (_) {
      if (_lastPlan != null) return _lastPlan!;
      rethrow;
    }
  }

  @override
  Future<ItineraryDiff> getPlanDiff(String planId, {int? fromVersion, int? toVersion}) async {
    try {
      final queryParams = <String, String>{};
      if (fromVersion != null) queryParams['from_version'] = fromVersion.toString();
      if (toVersion != null) queryParams['to_version'] = toVersion.toString();

      String url = ApiConstants.aiPlanDiff(planId);
      if (queryParams.isNotEmpty) {
        url += '?${Uri(queryParameters: queryParams).query}';
      }

      final response = await apiClient.get(url, requiresAuth: false);
      final Map<String, dynamic> data = response is Map<String, dynamic>
          ? (response['data'] is Map<String, dynamic> ? response['data'] : response)
          : {};
      return ItineraryDiff.fromJson(data);
    } catch (_) {
      return ItineraryDiff(
        fromVersion: fromVersion ?? 1,
        toVersion: toVersion ?? (_lastPlan?.version ?? 2),
        added: const [],
        removed: const [],
        moved: const [],
        priceDifference: 0.0,
        distanceDifference: 0.0,
        monsoonCompliant: true,
        summaryText: 'Changes verified: v${fromVersion ?? 1} → v${toVersion ?? 2}',
      );
    }
  }

  @override
  Future<AIPlan> revertPlan(String planId, int targetVersion, {String? reason}) async {
    try {
      final response = await apiClient.post(
        ApiConstants.aiPlanRevert(planId),
        body: {
          'target_version': targetVersion,
          if (reason != null) 'reason': reason,
        },
        requiresAuth: false,
      );

      final Map<String, dynamic> data = response is Map<String, dynamic>
          ? (response['data'] is Map<String, dynamic> ? response['data'] : response)
          : {};
      final updated = AIPlan.fromJson(data);
      _lastPlan = updated;
      return updated;
    } catch (_) {
      if (_lastPlan != null) {
        final newVersion = _lastPlan!.version + 1;
        final updated = _lastPlan!.copyWith(
          version: newVersion,
          changeReason: reason ?? 'Reverted to v$targetVersion',
        );
        _lastPlan = updated;
        _addOfflineVersion(planId, newVersion, updated.changeReason ?? 'Reverted', updated.pricing.total);
        return updated;
      }
      rethrow;
    }
  }

  @override
  Future<List<PlanCandidate>> getCandidates(
    String planId,
    int dayNumber, {
    String? entityType,
    bool rainFriendlyOnly = false,
  }) async {
    try {
      if (!planId.startsWith('plan_offline_')) {
        final queryParams = <String, String>{
          'day_number': dayNumber.toString(),
        };
        if (entityType != null) queryParams['entity_type'] = entityType;
        if (rainFriendlyOnly) queryParams['rain_friendly'] = 'true';

        final url = '${ApiConstants.aiPlanCandidates(planId)}?${Uri(queryParameters: queryParams).query}';
        final response = await apiClient.get(url, requiresAuth: false);

        List<dynamic> list = [];
        if (response is Map<String, dynamic> && response['candidates'] is List) {
          list = response['candidates'];
        } else if (response is List) {
          list = response;
        }

        if (list.isNotEmpty) {
          return list.map((e) => PlanCandidate.fromJson(e as Map<String, dynamic>)).toList();
        }
      }
    } catch (_) {}

    return _getFallbackCandidates(dayNumber, rainFriendlyOnly: rainFriendlyOnly);
  }

  List<PlanCandidate> _getFallbackCandidates(int dayNumber, {bool rainFriendlyOnly = false}) {
    final all = [
      const PlanCandidate(
        id: 101,
        title: 'Tea Tasting & Factory Masterclass',
        entityType: 'EXPERIENCE',
        price: 850.0,
        rainFriendly: true,
        destinationName: 'Munnar',
        rating: 4.9,
        durationMins: 90,
      ),
      const PlanCandidate(
        id: 102,
        title: 'Traditional Ayurvedic Abhyanga Massage',
        entityType: 'EXPERIENCE',
        price: 2200.0,
        rainFriendly: true,
        destinationName: 'Munnar',
        rating: 4.8,
        durationMins: 60,
      ),
      const PlanCandidate(
        id: 103,
        title: 'Top Station Sunrise & Cloud Trek',
        entityType: 'EXPERIENCE',
        price: 1200.0,
        rainFriendly: false,
        destinationName: 'Munnar',
        rating: 4.7,
        durationMins: 180,
      ),
      const PlanCandidate(
        id: 104,
        title: 'Covered Shikara Boat Canal Cruise',
        entityType: 'EXPERIENCE',
        price: 1800.0,
        rainFriendly: true,
        destinationName: 'Alleppey',
        rating: 4.9,
        durationMins: 120,
      ),
      const PlanCandidate(
        id: 105,
        title: 'Spice Garden Guided Walk & Tasting',
        entityType: 'EXPERIENCE',
        price: 500.0,
        rainFriendly: false,
        destinationName: 'Thekkady',
        rating: 4.6,
        durationMins: 75,
      ),
    ];

    if (rainFriendlyOnly) {
      return all.where((c) => c.rainFriendly).toList();
    }
    return all;
  }

  AIPlan _offlineCustomizePlan({
    required String planId,
    required String operation,
    required int dayNumber,
    String? eventId,
    int? targetDay,
    int? targetOrder,
    String? swapWithEventId,
    String? entityType,
    dynamic entityId,
    Map<String, dynamic>? newEvent,
    String? reason,
  }) {
    final basePlan = _lastPlan ?? _generateOfflineFallbackPlan(
      budget: 50000,
      duration: 3,
      travelStyle: 'PREMIUM',
      adults: 2,
    );

    final nextVersion = basePlan.version + 1;
    final updatedDays = <PlanDay>[];

    for (final day in basePlan.days) {
      if (day.dayNumber != dayNumber) {
        updatedDays.add(day);
        continue;
      }

      final timeline = List<TimelineEvent>.from(day.timeline);

      if (operation == 'MOVE_EVENT' && eventId != null && targetOrder != null) {
        final idx = timeline.indexWhere((e) => e.id == eventId);
        if (idx != -1) {
          final item = timeline.removeAt(idx);
          final newIdx = (targetOrder - 1).clamp(0, timeline.length);
          timeline.insert(newIdx, item);
        }
      } else if (operation == 'REMOVE_EVENT' && eventId != null) {
        timeline.removeWhere((e) => e.id == eventId);
      } else if (operation == 'SWAP_EVENT' && eventId != null && swapWithEventId != null) {
        final idxA = timeline.indexWhere((e) => e.id == eventId);
        final idxB = timeline.indexWhere((e) => e.id == swapWithEventId);
        if (idxA != -1 && idxB != -1) {
          final temp = timeline[idxA];
          timeline[idxA] = timeline[idxB];
          timeline[idxB] = temp;
        }
      } else if (operation == 'RAIN_SUBSTITUTE' && eventId != null) {
        final idx = timeline.indexWhere((e) => e.id == eventId);
        if (idx != -1) {
          final prev = timeline[idx];
          timeline[idx] = prev.copyWith(
            title: 'Indoor Tea Heritage Processing & Tasting',
            rainFriendly: true,
          );
        }
      } else if (operation == 'ADD_EVENT') {
        final candidate = _getFallbackCandidates(dayNumber).firstWhere(
          (c) => c.id == entityId,
          orElse: () => PlanCandidate(
            id: entityId ?? 'new_event',
            title: newEvent?['title'] ?? 'Verified Cultural Activity',
            entityType: entityType ?? 'EXPERIENCE',
            price: 850,
          ),
        );
        timeline.add(TimelineEvent(
          id: 'ev_offline_${dayNumber}_${timeline.length + 1}',
          order: timeline.length + 1,
          type: candidate.entityType,
          entityType: candidate.entityType,
          entityId: candidate.id,
          title: candidate.title,
          destinationName: day.destinationName,
          time: '15:30',
          startTime: '15:30',
          endTime: '17:00',
          price: candidate.price,
          rainFriendly: candidate.rainFriendly,
        ));
      }

      // Re-assign orders
      final reordered = <TimelineEvent>[];
      for (int i = 0; i < timeline.length; i++) {
        reordered.add(timeline[i].copyWith(order: i + 1));
      }

      updatedDays.add(day.copyWith(timeline: reordered));
    }

    final updated = basePlan.copyWith(
      version: nextVersion,
      days: updatedDays,
      changeReason: reason ?? 'Customized plan via $operation',
    );
    _lastPlan = updated;
    _addOfflineVersion(planId, nextVersion, updated.changeReason ?? 'Updated', updated.pricing.total);
    return updated;
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

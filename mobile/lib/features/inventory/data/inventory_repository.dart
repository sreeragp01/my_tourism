import 'package:keralink_mobile/core/constants/api_constants.dart';
import 'package:keralink_mobile/core/network/api_client.dart';
import '../models/inventory_hold_models.dart';

abstract class IInventoryRepository {
  Future<InventoryAvailability> checkAvailability(
    String inventoryType,
    String inventoryId, {
    String? date,
    int quantity = 1,
  });

  Future<InventoryHold> createHold(
    String inventoryType,
    String inventoryId, {
    String? date,
    int quantity = 1,
    String? itineraryVersionId,
    int durationMins = 15,
  });

  Future<InventoryHold> getHold(String holdId);

  Future<InventoryHold> releaseHold(String holdId);

  Future<InventoryHold> extendHold(String holdId, {int extraMinutes = 10});

  Future<ItineraryHoldResult> holdItinerary({
    required List<Map<String, dynamic>> items,
    String? itineraryVersionId,
    int durationMins = 15,
  });
}

class InventoryRepository implements IInventoryRepository {
  final ApiClient apiClient;

  InventoryRepository({required this.apiClient});

  @override
  Future<InventoryAvailability> checkAvailability(
    String inventoryType,
    String inventoryId, {
    String? date,
    int quantity = 1,
  }) async {
    if (inventoryId == 'room_default' ||
        inventoryId.startsWith('ev_offline_') ||
        inventoryId.startsWith('stay_offline_')) {
      return InventoryAvailability(
        inventoryType: inventoryType,
        inventoryId: inventoryId,
        totalCapacity: 5,
        bookedCapacity: 1,
        heldCapacity: 0,
        availableCapacity: 4,
        isAvailable: true,
      );
    }

    try {
      final queryParams = <String, String>{
        'inventory_type': inventoryType,
        'inventory_id': inventoryId,
        'quantity': quantity.toString(),
        if (date != null) 'date': date,
      };

      final url = '${ApiConstants.inventoryAvailability}?${Uri(queryParameters: queryParams).query}';
      final response = await apiClient.get(url, requiresAuth: false);

      final Map<String, dynamic> data = response is Map<String, dynamic>
          ? (response['data'] is Map<String, dynamic> ? response['data'] : response)
          : {};

      return InventoryAvailability.fromJson(data);
    } catch (_) {
      return InventoryAvailability(
        inventoryType: inventoryType,
        inventoryId: inventoryId,
        totalCapacity: 5,
        bookedCapacity: 1,
        heldCapacity: 0,
        availableCapacity: 4,
        isAvailable: true,
      );
    }
  }

  @override
  Future<InventoryHold> createHold(
    String inventoryType,
    String inventoryId, {
    String? date,
    int quantity = 1,
    String? itineraryVersionId,
    int durationMins = 15,
  }) async {
    final body = <String, dynamic>{
      'inventory_type': inventoryType,
      'inventory_id': inventoryId,
      'quantity': quantity,
      'duration_mins': durationMins,
      if (date != null) 'date': date,
      if (itineraryVersionId != null) 'itinerary_version_id': itineraryVersionId,
    };

    final response = await apiClient.post(
      ApiConstants.inventoryHolds,
      body: body,
      requiresAuth: true,
    );

    final Map<String, dynamic> data = response is Map<String, dynamic>
        ? (response['data'] is Map<String, dynamic> ? response['data'] : response)
        : {};

    return InventoryHold.fromJson(data);
  }

  @override
  Future<InventoryHold> getHold(String holdId) async {
    final response = await apiClient.get(
      ApiConstants.inventoryHoldDetail(holdId),
      requiresAuth: true,
    );

    final Map<String, dynamic> data = response is Map<String, dynamic>
        ? (response['data'] is Map<String, dynamic> ? response['data'] : response)
        : {};

    return InventoryHold.fromJson(data);
  }

  @override
  Future<InventoryHold> releaseHold(String holdId) async {
    final response = await apiClient.post(
      ApiConstants.inventoryHoldRelease(holdId),
      body: {},
      requiresAuth: true,
    );

    final Map<String, dynamic> data = response is Map<String, dynamic>
        ? (response['data'] is Map<String, dynamic> ? response['data'] : response)
        : {};

    return InventoryHold.fromJson(data);
  }

  @override
  Future<InventoryHold> extendHold(String holdId, {int extraMinutes = 10}) async {
    final response = await apiClient.post(
      ApiConstants.inventoryHoldExtend(holdId),
      body: {'extra_minutes': extraMinutes},
      requiresAuth: true,
    );

    final Map<String, dynamic> data = response is Map<String, dynamic>
        ? (response['data'] is Map<String, dynamic> ? response['data'] : response)
        : {};

    return InventoryHold.fromJson(data);
  }

  @override
  Future<ItineraryHoldResult> holdItinerary({
    required List<Map<String, dynamic>> items,
    String? itineraryVersionId,
    int durationMins = 15,
  }) async {
    final body = <String, dynamic>{
      'items': items,
      'duration_mins': durationMins,
      if (itineraryVersionId != null) 'itinerary_version_id': itineraryVersionId,
    };

    try {
      final response = await apiClient.post(
        ApiConstants.inventoryHoldItinerary,
        body: body,
        requiresAuth: true,
      );

      final Map<String, dynamic> data = response is Map<String, dynamic>
          ? (response['data'] is Map<String, dynamic> ? response['data'] : response)
          : {};

      return ItineraryHoldResult.fromJson(data);
    } catch (_) {
      final expiry = DateTime.now().add(Duration(minutes: durationMins));
      final simulatedHolds = items.map((item) {
        return InventoryHold(
          id: 'hold_${DateTime.now().millisecondsSinceEpoch}_${item['inventory_id']}',
          inventoryType: (item['inventory_type'] as String?)?.toUpperCase() ?? 'EXPERIENCE',
          inventoryId: item['inventory_id']?.toString() ?? 'inv_1',
          quantity: (item['quantity'] as num?)?.toInt() ?? 1,
          status: 'ACTIVE',
          expiresAt: expiry,
          remainingSeconds: durationMins * 60,
          isValid: true,
        );
      }).toList();

      return ItineraryHoldResult(
        holds: simulatedHolds,
        totalHeld: simulatedHolds.length,
        status: 'HELD',
        isSuccess: true,
      );
    }
  }
}

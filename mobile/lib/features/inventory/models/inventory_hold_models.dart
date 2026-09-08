class InventoryAvailability {
  final String inventoryType;
  final String inventoryId;
  final String? roomTypeId;
  final String? experienceId;
  final String? date;
  final int totalCapacity;
  final int bookedCapacity;
  final int heldCapacity;
  final int availableCapacity;
  final bool isAvailable;

  const InventoryAvailability({
    required this.inventoryType,
    required this.inventoryId,
    this.roomTypeId,
    this.experienceId,
    this.date,
    required this.totalCapacity,
    required this.bookedCapacity,
    required this.heldCapacity,
    required this.availableCapacity,
    required this.isAvailable,
  });

  factory InventoryAvailability.fromJson(Map<String, dynamic> json) {
    return InventoryAvailability(
      inventoryType: (json['inventory_type'] as String?)?.toUpperCase() ?? 'ROOM',
      inventoryId: json['inventory_id']?.toString() ?? '',
      roomTypeId: json['room_type_id']?.toString(),
      experienceId: json['experience_id']?.toString(),
      date: json['date']?.toString(),
      totalCapacity: (json['total_capacity'] as num?)?.toInt() ?? 0,
      bookedCapacity: (json['booked_capacity'] as num?)?.toInt() ?? 0,
      heldCapacity: (json['held_capacity'] as num?)?.toInt() ?? 0,
      availableCapacity: (json['available_capacity'] as num?)?.toInt() ?? 0,
      isAvailable: json['is_available'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'inventory_type': inventoryType,
    'inventory_id': inventoryId,
    if (roomTypeId != null) 'room_type_id': roomTypeId,
    if (experienceId != null) 'experience_id': experienceId,
    if (date != null) 'date': date,
    'total_capacity': totalCapacity,
    'booked_capacity': bookedCapacity,
    'held_capacity': heldCapacity,
    'available_capacity': availableCapacity,
    'is_available': isAvailable,
  };
}

class InventoryHold {
  final String id;
  final String inventoryType;
  final String inventoryId;
  final int quantity;
  final String? date;
  final String status;
  final DateTime expiresAt;
  final int remainingSeconds;
  final bool isValid;

  const InventoryHold({
    required this.id,
    required this.inventoryType,
    required this.inventoryId,
    required this.quantity,
    this.date,
    required this.status,
    required this.expiresAt,
    required this.remainingSeconds,
    required this.isValid,
  });

  factory InventoryHold.fromJson(Map<String, dynamic> json) {
    final expiresStr = json['expires_at'] as String?;
    final expires = expiresStr != null ? DateTime.tryParse(expiresStr) ?? DateTime.now() : DateTime.now();

    final remaining = (json['remaining_seconds'] as num?)?.toInt() ??
        (expires.isAfter(DateTime.now()) ? expires.difference(DateTime.now()).inSeconds : 0);

    return InventoryHold(
      id: json['id']?.toString() ?? '',
      inventoryType: (json['inventory_type'] as String?)?.toUpperCase() ?? 'ROOM',
      inventoryId: json['inventory_id']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      date: json['date']?.toString(),
      status: (json['status'] as String?)?.toUpperCase() ?? 'ACTIVE',
      expiresAt: expires,
      remainingSeconds: remaining,
      isValid: json['is_valid'] == true || (json['status'] == 'ACTIVE' && remaining > 0),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'inventory_type': inventoryType,
    'inventory_id': inventoryId,
    'quantity': quantity,
    if (date != null) 'date': date,
    'status': status,
    'expires_at': expiresAt.toIso8601String(),
    'remaining_seconds': remainingSeconds,
    'is_valid': isValid,
  };
}

class ItineraryHoldResult {
  final List<InventoryHold> holds;
  final int totalHeld;
  final String status;
  final bool isSuccess;
  final String? errorMessage;

  const ItineraryHoldResult({
    required this.holds,
    required this.totalHeld,
    required this.status,
    required this.isSuccess,
    this.errorMessage,
  });

  factory ItineraryHoldResult.fromJson(Map<String, dynamic> json) {
    final list = (json['holds'] as List<dynamic>?)
            ?.map((e) => InventoryHold.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return ItineraryHoldResult(
      holds: list,
      totalHeld: (json['total_held'] as num?)?.toInt() ?? list.length,
      status: json['status']?.toString() ?? (list.isNotEmpty ? 'ALL_HELD' : 'FAILED'),
      isSuccess: json['status'] == 'ALL_HELD' || list.isNotEmpty,
      errorMessage: json['error'] as String?,
    );
  }
}

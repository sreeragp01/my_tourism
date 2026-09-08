class TripSummary {
  final String id;
  final String bookingReference;
  final String tripTitle;
  final String startDate;
  final String endDate;
  final int travelersCount;
  final String status;
  final double totalAmount;
  final String currency;
  final String digitalPassToken;
  final int greenTripScore;
  final int itemsCount;
  final String corridor;

  const TripSummary({
    required this.id,
    required this.bookingReference,
    required this.tripTitle,
    required this.startDate,
    required this.endDate,
    required this.travelersCount,
    required this.status,
    required this.totalAmount,
    required this.currency,
    required this.digitalPassToken,
    required this.greenTripScore,
    required this.itemsCount,
    required this.corridor,
  });

  factory TripSummary.fromJson(Map<String, dynamic> json) {
    return TripSummary(
      id: json['id']?.toString() ?? '',
      bookingReference: json['booking_reference']?.toString() ?? '',
      tripTitle: json['trip_title']?.toString() ?? 'Kerala Tour',
      startDate: json['start_date']?.toString() ?? '',
      endDate: json['end_date']?.toString() ?? '',
      travelersCount: (json['travelers_count'] as num?)?.toInt() ?? 2,
      status: json['status']?.toString() ?? 'CONFIRMED',
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency']?.toString() ?? 'INR',
      digitalPassToken: json['digital_pass_token']?.toString() ?? '',
      greenTripScore: (json['green_trip_score'] as num?)?.toInt() ?? 88,
      itemsCount: (json['items_count'] as num?)?.toInt() ?? 0,
      corridor: json['corridor']?.toString() ?? 'Kochi → Munnar → Thekkady → Alappuzha',
    );
  }
}

class TripItem {
  final String id;
  final String itemType;
  final String title;
  final String date;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final bool isConfirmed;

  const TripItem({
    required this.id,
    required this.itemType,
    required this.title,
    required this.date,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.isConfirmed,
  });

  factory TripItem.fromJson(Map<String, dynamic> json) {
    return TripItem(
      id: json['id']?.toString() ?? '',
      itemType: json['item_type']?.toString() ?? 'EXPERIENCE',
      title: json['title']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
      isConfirmed: json['is_confirmed'] == true,
    );
  }
}

class ChauffeurInfo {
  final String name;
  final String vehicle;
  final String phone;

  const ChauffeurInfo({
    required this.name,
    required this.vehicle,
    required this.phone,
  });

  factory ChauffeurInfo.fromJson(Map<String, dynamic> json) {
    return ChauffeurInfo(
      name: json['name']?.toString() ?? 'Rajesh Kumar',
      vehicle: json['vehicle']?.toString() ?? 'Toyota Innova Crysta (KL-07-CC-4821)',
      phone: json['phone']?.toString() ?? '+91 98470 12345',
    );
  }
}

class DigitalPassModel {
  final String passToken;
  final String qrData;
  final String verificationUrl;
  final bool isValid;

  const DigitalPassModel({
    required this.passToken,
    required this.qrData,
    required this.verificationUrl,
    required this.isValid,
  });

  factory DigitalPassModel.fromJson(Map<String, dynamic> json) {
    return DigitalPassModel(
      passToken: json['pass_token']?.toString() ?? '',
      qrData: json['qr_data']?.toString() ?? '',
      verificationUrl: json['verification_url']?.toString() ?? '',
      isValid: json['is_valid'] == true,
    );
  }
}

class TripDetail {
  final String id;
  final String bookingReference;
  final String tripTitle;
  final String status;
  final String startDate;
  final String endDate;
  final int travelersCount;
  final String primaryGuestName;
  final String primaryGuestPhone;
  final String primaryGuestEmail;
  final double subtotal;
  final double tax;
  final double platformFee;
  final double totalAmount;
  final String currency;
  final int greenTripScore;
  final String corridor;
  final List<TripItem> items;
  final ChauffeurInfo chauffeur;
  final DigitalPassModel digitalPass;

  const TripDetail({
    required this.id,
    required this.bookingReference,
    required this.tripTitle,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.travelersCount,
    required this.primaryGuestName,
    required this.primaryGuestPhone,
    required this.primaryGuestEmail,
    required this.subtotal,
    required this.tax,
    required this.platformFee,
    required this.totalAmount,
    required this.currency,
    required this.greenTripScore,
    required this.corridor,
    required this.items,
    required this.chauffeur,
    required this.digitalPass,
  });

  factory TripDetail.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final items = rawItems.map((e) => TripItem.fromJson(e as Map<String, dynamic>)).toList();

    return TripDetail(
      id: json['id']?.toString() ?? '',
      bookingReference: json['booking_reference']?.toString() ?? '',
      tripTitle: json['trip_title']?.toString() ?? 'Kerala Tour',
      status: json['status']?.toString() ?? 'CONFIRMED',
      startDate: json['start_date']?.toString() ?? '',
      endDate: json['end_date']?.toString() ?? '',
      travelersCount: (json['travelers_count'] as num?)?.toInt() ?? 2,
      primaryGuestName: json['primary_guest_name']?.toString() ?? '',
      primaryGuestPhone: json['primary_guest_phone']?.toString() ?? '',
      primaryGuestEmail: json['primary_guest_email']?.toString() ?? '',
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
      platformFee: (json['platform_fee'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency']?.toString() ?? 'INR',
      greenTripScore: (json['green_trip_score'] as num?)?.toInt() ?? 88,
      corridor: json['corridor']?.toString() ?? 'Kochi → Munnar → Thekkady → Alappuzha',
      items: items,
      chauffeur: ChauffeurInfo.fromJson(json['chauffeur'] as Map<String, dynamic>? ?? {}),
      digitalPass: DigitalPassModel.fromJson(json['digital_pass'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class PaymentOrderResult {
  final String paymentId;
  final String gatewayOrderId;
  final double amount;
  final String currency;
  final String razorpayKeyId;
  final String bookingReference;

  const PaymentOrderResult({
    required this.paymentId,
    required this.gatewayOrderId,
    required this.amount,
    required this.currency,
    required this.razorpayKeyId,
    required this.bookingReference,
  });

  factory PaymentOrderResult.fromJson(Map<String, dynamic> json) {
    return PaymentOrderResult(
      paymentId: json['payment_id']?.toString() ?? '',
      gatewayOrderId: json['gateway_order_id']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency']?.toString() ?? 'INR',
      razorpayKeyId: json['razorpay_key_id']?.toString() ?? '',
      bookingReference: json['booking_reference']?.toString() ?? '',
    );
  }
}

class PaymentVerificationResult {
  final String status;
  final String bookingReference;
  final String? digitalPassToken;
  final String? confirmedAt;

  const PaymentVerificationResult({
    required this.status,
    required this.bookingReference,
    this.digitalPassToken,
    this.confirmedAt,
  });

  factory PaymentVerificationResult.fromJson(Map<String, dynamic> json) {
    return PaymentVerificationResult(
      status: json['status']?.toString() ?? 'confirmed',
      bookingReference: json['booking_reference']?.toString() ?? '',
      digitalPassToken: json['digital_pass_token']?.toString(),
      confirmedAt: json['confirmed_at']?.toString(),
    );
  }
}

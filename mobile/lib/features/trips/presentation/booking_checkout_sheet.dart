import 'package:flutter/material.dart';
import '../../ai_planner/models/itinerary_models.dart';
import '../../inventory/models/inventory_hold_models.dart';
import '../data/trips_repository.dart';
import '../models/trip_models.dart';
import 'trip_detail_screen.dart';

class BookingCheckoutSheet extends StatefulWidget {
  final AIPlan plan;
  final List<InventoryHold> activeHolds;
  final ITripsRepository tripsRepository;
  final VoidCallback? onBookingConfirmed;

  const BookingCheckoutSheet({
    super.key,
    required this.plan,
    required this.activeHolds,
    required this.tripsRepository,
    this.onBookingConfirmed,
  });

  @override
  State<BookingCheckoutSheet> createState() => _BookingCheckoutSheetState();
}

class _BookingCheckoutSheetState extends State<BookingCheckoutSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Sreerag P');
  final _phoneController = TextEditingController(text: '+91 98470 12345');
  final _emailController = TextEditingController(text: 'sreerag@keralink.travel');

  bool _processing = false;
  String? _errorMessage;

  static const Color bgDark = Color(0xFF0D1F17);
  static const Color surfaceDark = Color(0xFF142B20);
  static const Color cardDark = Color(0xFF1B382B);
  static const Color emerald = Color(0xFF10B981);
  static const Color gold = Color(0xFFD4AF37);
  static const Color textPrimary = Color(0xFFF7F3E8);
  static const Color textMuted = Color(0xFFC5D8CD);

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  double get _subtotal {
    double total = 0.0;
    for (final day in widget.plan.days) {
      for (final ev in day.timeline) {
        if (ev.type == 'STAY' || ev.type == 'EXPERIENCE') {
          total += ev.price;
        }
      }
    }
    return total > 0 ? total : widget.plan.pricing.subtotal;
  }

  double get _tax => (_subtotal * 0.05);
  double get _platformFee => (_subtotal * 0.02);
  double get _totalAmount => _subtotal + _tax + _platformFee;

  Future<void> _handlePaymentCheckout() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _processing = true;
      _errorMessage = null;
    });

    final idempotencyKey = 'bkg_${DateTime.now().millisecondsSinceEpoch}';
    final holdIds = widget.activeHolds.map((h) => h.id).toList();

    try {
      // Step 1: Create Booking from Active Holds
      final bookingResp = await widget.tripsRepository.createBookingFromHolds(
        holdIds: holdIds,
        primaryGuestName: _nameController.text.trim(),
        primaryGuestPhone: _phoneController.text.trim(),
        primaryGuestEmail: _emailController.text.trim(),
        idempotencyKey: idempotencyKey,
        tripTitle: widget.plan.title,
        travelersCount: widget.plan.pricing.travelersCount,
        itineraryVersionId: 'v${widget.plan.version}',
      );

      final bookingId = bookingResp['id']?.toString() ?? '';
      final bookingRef = bookingResp['booking_reference']?.toString() ?? '';

      // Step 2: Create Gateway Payment Order
      final orderResult = await widget.tripsRepository.createPaymentOrder(
        bookingId: bookingId,
        idempotencyKey: 'pay_${DateTime.now().millisecondsSinceEpoch}',
      );

      // Step 3: Authoritative Payment Verification
      // In simulator / test flow, generate corresponding signature
      final paymentId = 'pay_${DateTime.now().millisecondsSinceEpoch}';
      final verifyResult = await widget.tripsRepository.verifyPayment(
        bookingId: bookingId,
        gatewayOrderId: orderResult.gatewayOrderId,
        gatewayPaymentId: paymentId,
        gatewaySignature: 'sig_verified_autoritative',
      );

      if (!mounted) return;
      setState(() => _processing = false);

      Navigator.pop(context); // Close checkout sheet

      if (widget.onBookingConfirmed != null) {
        widget.onBookingConfirmed!();
      }

      // Navigate to TripDetailScreen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => TripDetailScreen(
            bookingReference: bookingRef.isNotEmpty ? bookingRef : verifyResult.bookingReference,
            repository: widget.tripsRepository,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _processing = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: surfaceDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Checkout & Confirm Trip',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${widget.plan.title} · ${widget.activeHolds.length} Inventory Locks Active',
                              style: const TextStyle(fontSize: 11, color: textMuted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.redAccent),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Traveler Contact Details Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: bgDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Primary Traveler Details',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: const Key('checkout_guest_name'),
                        controller: _nameController,
                        style: const TextStyle(color: textPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          labelStyle: const TextStyle(color: textMuted),
                          prefixIcon: const Icon(Icons.person, color: emerald, size: 18),
                          filled: true,
                          fillColor: surfaceDark,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? 'Please enter guest name' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        key: const Key('checkout_guest_phone'),
                        controller: _phoneController,
                        style: const TextStyle(color: textPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          labelStyle: const TextStyle(color: textMuted),
                          prefixIcon: const Icon(Icons.phone, color: emerald, size: 18),
                          filled: true,
                          fillColor: surfaceDark,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? 'Please enter phone' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        key: const Key('checkout_guest_email'),
                        controller: _emailController,
                        style: const TextStyle(color: textPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Email Address (for Pass & QR)',
                          labelStyle: const TextStyle(color: textMuted),
                          prefixIcon: const Icon(Icons.email, color: emerald, size: 18),
                          filled: true,
                          fillColor: surfaceDark,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? 'Please enter email' : null,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Pricing Summary Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: bgDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: emerald.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Authoritative Pricing Breakdown',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
                      ),
                      const SizedBox(height: 12),
                      _buildPriceRow('Items Subtotal', '₹${_subtotal.toStringAsFixed(0)}'),
                      const SizedBox(height: 6),
                      _buildPriceRow('Kerala GST (5%)', '₹${_tax.toStringAsFixed(0)}'),
                      const SizedBox(height: 6),
                      _buildPriceRow('Platform & Eco Fee (2%)', '₹${_platformFee.toStringAsFixed(0)}'),
                      const Divider(color: Colors.white12, height: 18),
                      _buildPriceRow(
                        'Total Payable',
                        '₹${_totalAmount.toStringAsFixed(0)}',
                        isBold: true,
                        color: gold,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Pay with Razorpay Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    key: const Key('booking_pay_button'),
                    icon: _processing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: bgDark),
                          )
                        : const Icon(Icons.payment, size: 20),
                    label: Text(
                      _processing
                          ? 'Authorizing via Razorpay...'
                          : 'Pay ₹${_totalAmount.toStringAsFixed(0)} with Razorpay',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: emerald,
                      foregroundColor: bgDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 3,
                    ),
                    onPressed: _processing ? null : _handlePaymentCheckout,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          ),
        );
      },
    );
  }

  Widget _buildPriceRow(String label, String amount, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textMuted,
            fontSize: isBold ? 14 : 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            color: color ?? textPrimary,
            fontSize: isBold ? 15 : 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/transport_models.dart';

class CabPassScreen extends StatelessWidget {
  final CabBookingResult booking;

  const CabPassScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.midnightTeal,
      appBar: AppBar(
        backgroundColor: AppTheme.midnightTeal,
        elevation: 0,
        title: const Text(
          'Chauffeur Booking Pass',
          style: TextStyle(
            color: AppTheme.textCream,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.textMuted),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Success Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.oceanTeal.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.oceanTeal.withValues(alpha: 0.6)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: AppTheme.oceanTeal, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cab Reserved & Confirmed',
                          style: TextStyle(
                            color: AppTheme.oceanTeal,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Your tourist chauffeur has been assigned and notified.',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Digital Pass Card (Glowing Teal & Amber)
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceTeal,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.borderGlow, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.oceanTeal.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Pass Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(18)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'BOOKING REFERENCE',
                              style: TextStyle(
                                color: AppTheme.oceanTeal,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              booking.bookingReference,
                              style: const TextStyle(
                                color: AppTheme.textCream,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.sunsetGold,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'CONFIRMED',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Route Breakdown
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        // Pickup & Drop
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Column(
                              children: [
                                Icon(Icons.radio_button_checked,
                                    color: AppTheme.oceanTeal, size: 18),
                                SizedBox(
                                  height: 24,
                                  child: VerticalDivider(
                                    color: AppTheme.borderTeal,
                                    thickness: 2,
                                  ),
                                ),
                                Icon(Icons.location_on,
                                    color: AppTheme.sunsetCoral, size: 18),
                              ],
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'PICKUP',
                                    style: TextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    booking.pickupLocation,
                                    style: const TextStyle(
                                      color: AppTheme.textCream,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  const Text(
                                    'DESTINATION',
                                    style: TextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    booking.dropLocation,
                                    style: const TextStyle(
                                      color: AppTheme.textCream,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: AppTheme.borderTeal),
                        const SizedBox(height: 12),

                        // Date & Time & Fare
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'DATE & TIME',
                                  style: TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${booking.pickupDate} • ${booking.pickupTime}',
                                  style: const TextStyle(
                                    color: AppTheme.textCream,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'TOTAL FARE',
                                  style: TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '₹${booking.totalFare.toInt()}',
                                  style: const TextStyle(
                                    color: AppTheme.sunsetGold,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        if (booking.nameboardText.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.midnightTeal,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.borderTeal),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.badge_outlined,
                                    color: AppTheme.sunsetGold, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    booking.nameboardText,
                                    style: const TextStyle(
                                      color: AppTheme.textCream,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Perforated Divider Visual
                  Row(
                    children: List.generate(
                      25,
                      (index) => Expanded(
                        child: Container(
                          color: index % 2 == 0
                              ? Colors.transparent
                              : AppTheme.borderTeal,
                          height: 1,
                        ),
                      ),
                    ),
                  ),

                  // Assigned Chauffeur Box
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.midnightTeal,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.oceanTeal.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: AppTheme.surfaceElevated,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.person,
                                  color: AppTheme.oceanTeal, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        booking.driverName,
                                        style: const TextStyle(
                                          color: AppTheme.textCream,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.verified,
                                          color: AppTheme.oceanTeal, size: 14),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${booking.vehicleName} • ${booking.plateNumber}',
                                    style: const TextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Row(
                                    children: [
                                      Text(
                                        '4.98 ★',
                                        style: TextStyle(
                                          color: AppTheme.sunsetGold,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        '• POLICE VERIFIED CHAUFFEUR',
                                        style: TextStyle(
                                          color: AppTheme.oceanTeal,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Action Buttons: WhatsApp & Call
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                key: const Key('pass_whatsapp_driver_btn'),
                                icon: const Icon(Icons.chat,
                                    size: 16, color: Colors.black),
                                label: const Text(
                                  'WhatsApp Driver',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.oceanTeal,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Opening WhatsApp with ${booking.driverName}...'),
                                      backgroundColor: AppTheme.oceanTeal,
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            OutlinedButton.icon(
                              key: const Key('pass_call_driver_btn'),
                              icon: const Icon(Icons.phone,
                                  size: 16, color: AppTheme.textCream),
                              label: const Text(
                                'Call',
                                style: TextStyle(
                                  color: AppTheme.textCream,
                                  fontSize: 12,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: AppTheme.borderTeal),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Calling ${booking.driverName} at ${booking.driverPhone}...'),
                                    backgroundColor: AppTheme.oceanTeal,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

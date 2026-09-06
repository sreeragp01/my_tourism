import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class MyTripsScreen extends StatelessWidget {
  const MyTripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const bookingRef = 'KL2609051234';

    return Scaffold(
      backgroundColor: const Color(0xFF0D1F17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF142B20),
        elevation: 0,
        title: const Text(
          'My Trips & Boarding Pass',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFF7F3E8)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Digital Boarding Pass Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF144032), Color(0xFF0F281E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.4)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'CONFIRMED • GREEN SCORE 88%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                    const Text(
                      bookingRef,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD4AF37),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  '6 Days Romantic Kerala Nature Escape',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Oct 15 - Oct 21, 2026 • 2 Travelers',
                  style: TextStyle(fontSize: 12, color: Color(0xFFC5D8CD)),
                ),
                const Divider(color: Colors.white12, height: 28),
                Row(
                  children: [
                    // QR Code
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: QrImageView(
                        data: 'https://keralink.org/pass/$bookingRef',
                        version: QrVersions.auto,
                        size: 90,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Digital Boarding Pass',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Scan at Brunton Boatyard, Lockhart Tea Estate, and Alleppey Houseboat check-in.',
                            style: TextStyle(fontSize: 11, color: Color(0xFFC5D8CD)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Chauffeur & Transit Details
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF142B20),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assigned Chauffeur & Vehicle',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF7F3E8),
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Color(0xFF10B981),
                      child: Icon(Icons.person, color: Color(0xFF0D1F17)),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rajesh Kumar',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Toyota Innova Crysta (KL-07-CC-4821)',
                            style: TextStyle(fontSize: 11, color: Color(0xFFC5D8CD)),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.phone_in_talk, color: Color(0xFF10B981), size: 20),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

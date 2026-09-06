import 'package:flutter/material.dart';

class SafetyHubScreen extends StatelessWidget {
  const SafetyHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final helplines = [
      {
        'title': 'Kerala Police & Emergency Rescue',
        'number': '112',
        'type': 'Immediate Dispatch (Toll-Free)',
        'color': const Color(0xFFE11D48),
        'icon': Icons.emergency,
      },
      {
        'title': 'Kerala Tourist Police Helpline',
        'number': '1800-425-4747',
        'type': 'Tourism Safety & Assistance',
        'color': const Color(0xFF10B981),
        'icon': Icons.shield_outlined,
      },
      {
        'title': 'Women Helplines (Pink Police)',
        'number': '1515',
        'type': 'Dedicated 24x7 Patrol',
        'color': const Color(0xFFF59E0B),
        'icon': Icons.support_agent,
      },
      {
        'title': 'Forest & Wildlife Emergency',
        'number': '1926',
        'type': 'Highland Ghats & Trekking',
        'color': const Color(0xFF059669),
        'icon': Icons.forest_outlined,
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0D1F17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF142B20),
        elevation: 0,
        title: const Text(
          'Safety & Emergency Hub',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFF7F3E8)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Emergency SOS Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF881337), Color(0xFF4C0519)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE11D48).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                        SizedBox(width: 8),
                        Text(
                          '24x7 STATEWIDE SOS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'TOLL FREE',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white70),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '112',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Immediate unified dispatch for Police, Medical & Fire services across all 14 Kerala districts.',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Verified Helplines & Authorities',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFF7F3E8),
            ),
          ),
          const SizedBox(height: 12),

          ...helplines.map((h) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF142B20),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: (h['color'] as Color).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(h['icon'] as IconData, color: h['color'] as Color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          h['title'] as String,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          h['type'] as String,
                          style: const TextStyle(fontSize: 11, color: Color(0xFFC5D8CD)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1F17),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: (h['color'] as Color).withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      h['number'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: h['color'] as Color,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

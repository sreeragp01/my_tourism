import 'package:flutter/material.dart';

class HomeDiscoverScreen extends StatelessWidget {
  final VoidCallback onOpenPlanner;
  final VoidCallback onOpenCompanion;

  const HomeDiscoverScreen({
    super.key,
    required this.onOpenPlanner,
    required this.onOpenCompanion,
  });

  @override
  Widget build(BuildContext context) {
    final categories = [
      {'label': 'Nature', 'icon': '🌿'},
      {'label': 'Beaches', 'icon': '🌴'},
      {'label': 'Hills', 'icon': '⛰️'},
      {'label': 'Backwaters', 'icon': '🛶'},
      {'label': 'Culture', 'icon': '🪔'},
      {'label': 'Food', 'icon': '🍛'},
    ];

    final destinations = [
      {
        'name': 'Munnar',
        'district': 'Idukki',
        'tagline': 'Misty Tea Hills & Valleys',
        'image': 'https://images.unsplash.com/photo-1593693397690-362cb9666fc2?auto=format&fit=crop&w=800&q=80',
        'tag': 'Hills',
      },
      {
        'name': 'Alleppey',
        'district': 'Alappuzha',
        'tagline': 'Serene Backwaters & Houseboats',
        'image': 'https://images.unsplash.com/photo-1602216056096-3b40cc0c9944?auto=format&fit=crop&w=800&q=80',
        'tag': 'Backwaters',
      },
      {
        'name': 'Fort Kochi',
        'district': 'Ernakulam',
        'tagline': 'Historic Spice Port & Biennale',
        'image': 'https://images.unsplash.com/photo-1582510003544-4d00b7f74220?auto=format&fit=crop&w=800&q=80',
        'tag': 'Culture',
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0D1F17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF142B20),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Good morning, Sreerag 🌴',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF7F3E8),
              ),
            ),
            Text(
              'Explore God\'s Own Country',
              style: TextStyle(
                fontSize: 12,
                color: const Color(0xFFC5D8CD).withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.forum_outlined, color: Color(0xFF10B981)),
            tooltip: 'Live Companion',
            onPressed: onOpenCompanion,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI Planner Banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF144032), Color(0xFF0A1D19)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'AI TRAVEL ARCHITECT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD4AF37),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Plan your perfect\nKerala journey',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Monsoon-adaptive routes, authentic village homestays, and green scores.',
                    style: TextStyle(fontSize: 12, color: Color(0xFFC5D8CD)),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: onOpenPlanner,
                    icon: const Icon(Icons.auto_awesome, size: 16),
                    label: const Text('Craft Itinerary'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: const Color(0xFF144032),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Categories
            const Text(
              'Explore by Interest',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF7F3E8),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF142B20),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Text(cat['icon']!, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(
                          cat['label']!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFF7F3E8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 28),

            // Destinations List
            const Text(
              'Featured Destinations',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF7F3E8),
              ),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: destinations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final d = destinations[index];
                return Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: const Color(0xFF142B20),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          Image.network(
                            d['image']!,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 150,
                              color: const Color(0xFF1C3A2D),
                              child: const Icon(Icons.landscape, size: 40, color: Colors.white30),
                            ),
                          ),
                          Positioned(
                            top: 10,
                            left: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF144032).withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                d['tag']!,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFD4AF37),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d['name']!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  d['tagline']!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFC5D8CD),
                                  ),
                                ),
                              ],
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFD4AF37)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

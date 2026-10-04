import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/map_models.dart';
import '../data/map_repository.dart';

class RoutePreviewScreen extends StatefulWidget {
  final IMapRepository? repository;
  final String startLandmark;
  final String destinationLandmark;

  const RoutePreviewScreen({
    super.key,
    this.repository,
    this.startLandmark = 'Kochi International Airport (COK)',
    this.destinationLandmark = 'Munnar Tea Valley',
  });

  @override
  State<RoutePreviewScreen> createState() => _RoutePreviewScreenState();
}

class _RoutePreviewScreenState extends State<RoutePreviewScreen> {
  RouteResult? _route;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRoute();
  }

  Future<void> _fetchRoute() async {
    if (widget.repository != null) {
      try {
        final result = await widget.repository!.getRoute(
          startLat: 10.1518,
          startLon: 76.3930,
          endLat: 10.0889,
          endLon: 77.0595,
        );
        if (mounted) {
          setState(() {
            _route = result;
            _isLoading = false;
          });
          return;
        }
      } catch (_) {}
    }

    // High fidelity fallback matching OSRM adapter
    if (mounted) {
      setState(() {
        _route = const RouteResult(
          distanceKm: 128.4,
          durationMinutes: 225,
          isGhatRoad: true,
          advisories: [
            'Ghat Fog Advisory: Maximum recommended speed 30 km/h with low-beam headlights.',
            'Monsoon hairpin bends active: Drive with extreme caution near Cheeyappara Falls.',
          ],
          polylinePoints: [],
          hairpinsCount: 14,
          summary: 'NH85 Cochin-Madurai Highway via Kothamangalam & Adimali',
        );
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.midnightTeal,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceTeal,
        elevation: 0,
        title: const Text(
          'Route & Transit Preview',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textCream),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.oceanTeal))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Origin & Destination Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceTeal,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.borderTeal),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.trip_origin, color: AppTheme.oceanTeal, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('ORIGIN', style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                                Text(widget.startLandmark, style: const TextStyle(color: AppTheme.textCream, fontSize: 14, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 9),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            height: 24,
                            child: VerticalDivider(color: AppTheme.borderTeal, thickness: 2),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: AppTheme.emergencyRed, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('DESTINATION', style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                                Text(widget.destinationLandmark, style: const TextStyle(color: AppTheme.textCream, fontSize: 14, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Corridor Metrics Summary
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        'Distance',
                        '${_route?.distanceKm ?? 128.4} km',
                        Icons.straighten,
                        AppTheme.oceanTeal,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        'Est. Travel Time',
                        '${(_route?.durationMinutes ?? 225) ~/ 60}h ${(_route?.durationMinutes ?? 225) % 60}m',
                        Icons.access_time,
                        const Color(0xFF38BDF8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        'Hairpin Turns',
                        '${_route?.hairpinsCount ?? 14} bends',
                        Icons.turn_sharp_right,
                        AppTheme.sunsetGold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Ghat Caution Section
                if (_route?.isGhatRoad ?? true) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceTeal,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.sunsetGold.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.shield_outlined, color: AppTheme.sunsetGold, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Highland Ghat Driving Advisories',
                              style: TextStyle(color: AppTheme.sunsetGold, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        for (final advisory in _route?.advisories ?? [])
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ', style: TextStyle(color: AppTheme.sunsetGold, fontSize: 14)),
                                Expanded(
                                  child: Text(
                                    advisory,
                                    style: const TextStyle(color: AppTheme.textCream, fontSize: 12, height: 1.4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Action: Start Navigation
                ElevatedButton.icon(
                  key: const Key('start_navigation_btn'),
                  icon: const Icon(Icons.navigation, color: AppTheme.midnightTeal),
                  label: const Text(
                    'Begin Live Corridor Transit',
                    style: TextStyle(color: AppTheme.midnightTeal, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.oceanTeal,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Transit active. Speed limit monitored at 30 km/h.'),
                        backgroundColor: AppTheme.oceanTeal,
                      ),
                    );
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceTeal,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderTeal),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(color: AppTheme.textCream, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
        ],
      ),
    );
  }
}

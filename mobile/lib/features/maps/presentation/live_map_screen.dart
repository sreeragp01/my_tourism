import 'package:flutter/material.dart';
import '../models/map_models.dart';
import '../data/map_repository.dart';
import 'route_preview_screen.dart';
import 'nearby_experiences_screen.dart';

class LiveMapScreen extends StatefulWidget {
  final IMapRepository? repository;
  final double initialLat;
  final double initialLon;
  final String destinationName;

  const LiveMapScreen({
    super.key,
    this.repository,
    this.initialLat = 10.0889,
    this.initialLon = 77.0595,
    this.destinationName = 'Munnar Tea Valley',
  });

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  late double _currentLat;
  late double _currentLon;
  bool _isLoading = false;
  String _currentLandmark = 'Lockhart Tea Valley, Munnar';
  RouteResult? _routeResult;

  @override
  void initState() {
    super.initState();
    _currentLat = widget.initialLat;
    _currentLon = widget.initialLon;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (widget.repository == null) return;
    setState(() => _isLoading = true);
    try {
      final landmark = await widget.repository!.reverseGeocode(lat: _currentLat, lon: _currentLon);
      final route = await widget.repository!.getRoute(
        startLat: 9.9312, // Kochi
        startLon: 76.2673,
        endLat: _currentLat,
        endLon: _currentLon,
      );
      if (mounted) {
        setState(() {
          _currentLandmark = landmark;
          _routeResult = route;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1F17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF142B20),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Live Corridor Map',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFF7F3E8)),
            ),
            Text(
              _currentLandmark,
              style: const TextStyle(fontSize: 12, color: Color(0xFF10B981)),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            key: const Key('refresh_map_btn'),
            icon: const Icon(Icons.my_location, color: Color(0xFF10B981)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('GPS Centered: Lockhart Tea Valley (Accuracy ±8m)'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Custom Interactive Kerala Corridor Canvas
          Positioned.fill(
            child: CustomPaint(
              painter: _KeralaCorridorMapPainter(
                travelerLat: _currentLat,
                travelerLon: _currentLon,
              ),
            ),
          ),

          // Top Ghat Advisory Banner
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937).withOpacity(0.92),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF59E0B), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 24),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Munnar Ghat Road Caution Active',
                          style: TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Dense mountain mist and 14 hairpin turns. Recommended speed: 30 km/h with low beams.',
                          style: TextStyle(color: Color(0xFFD1D5DB), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Quick Navigation & Route Card
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Quick Action Bar
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        key: const Key('route_preview_btn'),
                        icon: const Icon(Icons.alt_route, size: 18, color: Color(0xFF0D1F17)),
                        label: const Text('Route Preview', style: TextStyle(color: Color(0xFF0D1F17), fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RoutePreviewScreen(
                                repository: widget.repository,
                                startLandmark: 'Kochi International Airport',
                                destinationLandmark: widget.destinationName,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('nearby_experiences_btn'),
                        icon: const Icon(Icons.explore_outlined, size: 18, color: Color(0xFFF7F3E8)),
                        label: const Text('Nearby Spots', style: TextStyle(color: Color(0xFFF7F3E8), fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF2D5A43)),
                          backgroundColor: const Color(0xFF142B20).withOpacity(0.9),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NearbyExperiencesScreen(
                                repository: widget.repository,
                                currentLat: _currentLat,
                                currentLon: _currentLon,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // GPS Telemetry Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF142B20).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF2D5A43)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'GPS: ${_currentLat.toStringAsFixed(4)}°N, ${_currentLon.toStringAsFixed(4)}°E',
                            style: const TextStyle(color: Color(0xFFF7F3E8), fontSize: 12, fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                      const Text(
                        'Elevation: 1,532m',
                        style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KeralaCorridorMapPainter extends CustomPainter {
  final double travelerLat;
  final double travelerLon;

  _KeralaCorridorMapPainter({
    required this.travelerLat,
    required this.travelerLon,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF091510);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Grid lines representing geographical grid
    final gridPaint = Paint()
      ..color = const Color(0xFF142B20).withOpacity(0.5)
      ..strokeWidth = 1.0;

    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Corridor Route Path (Kochi -> Munnar -> Thekkady -> Alappuzha)
    final path = Path();
    final p1 = Offset(size.width * 0.25, size.height * 0.35); // Kochi
    final p2 = Offset(size.width * 0.70, size.height * 0.28); // Munnar
    final p3 = Offset(size.width * 0.75, size.height * 0.58); // Thekkady
    final p4 = Offset(size.width * 0.30, size.height * 0.75); // Alappuzha

    path.moveTo(p1.dx, p1.dy);
    path.cubicTo(
      size.width * 0.45, size.height * 0.20, // Mountain ascent
      size.width * 0.60, size.height * 0.22,
      p2.dx, p2.dy,
    );
    path.cubicTo(
      size.width * 0.85, size.height * 0.40, // Highland pass
      size.width * 0.80, size.height * 0.48,
      p3.dx, p3.dy,
    );
    path.cubicTo(
      size.width * 0.60, size.height * 0.70, // Backwater descent
      size.width * 0.45, size.height * 0.72,
      p4.dx, p4.dy,
    );

    // Draw route glow
    final glowPaint = Paint()
      ..color = const Color(0xFF10B981).withOpacity(0.25)
      ..strokeWidth = 8.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, glowPaint);

    // Draw main route line
    final routePaint = Paint()
      ..color = const Color(0xFF10B981)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, routePaint);

    // Waypoint dots
    _drawWaypoint(canvas, p1, 'Kochi Coast', isCurrent: false);
    _drawWaypoint(canvas, p2, 'Munnar Valley', isCurrent: true);
    _drawWaypoint(canvas, p3, 'Thekkady Reserve', isCurrent: false);
    _drawWaypoint(canvas, p4, 'Alappuzha Lake', isCurrent: false);
  }

  void _drawWaypoint(Canvas canvas, Offset pos, String label, {required bool isCurrent}) {
    if (isCurrent) {
      // Pulsing traveler radar ring
      final radarPaint = Paint()
        ..color = const Color(0xFF10B981).withOpacity(0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, 16.0, radarPaint);

      final dotPaint = Paint()
        ..color = const Color(0xFF10B981)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, 7.0, dotPaint);

      final whiteDot = Paint()..color = Colors.white;
      canvas.drawCircle(pos, 3.0, whiteDot);
    } else {
      final dotPaint = Paint()
        ..color = const Color(0xFF9CA3AF)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, 5.0, dotPaint);
    }

    final textSpan = TextSpan(
      text: label,
      style: TextStyle(
        color: isCurrent ? const Color(0xFF10B981) : const Color(0xFFD1D5DB),
        fontSize: 11,
        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(pos.dx - (textPainter.width / 2), pos.dy + 12));
  }

  @override
  bool shouldRepaint(covariant _KeralaCorridorMapPainter oldDelegate) {
    return oldDelegate.travelerLat != travelerLat || oldDelegate.travelerLon != travelerLon;
  }
}

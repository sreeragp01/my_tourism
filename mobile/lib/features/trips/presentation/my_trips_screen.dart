import 'package:flutter/material.dart';
import 'package:keralink_mobile/core/config/app_config.dart';
import 'package:keralink_mobile/core/network/api_client.dart';
import 'package:keralink_mobile/core/storage/secure_token_storage.dart';
import '../data/trips_repository.dart';
import '../models/trip_models.dart';
import 'trip_detail_screen.dart';
import '../../maps/presentation/live_map_screen.dart';

class MyTripsScreen extends StatefulWidget {
  final ITripsRepository? repository;

  const MyTripsScreen({super.key, this.repository});

  @override
  State<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTripsScreen> {
  late final ITripsRepository _repository;
  List<TripSummary> _trips = [];
  bool _loading = true;
  String? _errorMessage;

  static const Color bgDark = Color(0xFF0D1F17);
  static const Color surfaceDark = Color(0xFF142B20);
  static const Color cardDark = Color(0xFF1B382B);
  static const Color emerald = Color(0xFF10B981);
  static const Color gold = Color(0xFFD4AF37);
  static const Color textPrimary = Color(0xFFF7F3E8);
  static const Color textMuted = Color(0xFFC5D8CD);

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ??
        TripsRepository(
          apiClient: ApiClient(
            config: AppConfig.fromEnvironment(),
            storage: SecureTokenStorage(),
          ),
        );
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final list = await _repository.getUserTrips();
      if (!mounted) return;
      setState(() {
        _trips = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: surfaceDark,
        elevation: 0,
        title: const Text(
          'My Trips & Boarding Passes',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined, color: emerald),
            tooltip: 'Live Corridor Map',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LiveMapScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: emerald),
            tooltip: 'Refresh Trips',
            onPressed: _loadTrips,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: emerald))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_off_outlined, color: Colors.orangeAccent, size: 44),
                        const SizedBox(height: 12),
                        const Text(
                          'No Synchronized Bookings Found',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Sign in or explore offline itineraries and the live corridor map.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: textMuted.withValues(alpha: 0.8)),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: surfaceDark,
                                foregroundColor: textPrimary,
                              ),
                              onPressed: _loadTrips,
                              child: const Text('Retry'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: emerald,
                                foregroundColor: bgDark,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const LiveMapScreen()),
                                );
                              },
                              icon: const Icon(Icons.map, size: 16),
                              label: const Text('View Map'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              : _trips.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      color: emerald,
                      backgroundColor: surfaceDark,
                      onRefresh: _loadTrips,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _trips.length,
                        itemBuilder: (ctx, idx) => _buildTripCard(_trips[idx]),
                      ),
                    ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: emerald.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.luggage_outlined, size: 48, color: emerald),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Confirmed Trips Yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Use our AI Travel Architect to customize your dream Kerala journey, or view live corridors and scenic routes on the map.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: textMuted),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LiveMapScreen()),
                );
              },
              icon: const Icon(Icons.map_outlined, size: 18),
              label: const Text('Explore Interactive Map'),
              style: ElevatedButton.styleFrom(
                backgroundColor: emerald,
                foregroundColor: bgDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripCard(TripSummary trip) {
    return Container(
      key: Key('trip_card_${trip.bookingReference}'),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: surfaceDark,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: gold.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => TripDetailScreen(
                bookingReference: trip.bookingReference,
                repository: _repository,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: emerald.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: emerald),
                    ),
                    child: Text(
                      '${trip.status} • ECO ${trip.greenTripScore}%',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: emerald,
                      ),
                    ),
                  ),
                  Text(
                    trip.bookingReference,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: gold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                trip.tripTitle,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 12, color: textMuted),
                  const SizedBox(width: 4),
                  Text(
                    '${trip.startDate} - ${trip.endDate}',
                    style: const TextStyle(fontSize: 12, color: textMuted),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.people_outline, size: 13, color: textMuted),
                  const SizedBox(width: 4),
                  Text(
                    '${trip.travelersCount} Travelers',
                    style: const TextStyle(fontSize: 12, color: textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.route_outlined, size: 13, color: gold),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      trip.corridor,
                      style: const TextStyle(fontSize: 11, color: textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.white12, height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Amount', style: TextStyle(fontSize: 10, color: textMuted)),
                      Text(
                        '₹${trip.totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: gold,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.qr_code, size: 16),
                    label: const Text('View Pass', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: emerald,
                      foregroundColor: bgDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => TripDetailScreen(
                            bookingReference: trip.bookingReference,
                            repository: _repository,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

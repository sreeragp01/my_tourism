import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../data/trips_repository.dart';
import '../models/trip_models.dart';
import '../../companion/presentation/live_companion_screen.dart';
import '../../maps/presentation/live_map_screen.dart';
import '../../safety/presentation/safety_hub_screen.dart';

class TripDetailScreen extends StatefulWidget {
  final String bookingReference;
  final ITripsRepository repository;
  final TripDetail? initialDetail;

  const TripDetailScreen({
    super.key,
    required this.bookingReference,
    required this.repository,
    this.initialDetail,
  });

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  TripDetail? _detail;
  bool _loading = true;
  String? _error;

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
    if (widget.initialDetail != null) {
      _detail = widget.initialDetail;
      _loading = false;
    } else {
      _loadDetail();
    }
  }

  Future<void> _loadDetail() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await widget.repository.getTripDetail(widget.bookingReference);
      if (!mounted) return;
      setState(() {
        _detail = res;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
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
        title: Text(
          _detail != null ? 'Trip Pass #${_detail!.bookingReference}' : 'Trip Details',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
        ),
        actions: _detail != null
            ? [
                IconButton(
                  key: const Key('live_companion_nav_btn'),
                  icon: const Icon(Icons.support_agent, color: emerald),
                  tooltip: 'Live Companion',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LiveCompanionScreen(
                          bookingReference: _detail!.bookingReference,
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  key: const Key('corridor_map_nav_btn'),
                  icon: const Icon(Icons.map_outlined, color: emerald),
                  tooltip: 'Corridor Map',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LiveMapScreen(),
                      ),
                    );
                  },
                ),
                IconButton(
                  key: const Key('safety_hub_nav_btn'),
                  icon: const Icon(Icons.shield_outlined, color: Color(0xFFE11D48)),
                  tooltip: 'Safety Hub',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SafetyHubScreen(
                          bookingReference: _detail!.bookingReference,
                        ),
                      ),
                    );
                  },
                ),
              ]
            : null,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: emerald))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_error', style: const TextStyle(color: Colors.redAccent)),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _loadDetail, child: const Text('Retry')),
                    ],
                  ),
                )
              : _buildContent(_detail!),
    );
  }

  Widget _buildContent(TripDetail detail) {
    final qrPayload = detail.digitalPass.qrData.isNotEmpty
        ? detail.digitalPass.qrData
        : 'https://keralink.org/pass/${detail.bookingReference}';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Digital Boarding Pass Card
        Container(
          key: const Key('trip_pass_card'),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF144032), Color(0xFF0F281E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: gold.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 14,
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
                      color: emerald.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: emerald),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified, color: emerald, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          '${detail.status} • ECO ${detail.greenTripScore}%',
                          key: const Key('trip_status_badge'),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: emerald,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    detail.bookingReference,
                    key: const Key('trip_reference_text'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: gold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                detail.tripTitle,
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                '${detail.startDate} to ${detail.endDate} • ${detail.travelersCount} Travelers',
                style: const TextStyle(fontSize: 12, color: textMuted),
              ),
              const Divider(color: Colors.white12, height: 28),

              // QR Code Section
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: QrImageView(
                      key: const Key('trip_qr_image'),
                      data: qrPayload,
                      version: QrVersions.auto,
                      size: 96,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Digital Boarding Pass',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Present at resort check-in, houseboat boarding, and curated experiences.',
                          style: TextStyle(fontSize: 11, color: textMuted),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            detail.digitalPass.passToken,
                            key: const Key('trip_pass_token'),
                            style: const TextStyle(fontSize: 9, color: gold, fontFamily: 'monospace'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Assigned Chauffeur & Vehicle Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surfaceDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Assigned Chauffeur & Corridor Vehicle',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: emerald,
                    child: Icon(Icons.directions_car, color: bgDark),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          detail.chauffeur.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          detail.chauffeur.vehicle,
                          style: const TextStyle(fontSize: 11, color: textMuted),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.phone_in_talk, color: emerald, size: 20),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Confirmed Vouchers List
        const Text(
          'Confirmed Components & Vouchers',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary),
        ),
        const SizedBox(height: 10),

        ...detail.items.map((item) {
          final isRoom = item.itemType == 'ROOM';
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: surfaceDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (isRoom ? Colors.purpleAccent : emerald).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isRoom ? Icons.hotel : Icons.local_activity,
                    color: isRoom ? Colors.purpleAccent : emerald,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Date: ${item.date} • Qty: ${item.quantity}',
                        style: const TextStyle(fontSize: 11, color: textMuted),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${item.totalPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: gold,
                      ),
                    ),
                    const Text('Confirmed ✓', style: TextStyle(fontSize: 10, color: emerald)),
                  ],
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 16),

        // Financial Summary Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surfaceDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            children: [
              _buildPriceRow('Subtotal', '₹${detail.subtotal.toStringAsFixed(0)}'),
              const SizedBox(height: 6),
              _buildPriceRow('GST (5%)', '₹${detail.tax.toStringAsFixed(0)}'),
              const SizedBox(height: 6),
              _buildPriceRow('Platform & Eco Fee (2%)', '₹${detail.platformFee.toStringAsFixed(0)}'),
              const Divider(color: Colors.white12, height: 16),
              _buildPriceRow(
                'Total Paid',
                '₹${detail.totalAmount.toStringAsFixed(0)}',
                isBold: true,
                color: gold,
              ),
            ],
          ),
        ),

        // Live Trip Companion Action Bar
        Container(
          key: const Key('live_experience_action_bar'),
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: surfaceDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: emerald.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.assistant_navigation, color: emerald, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Live Trip Experience Engine',
                    style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.support_agent, size: 16, color: Color(0xFF0D1F17)),
                      label: const Text('Companion', style: TextStyle(color: Color(0xFF0D1F17), fontSize: 11, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: emerald,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LiveCompanionScreen(
                              bookingReference: detail.bookingReference,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.map_outlined, size: 16, color: textPrimary),
                      label: const Text('Corridor Map', style: TextStyle(color: textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: emerald),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LiveMapScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.shield_outlined, size: 16, color: Color(0xFFE11D48)),
                      label: const Text('Safety Hub', style: TextStyle(color: Color(0xFFE11D48), fontSize: 11, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE11D48)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SafetyHubScreen(
                              bookingReference: detail.bookingReference,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 30),
      ],
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

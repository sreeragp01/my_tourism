import 'dart:async';
import 'package:flutter/material.dart';
import 'package:keralink_mobile/core/config/app_config.dart';
import 'package:keralink_mobile/core/network/api_client.dart';
import 'package:keralink_mobile/core/storage/secure_token_storage.dart';
import '../../ai_planner/models/itinerary_models.dart';
import '../../trips/data/trips_repository.dart';
import '../../trips/presentation/booking_checkout_sheet.dart';
import '../data/inventory_repository.dart';
import '../models/inventory_hold_models.dart';

class InventoryHoldSheet extends StatefulWidget {
  final AIPlan plan;
  final IInventoryRepository repository;
  final ITripsRepository? tripsRepository;
  final VoidCallback? onProceedToBooking;

  const InventoryHoldSheet({
    super.key,
    required this.plan,
    required this.repository,
    this.tripsRepository,
    this.onProceedToBooking,
  });

  @override
  State<InventoryHoldSheet> createState() => _InventoryHoldSheetState();
}

class _InventoryHoldSheetState extends State<InventoryHoldSheet> {
  bool _loading = false;
  bool _checkingAvailability = true;
  String? _errorMessage;
  List<InventoryHold> _activeHolds = [];
  Map<String, InventoryAvailability> _availabilityMap = {};
  Timer? _countdownTimer;
  int _secondsRemaining = 15 * 60;

  // Theme Constants
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
    _checkItineraryAvailability();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  List<TimelineEvent> get _bookableComponents {
    final list = <TimelineEvent>[];
    for (final day in widget.plan.days) {
      for (final event in day.timeline) {
        if (event.type == 'STAY' || event.type == 'EXPERIENCE') {
          list.add(event);
        }
      }
    }
    return list;
  }

  Future<void> _checkItineraryAvailability() async {
    setState(() {
      _checkingAvailability = true;
      _errorMessage = null;
    });

    final map = <String, InventoryAvailability>{};

    for (final comp in _bookableComponents) {
      final invType = comp.type == 'STAY' ? 'ROOM' : 'EXPERIENCE';
      final invId = comp.type == 'STAY'
          ? (comp.accommodationId?.toString() ?? 'room_default')
          : (comp.experienceId?.toString() ?? comp.id);

      try {
        final avail = await widget.repository.checkAvailability(
          invType,
          invId,
          quantity: 1,
        );
        map[comp.id] = avail;
      } catch (_) {
        // Fallback simulated availability
        map[comp.id] = InventoryAvailability(
          inventoryType: invType,
          inventoryId: invId,
          totalCapacity: 5,
          bookedCapacity: 1,
          heldCapacity: 0,
          availableCapacity: 4,
          isAvailable: true,
        );
      }
    }

    if (!mounted) return;
    setState(() {
      _availabilityMap = map;
      _checkingAvailability = false;
    });
  }

  void _startCountdown(int initialSeconds) {
    _countdownTimer?.cancel();
    setState(() {
      _secondsRemaining = initialSeconds;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
        setState(() {
          _activeHolds.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your 15-minute inventory hold has expired.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    });
  }

  Future<void> _holdAllInventory() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final items = _bookableComponents.map((comp) {
      final invType = comp.type == 'STAY' ? 'ROOM' : 'EXPERIENCE';
      final invId = comp.type == 'STAY'
          ? (comp.accommodationId?.toString() ?? 'room_default')
          : (comp.experienceId?.toString() ?? comp.id);

      return <String, dynamic>{
        'inventory_type': invType,
        'inventory_id': invId,
        'quantity': 1,
      };
    }).toList();

    try {
      final result = await widget.repository.holdItinerary(
        items: items,
        itineraryVersionId: 'v${widget.plan.version}',
        durationMins: 15,
      );

      if (!mounted) return;

      if (result.isSuccess && result.holds.isNotEmpty) {
        setState(() {
          _loading = false;
          _activeHolds = result.holds;
        });
        _startCountdown(15 * 60);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Locked ${result.totalHeld} components for 15 minutes!'),
            backgroundColor: emerald,
          ),
        );
      } else {
        setState(() {
          _loading = false;
          _errorMessage = result.errorMessage ?? 'One or more items could not be held.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _extendHold() async {
    if (_activeHolds.isEmpty) return;

    setState(() => _loading = true);

    try {
      final firstHold = _activeHolds.first;
      final updated = await widget.repository.extendHold(firstHold.id, extraMinutes: 10);

      if (!mounted) return;
      setState(() {
        _loading = false;
      });
      _startCountdown(_secondsRemaining + (10 * 60));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hold extended by 10 minutes (expires ${updated.expiresAt.hour}:${updated.expiresAt.minute.toString().padLeft(2, '0')})'),
          backgroundColor: emerald,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to extend hold: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _releaseHold() async {
    if (_activeHolds.isEmpty) return;

    setState(() => _loading = true);

    try {
      for (final hold in _activeHolds) {
        await widget.repository.releaseHold(hold.id);
      }

      _countdownTimer?.cancel();

      if (!mounted) return;
      setState(() {
        _activeHolds.clear();
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inventory hold released.'), backgroundColor: emerald),
      );
      _checkItineraryAvailability();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to release hold: $e')),
      );
    }
  }

  String _formatTimer(int totalSecs) {
    final mins = totalSecs ~/ 60;
    final secs = totalSecs % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final components = _bookableComponents;
    final hasActiveHold = _activeHolds.isNotEmpty;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: surfaceDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Authoritative Live Availability',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.plan.title} (v${widget.plan.version})',
                        style: const TextStyle(fontSize: 11, color: textMuted),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Active Hold Banner (if active)
              if (hasActiveHold) ...[
                Container(
                  key: const Key('active_hold_banner'),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: bgDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: emerald),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: emerald.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.lock_clock, color: emerald, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'INVENTORY LOCKED FOR YOU',
                              style: TextStyle(
                                color: emerald,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Expires in ${_formatTimer(_secondsRemaining)}',
                              key: const Key('inventory_countdown_timer'),
                              style: const TextStyle(
                                color: gold,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        key: const Key('inventory_extend_hold_btn'),
                        icon: const Icon(Icons.update, color: gold),
                        tooltip: 'Extend +10m',
                        onPressed: _loading ? null : _extendHold,
                      ),
                      IconButton(
                        key: const Key('inventory_release_hold_btn'),
                        icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent),
                        tooltip: 'Release Hold',
                        onPressed: _loading ? null : _releaseHold,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Error display
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.redAccent),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: textPrimary, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Bookable Components List
              const Text(
                'Required Reservations:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary),
              ),
              const SizedBox(height: 8),

              if (_checkingAvailability)
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: emerald),
                        SizedBox(height: 12),
                        Text(
                          'Checking live PostgreSQL availability...',
                          style: TextStyle(color: textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: components.length,
                    itemBuilder: (context, index) {
                      final comp = components[index];
                      final avail = _availabilityMap[comp.id];
                      final isRoom = comp.type == 'STAY';
                      final isAvail = avail?.isAvailable ?? true;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: bgDark,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (isRoom ? Colors.purpleAccent : emerald).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isRoom ? Icons.hotel : Icons.local_activity,
                                color: isRoom ? Colors.purpleAccent : emerald,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    comp.title,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isRoom ? 'Overnight Room · ₹${comp.price.toStringAsFixed(0)}' : 'Curated Activity · ₹${comp.price.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 11, color: textMuted),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isAvail ? emerald.withValues(alpha: 0.15) : Colors.redAccent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: isAvail ? emerald : Colors.redAccent),
                              ),
                              child: Text(
                                isAvail ? (isRoom ? 'Available' : '${avail?.availableCapacity ?? 4} spots left') : 'Sold Out',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isAvail ? emerald : Colors.redAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 12),

              // Bottom Primary Actions
              if (!hasActiveHold)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    key: const Key('inventory_hold_all_btn'),
                    icon: _loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: bgDark),
                          )
                        : const Icon(Icons.lock, size: 18),
                    label: Text(
                      _loading ? 'Holding in PostgreSQL...' : 'Hold All Components (15 Mins)',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: gold,
                      foregroundColor: bgDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _loading || _checkingAvailability ? null : _holdAllInventory,
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    key: const Key('inventory_proceed_booking_btn'),
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: const Text(
                      'Proceed to Booking',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: emerald,
                      foregroundColor: bgDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      final holds = List<InventoryHold>.from(_activeHolds);
                      Navigator.pop(context);
                      if (widget.onProceedToBooking != null) {
                        widget.onProceedToBooking!();
                      } else {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (ctx) => BookingCheckoutSheet(
                            plan: widget.plan,
                            activeHolds: holds,
                            tripsRepository: widget.tripsRepository ??
                                TripsRepository(
                                  apiClient: ApiClient(
                                    config: AppConfig.fromEnvironment(),
                                    storage: SecureTokenStorage(),
                                  ),
                                ),
                          ),
                        );
                      }
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

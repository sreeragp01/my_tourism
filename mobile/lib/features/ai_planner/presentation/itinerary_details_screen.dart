import 'package:flutter/material.dart';
import '../data/ai_planner_repository.dart';
import '../models/itinerary_models.dart';

class ItineraryDetailsScreen extends StatefulWidget {
  final AIPlan initialPlan;
  final IAIPlannerRepository repository;

  const ItineraryDetailsScreen({
    super.key,
    required this.initialPlan,
    required this.repository,
  });

  @override
  State<ItineraryDetailsScreen> createState() => _ItineraryDetailsScreenState();
}

class _ItineraryDetailsScreenState extends State<ItineraryDetailsScreen> {
  late AIPlan _currentPlan;
  int _selectedDayIndex = 0;
  bool _isProcessingAction = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _currentPlan = widget.initialPlan;
  }

  Future<void> _applyRainSubstitution(int dayNumber, {String? outdoorItemId}) async {
    setState(() {
      _isProcessingAction = true;
      _statusMessage = 'Applying monsoon weather adaptation...';
    });

    try {
      final updatedPlan = await widget.repository.substituteRain(
        planId: _currentPlan.planId,
        dayNumber: dayNumber,
        outdoorItemId: outdoorItemId,
      );

      if (!mounted) return;
      setState(() {
        _currentPlan = updatedPlan;
        _isProcessingAction = false;
        _statusMessage = 'Day $dayNumber adapted for rain (created Version v${updatedPlan.version})';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Plan updated to v${updatedPlan.version}: Monsoon adaptation applied!'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessingAction = false;
        _statusMessage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to adapt plan: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _removeActivity(int dayNumber, String eventId, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF142B20),
        title: const Text('Remove Activity?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Do you want to remove "$title" from Day $dayNumber? A new plan version will be created.',
          style: const TextStyle(color: Color(0xFFC5D8CD)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isProcessingAction = true;
      _statusMessage = 'Recalculating itinerary without activity...';
    });

    try {
      final updatedPlan = await widget.repository.customizePlan(
        planId: _currentPlan.planId,
        action: 'REMOVE_ACTIVITY',
        dayNumber: dayNumber,
        timelineEventId: eventId,
        reason: 'Removed $title from Day $dayNumber',
      );

      if (!mounted) return;
      setState(() {
        _currentPlan = updatedPlan;
        _isProcessingAction = false;
        _statusMessage = 'Activity removed (Created Version v${updatedPlan.version})';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessingAction = false;
        _statusMessage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove activity: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showVersionsSheet() async {
    try {
      final versions = await widget.repository.getPlanVersions(_currentPlan.planId);
      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF142B20),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Itinerary Versions',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (versions.isEmpty)
                  const Text('Only version 1 is currently active.', style: TextStyle(color: Colors.white70))
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: versions.length,
                      itemBuilder: (context, index) {
                        final v = versions[index];
                        final isSelected = v.version == _currentPlan.version;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF10B981).withValues(alpha: 0.2) : const Color(0xFF0D1F17),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF10B981) : Colors.white10,
                            ),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isSelected ? const Color(0xFF10B981) : Colors.white12,
                              child: Text(
                                'v${v.version}',
                                style: TextStyle(
                                  color: isSelected ? const Color(0xFF0D1F17) : Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              v.changeReason,
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              '₹${v.totalPrice.toStringAsFixed(0)}',
                              style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 12),
                            ),
                            trailing: isSelected
                                ? const Chip(
                                    label: Text('Current', style: TextStyle(fontSize: 10, color: Colors.white)),
                                    backgroundColor: Color(0xFF10B981),
                                  )
                                : TextButton(
                                    onPressed: () async {
                                      Navigator.pop(ctx);
                                      final detail = await widget.repository.getPlanVersionDetail(
                                        _currentPlan.planId,
                                        v.version,
                                      );
                                      if (mounted) {
                                        setState(() {
                                          _currentPlan = detail;
                                        });
                                      }
                                    },
                                    child: const Text('View', style: TextStyle(color: Color(0xFF10B981))),
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not fetch versions: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeDays = _currentPlan.days;
    final currentDay = activeDays.isNotEmpty && _selectedDayIndex < activeDays.length
        ? activeDays[_selectedDayIndex]
        : (activeDays.isNotEmpty ? activeDays.first : null);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1F17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF142B20),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _currentPlan.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFF7F3E8)),
            ),
            Text(
              '${_currentPlan.durationDays} Days / ${_currentPlan.travelStyle}',
              style: const TextStyle(fontSize: 11, color: Color(0xFFC5D8CD)),
            ),
          ],
        ),
        actions: [
          IconButton(
            key: const Key('itinerary_versions_button'),
            icon: const Icon(Icons.history, color: Color(0xFFD4AF37)),
            tooltip: 'Version History',
            onPressed: _showVersionsSheet,
          ),
        ],
      ),
      body: _isProcessingAction
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF10B981)),
                  const SizedBox(height: 16),
                  Text(
                    _statusMessage ?? 'Processing...',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Version & Rain adaptation banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: const Color(0xFF142B20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF10B981)),
                                ),
                                child: Text(
                                  'Version v${_currentPlan.version}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (_currentPlan.changeReason != null)
                                Expanded(
                                  child: Text(
                                    _currentPlan.changeReason!,
                                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          key: const Key('itinerary_rain_substitute_btn'),
                          icon: const Icon(Icons.beach_access, size: 14, color: Color(0xFFD4AF37)),
                          label: const Text('Rain Mode', style: TextStyle(fontSize: 11, color: Color(0xFFD4AF37))),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFD4AF37)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          ),
                          onPressed: currentDay != null
                              ? () => _applyRainSubstitution(currentDay.dayNumber)
                              : null,
                        ),
                      ],
                    ),
                  ),

                  // Route Corridor Preview
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _currentPlan.corridorRoute.map((dest) {
                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF142B20),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.place, size: 12, color: Color(0xFF10B981)),
                                const SizedBox(width: 4),
                                Text(dest, style: const TextStyle(color: Colors.white, fontSize: 12)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  // Day Selector Tabs
                  if (activeDays.isNotEmpty)
                    SizedBox(
                      height: 48,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: activeDays.length,
                        itemBuilder: (context, index) {
                          final day = activeDays[index];
                          final isSelected = index == _selectedDayIndex;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedDayIndex = index),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF10B981) : const Color(0xFF142B20),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF10B981) : Colors.white12,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'Day ${day.dayNumber}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? const Color(0xFF0D1F17) : Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Day Content & Theme
                  if (currentDay != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF142B20),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.explore, color: Color(0xFFD4AF37), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentDay.destinationName,
                                    style: const TextStyle(
                                      color: Color(0xFFD4AF37),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    currentDay.themeTitle,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Timeline Events List
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: currentDay.timeline.map((event) {
                          return _buildTimelineEventCard(currentDay.dayNumber, event);
                        }).toList(),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Authoritative Pricing Breakdown (Django Authoritative Engine)
                  _buildPricingCard(_currentPlan.pricing),

                  const SizedBox(height: 24),

                  // Proceed to Booking CTA
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        key: const Key('itinerary_proceed_booking_btn'),
                        icon: const Icon(Icons.lock_clock, size: 20),
                        label: Text(
                          'Proceed to Reserve (₹${_currentPlan.pricing.total.toStringAsFixed(0)})',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF37),
                          foregroundColor: const Color(0xFF144032),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Locking inventory hold for ${_currentPlan.durationDays}-day itinerary. Moving to Phase 6...',
                              ),
                              backgroundColor: const Color(0xFF10B981),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildTimelineEventCard(int dayNumber, TimelineEvent event) {
    Color badgeColor;
    IconData icon;
    switch (event.type) {
      case 'EXPERIENCE':
        badgeColor = const Color(0xFF10B981);
        icon = Icons.local_activity;
        break;
      case 'MEAL':
        badgeColor = Colors.orangeAccent;
        icon = Icons.restaurant;
        break;
      case 'STAY':
        badgeColor = Colors.purpleAccent;
        icon = Icons.hotel;
        break;
      case 'TRANSFER':
        badgeColor = Colors.blueAccent;
        icon = Icons.directions_car;
        break;
      default:
        badgeColor = Colors.white54;
        icon = Icons.event;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF142B20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: badgeColor),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      event.type,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: badgeColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${event.startTime} - ${event.endTime}',
                    style: const TextStyle(fontSize: 11, color: Colors.white60),
                  ),
                ],
              ),
              if (event.type != 'STAY')
                IconButton(
                  icon: const Icon(Icons.close, size: 16, color: Colors.white38),
                  tooltip: 'Remove activity',
                  onPressed: () => _removeActivity(dayNumber, event.id, event.title),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            event.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    event.rainFriendly ? Icons.beach_access : Icons.wb_sunny,
                    size: 13,
                    color: event.rainFriendly ? const Color(0xFF10B981) : Colors.amber,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    event.rainFriendly ? 'Rain Friendly' : 'Outdoor',
                    style: TextStyle(
                      fontSize: 11,
                      color: event.rainFriendly ? const Color(0xFF10B981) : Colors.amber,
                    ),
                  ),
                ],
              ),
              if (event.price > 0)
                Text(
                  '₹${event.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD4AF37),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard(PricingBreakdown pricing) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF142B20),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Authoritative Pricing',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'DJANGO CALCULATED',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD4AF37),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPriceRow('Overnight Stays', pricing.staysSubtotal),
          _buildPriceRow('Experiential Activities', pricing.experiencesSubtotal),
          _buildPriceRow('Dedicated Chauffeur Transport', pricing.transportSubtotal),
          const Divider(color: Colors.white12, height: 16),
          _buildPriceRow('Subtotal', pricing.subtotal, isMuted: false),
          _buildPriceRow('GST (${pricing.gstRatePercent.toStringAsFixed(0)}%)', pricing.gstAmount),
          _buildPriceRow('Platform Fee (${pricing.platformFeePercent.toStringAsFixed(0)}%)', pricing.platformFee),
          if (pricing.discount > 0)
            _buildPriceRow('Special Discount', -pricing.discount, isDiscount: true),
          const Divider(color: Colors.white24, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Package Price',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(
                '₹${pricing.total.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD4AF37),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isMuted = true, bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isMuted ? const Color(0xFFC5D8CD) : Colors.white,
            ),
          ),
          Text(
            '${isDiscount ? '-' : ''}₹${amount.abs().toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: isMuted ? FontWeight.normal : FontWeight.bold,
              color: isDiscount ? const Color(0xFF10B981) : (isMuted ? const Color(0xFFC5D8CD) : Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

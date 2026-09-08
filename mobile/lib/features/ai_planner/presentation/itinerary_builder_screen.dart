import 'package:flutter/material.dart';
import 'package:keralink_mobile/core/config/app_config.dart';
import 'package:keralink_mobile/core/network/api_client.dart';
import 'package:keralink_mobile/core/storage/secure_token_storage.dart';
import '../../inventory/data/inventory_repository.dart';
import '../../inventory/presentation/inventory_hold_sheet.dart';
import '../data/ai_planner_repository.dart';
import '../models/itinerary_models.dart';

class ItineraryBuilderScreen extends StatefulWidget {
  final AIPlan initialPlan;
  final IAIPlannerRepository repository;
  final IInventoryRepository? inventoryRepository;

  const ItineraryBuilderScreen({
    super.key,
    required this.initialPlan,
    required this.repository,
    this.inventoryRepository,
  });

  @override
  State<ItineraryBuilderScreen> createState() => _ItineraryBuilderScreenState();
}

class _ItineraryBuilderScreenState extends State<ItineraryBuilderScreen> {
  late AIPlan _currentPlan;
  int _selectedDayIndex = 0;
  bool _isLoading = false;
  String? _statusMessage;
  ItineraryDiff? _lastDiff;

  // Theme Constants
  static const Color bgDark = Color(0xFF0D1F17);
  static const Color surfaceDark = Color(0xFF142B20);
  static const Color emerald = Color(0xFF10B981);
  static const Color gold = Color(0xFFD4AF37);
  static const Color textPrimary = Color(0xFFF7F3E8);
  static const Color textMuted = Color(0xFFC5D8CD);

  late final IInventoryRepository _inventoryRepository;

  @override
  void initState() {
    super.initState();
    _currentPlan = widget.initialPlan;
    _inventoryRepository = widget.inventoryRepository ??
        InventoryRepository(
          apiClient: ApiClient(
            config: AppConfig.fromEnvironment(),
            storage: SecureTokenStorage(),
          ),
        );
  }

  PlanDay? get _currentDay {
    if (_currentPlan.days.isEmpty) return null;
    if (_selectedDayIndex >= _currentPlan.days.length) {
      return _currentPlan.days.first;
    }
    return _currentPlan.days[_selectedDayIndex];
  }

  Future<void> _performBuilderOperation({
    required String statusText,
    required Future<AIPlan> Function() operation,
    String? successMessage,
  }) async {
    setState(() {
      _isLoading = true;
      _statusMessage = statusText;
    });

    try {
      final prevVersion = _currentPlan.version;
      final updated = await operation();

      // Attempt to load diff if version incremented
      ItineraryDiff? diff;
      if (updated.version > prevVersion) {
        try {
          diff = await widget.repository.getPlanDiff(
            updated.planId,
            fromVersion: prevVersion,
            toVersion: updated.version,
          );
        } catch (_) {}
      }

      if (!mounted) return;
      setState(() {
        _currentPlan = updated;
        _lastDiff = diff;
        _isLoading = false;
        _statusMessage = null;
      });

      if (successMessage != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$successMessage (v${updated.version})'),
            backgroundColor: emerald,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            action: diff != null
                ? SnackBarAction(
                    label: 'View Diff',
                    textColor: Colors.white,
                    onPressed: _showDiffModal,
                  )
                : null,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _statusMessage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Operation failed: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Operation: MOVE_EVENT (reorder within day or move across days)
  Future<void> _moveEvent(TimelineEvent event, int deltaOrder) async {
    final currentDay = _currentDay;
    if (currentDay == null) return;

    final targetOrder = (event.order + deltaOrder).clamp(1, currentDay.timeline.length);
    if (targetOrder == event.order) return;

    await _performBuilderOperation(
      statusText: 'Reordering event & validating route schedule...',
      operation: () => widget.repository.customizePlan(
        planId: _currentPlan.planId,
        operation: 'MOVE_EVENT',
        eventId: event.id,
        dayNumber: currentDay.dayNumber,
        targetOrder: targetOrder,
        reason: 'Moved ${event.title} to position $targetOrder',
      ),
      successMessage: 'Event reordered successfully',
    );
  }

  // Operation: REMOVE_EVENT
  Future<void> _removeEvent(TimelineEvent event) async {
    final currentDay = _currentDay;
    if (currentDay == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surfaceDark,
        title: const Text('Remove Event?', style: TextStyle(color: textPrimary)),
        content: Text(
          'Remove "${event.title}" from Day ${currentDay.dayNumber}?\nDeterministic validation will recalculate route & pricing.',
          style: const TextStyle(color: textMuted),
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

    await _performBuilderOperation(
      statusText: 'Removing event and updating day timeline...',
      operation: () => widget.repository.customizePlan(
        planId: _currentPlan.planId,
        operation: 'REMOVE_EVENT',
        eventId: event.id,
        dayNumber: currentDay.dayNumber,
        reason: 'Removed ${event.title} from Day ${currentDay.dayNumber}',
      ),
      successMessage: 'Event removed',
    );
  }

  // Operation: SWAP_EVENT
  Future<void> _swapEventWithAnother(TimelineEvent event) async {
    final currentDay = _currentDay;
    if (currentDay == null) return;

    final otherEvents = currentDay.timeline.where((e) => e.id != event.id).toList();
    if (otherEvents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No other events on this day to swap with.')),
      );
      return;
    }

    final targetEvent = await showModalBottomSheet<TimelineEvent>(
      context: context,
      backgroundColor: surfaceDark,
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
              Text(
                'Swap "${event.title}" with:',
                style: const TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...otherEvents.map((other) {
                return ListTile(
                  title: Text(other.title, style: const TextStyle(color: Colors.white, fontSize: 13)),
                  subtitle: Text(
                    'Order #${other.order} · ${other.startTime} - ${other.endTime}',
                    style: const TextStyle(color: textMuted, fontSize: 11),
                  ),
                  trailing: const Icon(Icons.swap_horiz, color: gold),
                  onTap: () => Navigator.pop(ctx, other),
                );
              }),
            ],
          ),
        );
      },
    );

    if (targetEvent == null) return;

    await _performBuilderOperation(
      statusText: 'Swapping event positions & validating continuity...',
      operation: () => widget.repository.customizePlan(
        planId: _currentPlan.planId,
        operation: 'SWAP_EVENT',
        eventId: event.id,
        swapWithEventId: targetEvent.id,
        dayNumber: currentDay.dayNumber,
        reason: 'Swapped ${event.title} with ${targetEvent.title}',
      ),
      successMessage: 'Events swapped successfully',
    );
  }

  // Operation: RAIN_SUBSTITUTE
  Future<void> _substituteRain(TimelineEvent event) async {
    final currentDay = _currentDay;
    if (currentDay == null) return;

    await _performBuilderOperation(
      statusText: 'Finding indoor rain-safe alternative from database...',
      operation: () => widget.repository.customizePlan(
        planId: _currentPlan.planId,
        operation: 'RAIN_SUBSTITUTE',
        eventId: event.id,
        dayNumber: currentDay.dayNumber,
        reason: 'Monsoon weather substitution for ${event.title}',
      ),
      successMessage: 'Rain-safe indoor alternative substituted',
    );
  }

  // Operation: ADD_EVENT (via candidate picker)
  Future<void> _showAddCandidateSheet() async {
    final currentDay = _currentDay;
    if (currentDay == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return _CandidatePickerSheet(
          planId: _currentPlan.planId,
          dayNumber: currentDay.dayNumber,
          destinationName: currentDay.destinationName,
          repository: widget.repository,
          onSelectCandidate: (candidate) async {
            Navigator.pop(ctx);
            await _performBuilderOperation(
              statusText: 'Validating & adding ${candidate.title}...',
              operation: () => widget.repository.customizePlan(
                planId: _currentPlan.planId,
                operation: 'ADD_EVENT',
                entityType: candidate.entityType,
                entityId: candidate.id,
                targetDay: currentDay.dayNumber,
                reason: 'Added ${candidate.title} to Day ${currentDay.dayNumber}',
              ),
              successMessage: 'Added ${candidate.title}',
            );
          },
        );
      },
    );
  }

  // Version History & Revert
  Future<void> _showVersionHistorySheet() async {
    try {
      final versions = await widget.repository.getPlanVersions(_currentPlan.planId);
      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: surfaceDark,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                      'Itinerary Version History',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Every edit produces an immutable version. You can roll back anytime.',
                  style: TextStyle(fontSize: 12, color: textMuted),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: versions.length,
                    itemBuilder: (context, index) {
                      final v = versions[index];
                      final isCurrent = v.version == _currentPlan.version;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isCurrent ? emerald.withValues(alpha: 0.15) : bgDark,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isCurrent ? emerald : Colors.white10,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: isCurrent ? emerald : Colors.white12,
                              child: Text(
                                'v${v.version}',
                                style: TextStyle(
                                  color: isCurrent ? bgDark : textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    v.changeReason,
                                    style: const TextStyle(
                                      color: textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '₹${v.totalPrice.toStringAsFixed(0)} · Status: ${v.validationStatus}',
                                    style: const TextStyle(color: gold, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            if (isCurrent)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: emerald,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Current',
                                  style: TextStyle(
                                    color: bgDark,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            else
                              ElevatedButton(
                                key: Key('revert_btn_v${v.version}'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: gold,
                                  foregroundColor: bgDark,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () async {
                                  Navigator.pop(ctx);
                                  await _performBuilderOperation(
                                    statusText: 'Rolling back to v${v.version}...',
                                    operation: () => widget.repository.revertPlan(
                                      _currentPlan.planId,
                                      v.version,
                                      reason: 'Reverted to v${v.version}',
                                    ),
                                    successMessage: 'Reverted to v${v.version}',
                                  );
                                },
                                child: const Text('Revert', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                          ],
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
        SnackBar(content: Text('Failed to load versions: $e')),
      );
    }
  }

  // Inventory & Holds Sheet
  void _showInventoryHoldSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => InventoryHoldSheet(
        plan: _currentPlan,
        repository: _inventoryRepository,
      ),
    );
  }

  // Diff Modal
  Future<void> _showDiffModal() async {
    ItineraryDiff? diff = _lastDiff;
    if (diff == null && _currentPlan.version > 1) {
      try {
        diff = await widget.repository.getPlanDiff(
          _currentPlan.planId,
          fromVersion: _currentPlan.version - 1,
          toVersion: _currentPlan.version,
        );
      } catch (_) {}
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: surfaceDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.compare_arrows, color: gold, size: 20),
              const SizedBox(width: 8),
              Text(
                diff != null
                    ? 'Version Diff (v${diff.fromVersion} → v${diff.toVersion})'
                    : 'Version Diff',
                style: const TextStyle(color: textPrimary, fontSize: 16),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: diff == null
                ? const Text(
                    'No difference recorded yet or this is v1 (initial plan).',
                    style: TextStyle(color: textMuted),
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Summary row
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: bgDark,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                diff.summaryText,
                                style: const TextStyle(color: textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Price Delta: ${diff.priceDifference >= 0 ? '+' : ''}₹${diff.priceDifference.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      color: diff.priceDifference > 0 ? Colors.amber : (diff.priceDifference < 0 ? emerald : textMuted),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Distance: ${diff.distanceDifference >= 0 ? '+' : ''}${diff.distanceDifference.toStringAsFixed(1)} km',
                                    style: const TextStyle(color: textMuted, fontSize: 11),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    diff.monsoonCompliant ? Icons.check_circle : Icons.warning_amber,
                                    size: 12,
                                    color: diff.monsoonCompliant ? emerald : Colors.amber,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    diff.monsoonCompliant ? 'Monsoon Compliant' : 'Safety Check Recommended',
                                    style: TextStyle(
                                      color: diff.monsoonCompliant ? emerald : Colors.amber,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Added events
                        if (diff.added.isNotEmpty) ...[
                          const Text('Added Events (+):', style: TextStyle(color: emerald, fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 4),
                          ...diff.added.map((item) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Text('• Day ${item.day}: ${item.title}', style: const TextStyle(color: textPrimary, fontSize: 11)),
                              )),
                          const SizedBox(height: 8),
                        ],

                        // Removed events
                        if (diff.removed.isNotEmpty) ...[
                          const Text('Removed Events (-):', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 4),
                          ...diff.removed.map((item) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Text('• Day ${item.day}: ${item.title}', style: const TextStyle(color: textMuted, fontSize: 11)),
                              )),
                          const SizedBox(height: 8),
                        ],

                        // Moved events
                        if (diff.moved.isNotEmpty) ...[
                          const Text('Moved Events (⇄):', style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 4),
                          ...diff.moved.map((item) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Text('• ${item.title}: #${item.fromOrder} → #${item.toOrder}', style: const TextStyle(color: textPrimary, fontSize: 11)),
                              )),
                        ],

                        if (diff.added.isEmpty && diff.removed.isEmpty && diff.moved.isEmpty)
                          const Text('No event additions or deletions.', style: TextStyle(color: textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close', style: TextStyle(color: emerald)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final days = _currentPlan.days;
    final currentDay = _currentDay;

    // Validation Status Color
    Color statusColor;
    switch (_currentPlan.validationStatus.toUpperCase()) {
      case 'VALID':
        statusColor = emerald;
        break;
      case 'WARNINGS':
        statusColor = Colors.amber;
        break;
      default:
        statusColor = Colors.redAccent;
    }

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: surfaceDark,
        elevation: 0,
        title: Row(
          children: [
            const Text(
              'Itinerary Builder',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
            ),
            const SizedBox(width: 8),
            Container(
              key: const Key('builder_version_badge'),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: emerald,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'v${_currentPlan.version}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: bgDark),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: statusColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(radius: 3, backgroundColor: statusColor),
                  const SizedBox(width: 4),
                  Text(
                    _currentPlan.validationStatus.toUpperCase(),
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            key: const Key('builder_diff_btn'),
            icon: const Icon(Icons.compare_arrows, color: gold),
            tooltip: 'View Diff',
            onPressed: _showDiffModal,
          ),
          IconButton(
            key: const Key('builder_history_btn'),
            icon: const Icon(Icons.history, color: textPrimary),
            tooltip: 'Version History',
            onPressed: _showVersionHistorySheet,
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Summary Header Card
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surfaceDark,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: emerald.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _currentPlan.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            '₹${_currentPlan.pricing.total.toStringAsFixed(0)}',
                            key: const Key('builder_total_price'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: gold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_currentPlan.durationDays} Days · ${_currentPlan.travelStyle}',
                            style: const TextStyle(fontSize: 12, color: textMuted),
                          ),
                          if (_lastDiff != null && _lastDiff!.priceDifference != 0)
                            Text(
                              '${_lastDiff!.priceDifference > 0 ? '+' : ''}₹${_lastDiff!.priceDifference.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _lastDiff!.priceDifference > 0 ? Colors.amber : emerald,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Corridor Route Chips
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          ..._currentPlan.corridorRoute.map((dest) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: bgDark,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Text(
                                dest,
                                style: const TextStyle(color: Colors.white70, fontSize: 10),
                              ),
                            );
                          }),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _currentPlan.monsoonMode
                                  ? const Color(0xFF0284C7).withValues(alpha: 0.2)
                                  : gold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _currentPlan.monsoonMode ? const Color(0xFF38BDF8) : gold,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _currentPlan.monsoonMode ? Icons.water_drop : Icons.wb_sunny,
                                  size: 10,
                                  color: _currentPlan.monsoonMode ? const Color(0xFF38BDF8) : gold,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _currentPlan.monsoonMode ? 'Monsoon Compliant' : 'Peak Weather',
                                  style: TextStyle(
                                    color: _currentPlan.monsoonMode ? const Color(0xFF38BDF8) : gold,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
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

                // Day Selector Tabs
                if (days.isNotEmpty)
                  SizedBox(
                    height: 44,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: days.length,
                      itemBuilder: (context, index) {
                        final d = days[index];
                        final isSelected = index == _selectedDayIndex;
                        return GestureDetector(
                          key: Key('builder_day_tab_${d.dayNumber}'),
                          onTap: () => setState(() => _selectedDayIndex = index),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? emerald : surfaceDark,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? emerald : Colors.white12,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Day ${d.dayNumber}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? bgDark : textPrimary,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 14),

                // Selected Day Header Info
                if (currentDay != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: surfaceDark,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: gold.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, color: gold, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentDay.destinationName,
                                  style: const TextStyle(
                                    color: gold,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  currentDay.themeTitle,
                                  style: const TextStyle(color: textPrimary, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${currentDay.timeline.length} events',
                            style: const TextStyle(color: textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Events Timeline List
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: currentDay.timeline.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final event = entry.value;
                        final isFirst = idx == 0;
                        final isLast = idx == currentDay.timeline.length - 1;
                        return _buildEventItem(event, isFirst: isFirst, isLast: isLast);
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // "+ Add Experience" button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: OutlinedButton.icon(
                        key: const Key('builder_add_event_btn'),
                        icon: const Icon(Icons.add_circle_outline, color: emerald, size: 18),
                        label: Text(
                          'Add Experience to Day ${currentDay.dayNumber}',
                          style: const TextStyle(color: emerald, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: emerald, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _showAddCandidateSheet,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // "Check Availability & Hold (15 Mins)" CTA Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        key: const Key('builder_check_availability_btn'),
                        icon: const Icon(Icons.timer_outlined, color: bgDark, size: 20),
                        label: const Text(
                          'Check Availability & Hold (15 Mins)',
                          style: TextStyle(
                            color: bgDark,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: gold,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 2,
                        ),
                        onPressed: _showInventoryHoldSheet,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 40),
              ],
            ),
          ),

          // Loading Overlay / Status banner
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.65),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(32),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: surfaceDark,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: emerald),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: emerald),
                      const SizedBox(height: 16),
                      Text(
                        _statusMessage ?? 'Validating changes with Django...',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEventItem(TimelineEvent event, {required bool isFirst, required bool isLast}) {
    Color typeColor;
    IconData typeIcon;
    switch (event.type) {
      case 'EXPERIENCE':
        typeColor = emerald;
        typeIcon = Icons.local_activity;
        break;
      case 'ATTRACTION':
        typeColor = const Color(0xFF38BDF8);
        typeIcon = Icons.photo_camera;
        break;
      case 'MEAL':
        typeColor = Colors.orangeAccent;
        typeIcon = Icons.restaurant;
        break;
      case 'STAY':
        typeColor = Colors.purpleAccent;
        typeIcon = Icons.hotel;
        break;
      case 'TRANSFER':
        typeColor = Colors.blueAccent;
        typeIcon = Icons.directions_car;
        break;
      default:
        typeColor = Colors.white54;
        typeIcon = Icons.event;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order, Type, and Actions Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: bgDark,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(
                  '#${event.order}',
                  style: const TextStyle(color: textMuted, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(typeIcon, size: 11, color: typeColor),
                    const SizedBox(width: 4),
                    Text(
                      event.type,
                      style: TextStyle(color: typeColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Reorder / Move Up Button
              IconButton(
                key: Key('move_up_${event.id}'),
                icon: const Icon(Icons.arrow_upward, size: 16),
                color: isFirst ? Colors.white12 : textMuted,
                tooltip: 'Move Up',
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                onPressed: isFirst ? null : () => _moveEvent(event, -1),
              ),
              const SizedBox(width: 4),
              // Reorder / Move Down Button
              IconButton(
                key: Key('move_down_${event.id}'),
                icon: const Icon(Icons.arrow_downward, size: 16),
                color: isLast ? Colors.white12 : textMuted,
                tooltip: 'Move Down',
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                onPressed: isLast ? null : () => _moveEvent(event, 1),
              ),
              const SizedBox(width: 4),
              // Swap Button
              IconButton(
                key: Key('swap_${event.id}'),
                icon: const Icon(Icons.swap_vert, size: 16),
                color: textMuted,
                tooltip: 'Swap Position',
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                onPressed: () => _swapEventWithAnother(event),
              ),
              const SizedBox(width: 4),
              // Remove Button
              IconButton(
                key: Key('remove_${event.id}'),
                icon: const Icon(Icons.close, size: 16),
                color: Colors.redAccent.withValues(alpha: 0.7),
                tooltip: 'Remove',
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                onPressed: () => _removeEvent(event),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Title
          Text(
            event.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),

          const SizedBox(height: 6),

          // Time Range
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 12, color: textMuted),
              const SizedBox(width: 4),
              Text(
                '${event.startTime} - ${event.endTime}',
                style: const TextStyle(color: textMuted, fontSize: 11),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Bottom attributes row: Rain status, Price, Rain Alternative action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          event.rainFriendly ? Icons.beach_access : Icons.wb_sunny,
                          size: 12,
                          color: event.rainFriendly ? emerald : Colors.amber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          event.rainFriendly ? 'Rain Friendly' : 'Outdoor',
                          style: TextStyle(
                            fontSize: 11,
                            color: event.rainFriendly ? emerald : Colors.amber,
                          ),
                        ),
                      ],
                    ),
                    if (!event.rainFriendly)
                      TextButton.icon(
                        key: Key('rain_sub_${event.id}'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          backgroundColor: gold.withValues(alpha: 0.15),
                        ),
                        icon: const Icon(Icons.umbrella, size: 12, color: gold),
                        label: const Text(
                          'Rain Safe Alternative',
                          style: TextStyle(fontSize: 10, color: gold, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () => _substituteRain(event),
                      ),
                  ],
                ),
              ),
              if (event.price > 0) ...[
                const SizedBox(width: 8),
                Text(
                  '₹${event.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: gold,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _CandidatePickerSheet extends StatefulWidget {
  final String planId;
  final int dayNumber;
  final String destinationName;
  final IAIPlannerRepository repository;
  final ValueChanged<PlanCandidate> onSelectCandidate;

  const _CandidatePickerSheet({
    required this.planId,
    required this.dayNumber,
    required this.destinationName,
    required this.repository,
    required this.onSelectCandidate,
  });

  @override
  State<_CandidatePickerSheet> createState() => _CandidatePickerSheetState();
}

class _CandidatePickerSheetState extends State<_CandidatePickerSheet> {
  bool _loading = true;
  List<PlanCandidate> _candidates = [];
  bool _rainOnly = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCandidates();
  }

  Future<void> _loadCandidates() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await widget.repository.getCandidates(
        widget.planId,
        widget.dayNumber,
        rainFriendlyOnly: _rainOnly,
      );
      if (!mounted) return;
      setState(() {
        _candidates = list;
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
    const bgDark = Color(0xFF0D1F17);
    const emerald = Color(0xFF10B981);
    const gold = Color(0xFFD4AF37);
    const textPrimary = Color(0xFFF7F3E8);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (ctx, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Add Verified Experience',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Day ${widget.dayNumber} · ${widget.destinationName}',
                        style: const TextStyle(color: Color(0xFFC5D8CD), fontSize: 12),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Filter row
              Row(
                children: [
                  FilterChip(
                    label: const Text('Rain Safe Only', style: TextStyle(fontSize: 11)),
                    selected: _rainOnly,
                    selectedColor: emerald.withValues(alpha: 0.25),
                    checkmarkColor: emerald,
                    onSelected: (val) {
                      setState(() => _rainOnly = val);
                      _loadCandidates();
                    },
                  ),
                ],
              ),

              const SizedBox(height: 10),

              if (_loading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator(color: emerald)),
                )
              else if (_error != null)
                Expanded(
                  child: Center(
                    child: Text('Error: $_error', style: const TextStyle(color: Colors.redAccent)),
                  ),
                )
              else if (_candidates.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'No candidates available for this day.',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: _candidates.length,
                    itemBuilder: (context, index) {
                      final candidate = _candidates[index];
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
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: emerald.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          candidate.entityType,
                                          style: const TextStyle(color: emerald, fontSize: 9, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      if (candidate.rainFriendly)
                                        const Icon(Icons.beach_access, size: 12, color: emerald),
                                      const Spacer(),
                                      Text(
                                        '₹${candidate.price.toStringAsFixed(0)}',
                                        style: const TextStyle(color: gold, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    candidate.title,
                                    style: const TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${candidate.durationMins} mins · ⭐ ${candidate.rating.toStringAsFixed(1)}',
                                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              key: Key('candidate_add_btn_${candidate.id}'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: emerald,
                                foregroundColor: bgDark,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () => widget.onSelectCandidate(candidate),
                              child: const Text('Add', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
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
  }
}

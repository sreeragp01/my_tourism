import 'package:flutter/material.dart';

class ProximityBanner extends StatelessWidget {
  final String waypointName;
  final double distanceMeters;
  final String eventType; // ARRIVAL_200M or APPROACH_500M
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;

  const ProximityBanner({
    super.key,
    required this.waypointName,
    required this.distanceMeters,
    required this.eventType,
    this.onAction,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isArrival = eventType == 'ARRIVAL_200M' || distanceMeters <= 200;
    final primaryColor = isArrival ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    final title = isArrival ? 'Arrived at $waypointName' : 'Approaching $waypointName';
    final subtitle = isArrival
        ? 'You are within ${distanceMeters.toInt()}m. Digital booking pass is ready for check-in.'
        : 'Estimated distance: ${distanceMeters.toInt()}m along scenic corridor.';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF142B20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primaryColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isArrival ? Icons.check_circle_outline : Icons.near_me_outlined,
              color: primaryColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFF7F3E8),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 11, height: 1.3),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton(
                      key: const Key('proximity_action_btn'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: const Color(0xFF0D1F17),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: onAction,
                      child: Text(
                        isArrival ? 'Show Pass QR' : 'View Waypoint',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (onDismiss != null)
                      TextButton(
                        key: const Key('proximity_dismiss_btn'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: onDismiss,
                        child: const Text('Dismiss', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11)),
                      ),
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

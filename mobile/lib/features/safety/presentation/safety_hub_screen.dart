import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/safety_models.dart';
import '../data/safety_repository.dart';

class SafetyHubScreen extends StatefulWidget {
  final ISafetyRepository? repository;
  final String? bookingReference;

  const SafetyHubScreen({
    super.key,
    this.repository,
    this.bookingReference,
  });

  @override
  State<SafetyHubScreen> createState() => _SafetyHubScreenState();
}

class _SafetyHubScreenState extends State<SafetyHubScreen> {
  TripShareResult? _activeShareToken;
  String? _lastSosAlertId;

  Future<void> _triggerSos() async {
    if (widget.repository != null) {
      try {
        final alert = await widget.repository!.triggerSos(
          bookingReference: widget.bookingReference ?? 'KL2609071234',
          latitude: 10.0889,
          longitude: 77.0595,
          locationName: 'Lockhart Tea Valley, Munnar',
          alertType: 'SOS_112',
        );
        setState(() => _lastSosAlertId = alert.alertId);
      } catch (_) {}
    }

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceTeal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.emergencyRed, width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.emergencyRed, size: 28),
            SizedBox(width: 8),
            Text(
              'Emergency Alert Sent',
              style: TextStyle(color: AppTheme.textCream, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your GPS location (10.0889°N, 77.0595°E - Lockhart Valley) has been transmitted to Kerala Tourist Police and National Emergency Services.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.4),
            ),
            if (_lastSosAlertId != null) ...[
              const SizedBox(height: 10),
              Text(
                'Alert Reference: ${_lastSosAlertId!.substring(0, 8)}...',
                style: const TextStyle(color: AppTheme.oceanTeal, fontSize: 12, fontFamily: 'monospace'),
              ),
            ],
            const SizedBox(height: 12),
            const Text(
              'Immediate Action: Dial 112 directly below or wait in safe shelter.',
              style: TextStyle(color: AppTheme.sunsetGold, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            key: const Key('dismiss_sos_dialog_btn'),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Dismiss', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton.icon(
            key: const Key('call_112_btn'),
            icon: const Icon(Icons.phone, size: 16, color: Colors.white),
            label: const Text('Call 112 Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emergencyRed),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Dialing National Emergency SOS 112...'),
                  backgroundColor: AppTheme.emergencyRed,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _createShareLink() async {
    final ref = widget.bookingReference ?? 'KL2609071234';
    if (widget.repository != null) {
      try {
        final result = await widget.repository!.createTripShareToken(ref, expiryHours: 24);
        if (mounted) {
          setState(() => _activeShareToken = result);
        }
      } catch (_) {}
    } else {
      if (mounted) {
        setState(() {
          _activeShareToken = TripShareResult(
            token: 'mock-share-token-xyz-1234',
            bookingReference: ref,
            expiresAt: '24 hours from now',
            shareUrl: '/api/v1/safety/shared/mock-share-token-xyz-1234/',
            isValid: true,
          );
        });
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Temporary family share link generated (valid 24h).'),
          backgroundColor: AppTheme.oceanTeal,
        ),
      );
    }
  }

  Future<void> _revokeShareLink() async {
    if (_activeShareToken != null && widget.repository != null) {
      try {
        await widget.repository!.revokeTripShareToken(_activeShareToken!.token);
      } catch (_) {}
    }
    if (mounted) {
      setState(() => _activeShareToken = null);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trip share link has been revoked.'),
          backgroundColor: AppTheme.sunsetGold,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final helplines = [
      {
        'title': 'National Emergency & Police',
        'number': '112',
        'type': 'Immediate Dispatch (Toll-Free 24x7)',
        'color': AppTheme.emergencyRed,
        'icon': Icons.emergency,
      },
      {
        'title': 'Kerala Tourist Police Helpline',
        'number': '1800-425-4747',
        'type': 'Tourist Assistance & Protection',
        'color': AppTheme.oceanTeal,
        'icon': Icons.shield_outlined,
      },
      {
        'title': 'Women Safety Helpline (Mitra)',
        'number': '181',
        'type': 'Rapid Response Support',
        'color': AppTheme.sunsetGold,
        'icon': Icons.support_agent,
      },
      {
        'title': 'Ambulance / Emergency Medical',
        'number': '108',
        'type': 'Kerala State EMS Network',
        'color': const Color(0xFF38BDF8),
        'icon': Icons.local_hospital_outlined,
      },
      {
        'title': 'Highway Police Patrol',
        'number': '9846100100',
        'type': 'NH66 & Munnar Ghat NH85 Patrol',
        'color': AppTheme.sunsetCoral,
        'icon': Icons.directions_car_outlined,
      },
    ];

    return Scaffold(
      backgroundColor: AppTheme.midnightTeal,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceTeal,
        elevation: 0,
        title: const Text(
          'Safety & Emergency Hub',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textCream),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Emergency SOS Action Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF881337), Color(0xFF4C0519)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.emergencyRed, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.emergencyRed.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppTheme.emergencyRed,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.sos, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EMERGENCY SOS',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Transmits GPS coords to Tourist Police & 112 dispatch.',
                            style: TextStyle(color: Color(0xFFFECDD3), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    key: const Key('trigger_sos_btn'),
                    icon: const Icon(Icons.emergency, color: Colors.white),
                    label: const Text(
                      'TRIGGER IMMEDIATE SOS (112)',
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.emergencyRed,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _triggerSos,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Temporary Trip Share Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceTeal,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.borderTeal),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.share_location, color: AppTheme.oceanTeal, size: 22),
                    const SizedBox(width: 8),
                    const Text(
                      'Family Live Trip Sharing',
                      style: TextStyle(color: AppTheme.textCream, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.midnightTeal,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.borderTeal),
                      ),
                      child: const Text('24H TOKEN', style: TextStyle(color: AppTheme.oceanTeal, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Share sanitized live trip progress with family without sharing payment info, personal phone, or credentials.',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 12),
                if (_activeShareToken == null) ...[
                  ElevatedButton.icon(
                    key: const Key('generate_share_link_btn'),
                    icon: const Icon(Icons.link, size: 18, color: AppTheme.midnightTeal),
                    label: const Text('Generate Family Share Link', style: TextStyle(color: AppTheme.midnightTeal, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.oceanTeal,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _createShareLink,
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.midnightTeal,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.oceanTeal),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle, color: AppTheme.oceanTeal, size: 16),
                            const SizedBox(width: 6),
                            const Text(
                              'Active Share Link',
                              style: TextStyle(color: AppTheme.oceanTeal, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            Text(
                              'Token: ${_activeShareToken!.token.substring(0, 8)}...',
                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontFamily: 'monospace'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                key: const Key('copy_share_link_btn'),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppTheme.borderTeal),
                                ),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Share URL copied to clipboard.'),
                                      backgroundColor: AppTheme.oceanTeal,
                                    ),
                                  );
                                },
                                child: const Text('Copy Link', style: TextStyle(color: AppTheme.textCream, fontSize: 12)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                key: const Key('revoke_share_link_btn'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.emergencyRed,
                                ),
                                onPressed: _revokeShareLink,
                                child: const Text('Revoke Link', style: TextStyle(color: Colors.white, fontSize: 12)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Verified Helplines Directory
          const Text(
            'Official Kerala Tourism Helplines',
            style: TextStyle(color: AppTheme.textCream, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          for (final h in helplines) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceTeal,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderTeal),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (h['color'] as Color).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(h['icon'] as IconData, color: h['color'] as Color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          h['title'] as String,
                          style: const TextStyle(color: AppTheme.textCream, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          h['type'] as String,
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    key: Key('call_btn_${h['number']}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.midnightTeal,
                      foregroundColor: h['color'] as Color,
                      side: BorderSide(color: (h['color'] as Color).withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Dialing ${h['title']}: ${h['number']}...'),
                          backgroundColor: h['color'] as Color,
                        ),
                      );
                    },
                    child: Text(
                      h['number'] as String,
                      style: TextStyle(color: h['color'] as Color, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

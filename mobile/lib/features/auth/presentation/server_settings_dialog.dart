import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';

class ServerSettingsDialog extends StatefulWidget {
  final ApiClient apiClient;

  const ServerSettingsDialog({
    super.key,
    required this.apiClient,
  });

  static Future<void> show(BuildContext context, ApiClient apiClient) {
    return showDialog(
      context: context,
      builder: (_) => ServerSettingsDialog(apiClient: apiClient),
    );
  }

  @override
  State<ServerSettingsDialog> createState() => _ServerSettingsDialogState();
}

class _ServerSettingsDialogState extends State<ServerSettingsDialog> {
  late final TextEditingController _controller;
  bool _isTesting = false;
  bool? _testSuccess;
  String? _testMessage;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.apiClient.baseUrl);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    final targetUrl = _controller.text.trim();
    if (targetUrl.isEmpty) return;

    setState(() {
      _isTesting = true;
      _testSuccess = null;
      _testMessage = null;
    });

    final isReachable = await widget.apiClient.checkHealth(targetUrl);

    if (mounted) {
      setState(() {
        _isTesting = false;
        _testSuccess = isReachable;
        _testMessage = isReachable
            ? 'Success: Server is reachable and ready!'
            : 'Connection failed. Verify backend is running on 0.0.0.0:8000.';
      });
    }
  }

  void _applyPreset(String url) {
    setState(() {
      _controller.text = url;
      _testSuccess = null;
      _testMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF142B20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: const [
          Icon(Icons.dns_outlined, color: Color(0xFF10B981), size: 22),
          SizedBox(width: 8),
          Text(
            'Server Connection',
            style: TextStyle(color: Color(0xFFF7F3E8), fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Specify the Django backend URL for your network:',
              style: TextStyle(color: Color(0xFFC5D8CD), fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF0D1F17),
                hintText: 'http://192.168.x.x:8000/api/v1',
                hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: (_) {
                if (_testSuccess != null) {
                  setState(() {
                    _testSuccess = null;
                    _testMessage = null;
                  });
                }
              },
            ),
            const SizedBox(height: 10),

            // Test Connection Button & Indicator
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _isTesting ? null : _testConnection,
                  icon: _isTesting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10B981)),
                        )
                      : const Icon(Icons.wifi_tethering, size: 15, color: Color(0xFF10B981)),
                  label: Text(
                    _isTesting ? 'Testing...' : 'Test Connection',
                    style: const TextStyle(color: Color(0xFF10B981), fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF10B981), width: 0.8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                ),
              ],
            ),

            if (_testMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (_testSuccess == true ? const Color(0xFF10B981) : const Color(0xFFE11D48)).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _testSuccess == true ? const Color(0xFF10B981) : const Color(0xFFE11D48),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _testSuccess == true ? Icons.check_circle_outline : Icons.error_outline,
                      color: _testSuccess == true ? const Color(0xFF10B981) : const Color(0xFFE11D48),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _testMessage!,
                        style: TextStyle(
                          color: _testSuccess == true ? const Color(0xFF10B981) : const Color(0xFFFCA5A5),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),
            const Text(
              'Quick Presets:',
              style: TextStyle(color: Color(0xFFD4AF37), fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _presetChip('Wi-Fi LAN', 'http://192.168.220.40:8000/api/v1', 'Physical Phone'),
                _presetChip('USB ADB', 'http://127.0.0.1:8000/api/v1', 'Cable Reverse'),
                _presetChip('Emulator', 'http://10.0.2.2:8000/api/v1', 'Android Studio'),
                _presetChip('Localhost', 'http://localhost:8000/api/v1', 'Desktop / Web'),
              ],
            ),

            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1F17),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💡 Physical Phone Guide:',
                    style: TextStyle(color: Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '• Option 1 (Wi-Fi): Connect phone to same Wi-Fi and choose "Wi-Fi LAN".\n'
                    '• Option 2 (USB): Plug cable, run "adb reverse tcp:8000 tcp:8000", and choose "USB ADB".',
                    style: TextStyle(color: Color(0xFF8BA598), fontSize: 10, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white60, fontSize: 13)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: const Color(0xFF0D1F17),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () {
            final text = _controller.text.trim();
            if (text.isNotEmpty) {
              widget.apiClient.setCustomBaseUrl(text);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Server set to $text'),
                  backgroundColor: const Color(0xFF10B981),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
            Navigator.pop(context);
          },
          child: const Text('Save & Apply', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ],
    );
  }

  Widget _presetChip(String label, String url, String subtitle) {
    final isSelected = _controller.text.trim() == url;
    return ActionChip(
      backgroundColor: isSelected ? const Color(0xFF10B981).withValues(alpha: 0.2) : const Color(0xFF1B382B),
      side: BorderSide(
        color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
        width: 1,
      ),
      label: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
          Text(subtitle, style: const TextStyle(fontSize: 9, color: Colors.white54)),
        ],
      ),
      onPressed: () => _applyPreset(url),
    );
  }
}

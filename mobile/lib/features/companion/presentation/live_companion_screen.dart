import 'package:flutter/material.dart';

class LiveCompanionScreen extends StatefulWidget {
  const LiveCompanionScreen({super.key});

  @override
  State<LiveCompanionScreen> createState() => _LiveCompanionScreenState();
}

class _LiveCompanionScreenState extends State<LiveCompanionScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {
      'sender': 'ai',
      'text': 'Namaskaram Sreerag! 🌴 I am your live KeraLink Companion. You are on Day 2 in Munnar. Light mountain mist is active (19°C). How can I assist your journey?',
      'time': '10:15 AM',
      'suggestions': ["What's next on timeline?", "Monsoon radar", "Local food nearby"]
    }
  ];

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add({
        'sender': 'user',
        'text': text,
        'time': 'Just now',
      });
      _messages.add({
        'sender': 'ai',
        'text': '🌧️ Mountain mist is clearing near Lockhart Estate. Your Heritage Tea Estate walk is scheduled at 14:30. Driver Rajesh is on standby.',
        'time': 'Just now',
        'suggestions': ['Call Driver Rajesh', 'View Tea Tasting details']
      });
    });
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1F17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF142B20),
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KeraLink AI Companion',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Day 2 · Munnar Hills (19°C Mist)',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_in_talk, color: Color(0xFFE63946)),
            tooltip: 'Tourist Police (1800-425-4747)',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Dialing 24/7 Kerala Tourist Police Helpline: 1800-425-4747')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Emergency Safety & Weather Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF1E3A2B),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, color: Color(0xFFD4A373), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'KeraLink 24/7 Safety Net Active · Medical & Ghat Radar Synced',
                    style: TextStyle(color: Color(0xFFD4A373), fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          // Messages List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isAi = msg['sender'] == 'ai';
                return Align(
                  alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                    decoration: BoxDecoration(
                      color: isAi ? const Color(0xFF1B3629) : const Color(0xFF2E6F40),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isAi ? const Color(0xFF2D5A43) : Colors.transparent,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg['text'],
                          style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                        ),
                        if (msg['suggestions'] != null) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: (msg['suggestions'] as List<String>).map((s) {
                              return ActionChip(
                                label: Text(s, style: const TextStyle(fontSize: 10, color: Color(0xFFD4A373))),
                                backgroundColor: const Color(0xFF0F261B),
                                onPressed: () => _sendMessage(s),
                              );
                            }).toList(),
                          ),
                        ]
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Input Field
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF142B20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Ask your companion anything...',
                      hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFF0D1F17),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFFD4A373)),
                  onPressed: () => _sendMessage(_textController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

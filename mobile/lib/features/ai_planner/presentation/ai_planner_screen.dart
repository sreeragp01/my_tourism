import 'package:flutter/material.dart';

class AIPlannerScreen extends StatefulWidget {
  const AIPlannerScreen({super.key});

  @override
  State<AIPlannerScreen> createState() => _AIPlannerScreenState();
}

class _AIPlannerScreenState extends State<AIPlannerScreen> {
  final TextEditingController _promptController = TextEditingController(
    text: '6 days luxury Kerala trip to Munnar and Alleppey with authentic cuisine',
  );

  double _durationDays = 6;
  String _travelStyle = 'PREMIUM';
  bool _isGenerating = false;
  Map<String, dynamic>? _generatedPlan;

  void _generateItinerary() {
    setState(() {
      _isGenerating = true;
    });

    // Simulate AI synthesis based on requirement parser & pricing engine
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _generatedPlan = {
          'title': 'Romantic Kerala Hills & Backwaters Corridor',
          'duration': '${_durationDays.toInt()} Days / ${(_durationDays - 1).toInt()} Nights',
          'totalPrice': '₹78,400',
          'greenScore': '91/100',
          'days': [
            {
              'day': 'Day 1',
              'location': 'Fort Kochi & Colonial Promenade',
              'activity': 'Heritage Net Walk & Kathakali Performance',
              'stay': 'Brunton Boatyard (Heritage)',
            },
            {
              'day': 'Day 2',
              'location': 'Munnar Tea Highlands',
              'activity': 'Lockhart Tea Tasting & Mist Cloud Trail',
              'stay': 'Spice Tree Luxury Chalet',
            },
            {
              'day': 'Day 3',
              'location': 'Alleppey Backwaters',
              'activity': 'Private Solar-Assisted Houseboat Cruise',
              'stay': 'Vembanad Lake Heritage Tharavadu',
            },
          ],
        };
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1F17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF142B20),
        elevation: 0,
        title: const Text(
          'AI Travel Architect',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFF7F3E8)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Prompt Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF142B20),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'What kind of Kerala journey do you dream of?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF7F3E8),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _promptController,
                    maxLines: 3,
                    style: const TextStyle(fontSize: 13, color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF0D1F17),
                      hintText: 'e.g., 5 days relaxing family trip with treehouse and backwaters...',
                      hintStyle: const TextStyle(fontSize: 12, color: Colors.white38),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Duration',
                        style: TextStyle(fontSize: 13, color: Color(0xFFC5D8CD)),
                      ),
                      Text(
                        '${_durationDays.toInt()} Days',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD4AF37),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _durationDays,
                    min: 3,
                    max: 10,
                    divisions: 7,
                    activeColor: const Color(0xFF10B981),
                    inactiveColor: Colors.white10,
                    onChanged: (v) => setState(() => _durationDays = v),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Travel Style',
                    style: TextStyle(fontSize: 13, color: Color(0xFFC5D8CD)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: ['BUDGET', 'COMFORT', 'PREMIUM', 'LUXURY'].map((style) {
                      final selected = _travelStyle == style;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _travelStyle = style),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: selected ? const Color(0xFF10B981) : const Color(0xFF0D1F17),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected ? const Color(0xFF10B981) : Colors.white12,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                style,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: selected ? const Color(0xFF0D1F17) : Colors.white70,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: _isGenerating ? null : _generateItinerary,
                      icon: _isGenerating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF144032)),
                            )
                          : const Icon(Icons.bolt, size: 18),
                      label: Text(_isGenerating ? 'Synthesizing Route...' : 'Generate Plan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        foregroundColor: const Color(0xFF144032),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_generatedPlan != null) ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Generated Itinerary',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF7F3E8),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Green Score ${_generatedPlan!['greenScore']}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF142B20),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _generatedPlan!['title'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _generatedPlan!['duration'],
                          style: const TextStyle(fontSize: 12, color: Color(0xFFC5D8CD)),
                        ),
                        Text(
                          _generatedPlan!['totalPrice'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD4AF37),
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white12, height: 24),
                    ...(_generatedPlan!['days'] as List).map((d) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                d['day'],
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    d['location'],
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    d['activity'],
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFFC5D8CD),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:keralink_mobile/core/config/app_config.dart';
import 'package:keralink_mobile/core/network/api_client.dart';
import 'package:keralink_mobile/core/storage/secure_token_storage.dart';
import '../data/ai_planner_repository.dart';
import '../models/itinerary_models.dart';
import 'itinerary_details_screen.dart';

class AIPlannerScreen extends StatefulWidget {
  final IAIPlannerRepository? repository;

  const AIPlannerScreen({super.key, this.repository});

  @override
  State<AIPlannerScreen> createState() => _AIPlannerScreenState();
}

class _AIPlannerScreenState extends State<AIPlannerScreen> {
  late final IAIPlannerRepository _repository;

  final TextEditingController _promptController = TextEditingController(
    text: '6 days luxury Kerala trip to Munnar and Alleppey with authentic cuisine',
  );

  double _durationDays = 6;
  String _travelStyle = 'PREMIUM';
  double _estimatedBudget = 65000;
  bool _isGenerating = false;
  bool _isParsingPrompt = false;
  AIPlan? _generatedPlan;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ??
        AIPlannerRepository(
          apiClient: ApiClient(
            config: AppConfig.fromEnvironment(),
            storage: SecureTokenStorage(),
          ),
        );
  }

  Future<void> _parsePrompt() async {
    final text = _promptController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isParsingPrompt = true;
      _errorMessage = null;
    });

    try {
      final profile = await _repository.parsePrompt(text);
      if (!mounted) return;
      setState(() {
        _isParsingPrompt = false;
        _durationDays = profile.durationDays.toDouble().clamp(2, 10);
        _travelStyle = profile.travelStyle;
        _estimatedBudget = profile.budgetLimit;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('AI Extracted: ${_durationDays.toInt()} Days · $_travelStyle style'),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isParsingPrompt = false;
      });
    }
  }

  Future<void> _generateItinerary() async {
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      final plan = await _repository.generateItinerary(
        budget: _estimatedBudget,
        duration: _durationDays.toInt(),
        travelStyle: _travelStyle,
      );

      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _generatedPlan = plan;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _errorMessage = 'Generation failed: ${e.toString()}';
      });
    }
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'What kind of Kerala journey do you dream of?',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF7F3E8),
                          ),
                        ),
                      ),
                      TextButton.icon(
                        key: const Key('ai_parse_prompt_btn'),
                        onPressed: _isParsingPrompt ? null : _parsePrompt,
                        icon: _isParsingPrompt
                            ? const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10B981)),
                              )
                            : const Icon(Icons.auto_awesome, size: 14, color: Color(0xFF10B981)),
                        label: const Text(
                          'Extract Intent',
                          style: TextStyle(fontSize: 11, color: Color(0xFF10B981)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    key: const Key('ai_prompt_input'),
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
                    min: 2,
                    max: 10,
                    divisions: 8,
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
                    height: 48,
                    child: ElevatedButton.icon(
                      key: const Key('ai_generate_plan_btn'),
                      onPressed: _isGenerating ? null : _generateItinerary,
                      icon: _isGenerating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF144032)),
                            )
                          : const Icon(Icons.bolt, size: 18),
                      label: Text(_isGenerating ? 'Synthesizing Authoritative Route...' : 'Generate Plan'),
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

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (_generatedPlan != null) ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Synthesized Itinerary',
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
                      border: Border.all(color: const Color(0xFF10B981)),
                    ),
                    child: Text(
                      'Score ${_generatedPlan!.validation.score}/100',
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
                      _generatedPlan!.title,
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
                          '${_generatedPlan!.durationDays} Days / ${_generatedPlan!.travelStyle}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFFC5D8CD)),
                        ),
                        Text(
                          '₹${_generatedPlan!.pricing.total.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD4AF37),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: _generatedPlan!.corridorRoute.map((c) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D1F17),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Text(c, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                        );
                      }).toList(),
                    ),
                    const Divider(color: Colors.white12, height: 24),
                    ..._generatedPlan!.days.take(3).map((d) {
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
                                'Day ${d.dayNumber}',
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
                                    d.destinationName,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    d.themeTitle,
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
                    if (_generatedPlan!.days.length > 3)
                      Center(
                        child: Text(
                          '+ ${_generatedPlan!.days.length - 3} more days in corridor',
                          style: const TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        key: const Key('ai_view_details_btn'),
                        icon: const Icon(Icons.tune, size: 18),
                        label: const Text('Customize & View Day Schedule'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: const Color(0xFF0D1F17),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          textStyle: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (ctx) => ItineraryDetailsScreen(
                                initialPlan: _generatedPlan!,
                                repository: _repository,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
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


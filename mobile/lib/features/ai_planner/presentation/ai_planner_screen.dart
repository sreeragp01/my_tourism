import 'dart:async';
import 'package:flutter/material.dart';
import 'package:keralink_mobile/core/config/app_config.dart';
import 'package:keralink_mobile/core/network/api_client.dart';
import 'package:keralink_mobile/core/storage/secure_token_storage.dart';
import '../data/ai_planner_repository.dart';
import '../models/itinerary_models.dart';
import 'itinerary_builder_screen.dart';

class AIPlannerScreen extends StatefulWidget {
  final IAIPlannerRepository? repository;

  const AIPlannerScreen({super.key, this.repository});

  @override
  State<AIPlannerScreen> createState() => _AIPlannerScreenState();
}

class _AIPlannerScreenState extends State<AIPlannerScreen> {
  late final IAIPlannerRepository _repository;

  final TextEditingController _promptController = TextEditingController(
    text: '6 days luxury Kerala trip with my wife in June, budget ₹80,000, relaxed trip with nature and good food',
  );

  double _durationDays = 6;
  String _travelStyle = 'PREMIUM';
  double _estimatedBudget = 80000;
  String _month = 'June';
  bool _monsoonMode = true;
  int _adults = 2;
  List<String> _interests = ['Nature', 'Food', 'Backwaters'];

  bool _isGenerating = false;
  bool _isParsingPrompt = false;
  int _progressStepIndex = 0;
  Timer? _progressTimer;

  AIPlan? _generatedPlan;
  String? _errorMessage;

  final List<String> _generationSteps = [
    'Analyzing traveler preferences & group constraints',
    'Filtering candidate corridors & heritage attractions',
    'Optimizing road transit times across Western Ghats',
    'Checking live monsoon forecasts & weather safety',
    'Verifying boutique room inventory & experience slots',
    'Calculating transparent pricing & Green Trip Score',
  ];

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

  @override
  void dispose() {
    _progressTimer?.cancel();
    _promptController.dispose();
    super.dispose();
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
        _month = profile.month;
        _monsoonMode = profile.monsoonMode;
        _adults = profile.adults;
        if (profile.interests.isNotEmpty) {
          _interests = profile.interests;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('AI Extracted: ${_durationDays.toInt()} Days · $_month · $_travelStyle style'),
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
      _progressStepIndex = 0;
      _errorMessage = null;
    });

    // Animate the 6 authoritative generation progress steps
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 380), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_progressStepIndex < _generationSteps.length - 1) {
        setState(() {
          _progressStepIndex++;
        });
      } else {
        timer.cancel();
      }
    });

    try {
      final plan = await _repository.generateItinerary(
        budget: _estimatedBudget,
        duration: _durationDays.toInt(),
        travelStyle: _travelStyle,
        month: _month,
        monsoonMode: _monsoonMode,
        interests: _interests,
        adults: _adults,
      );

      _progressTimer?.cancel();

      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _generatedPlan = plan;
      });
    } catch (e) {
      _progressTimer?.cancel();
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _errorMessage = 'Generation failed: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgDark = Color(0xFF0D1F17);
    const surfaceDark = Color(0xFF142B20);
    const emerald = Color(0xFF10B981);
    const gold = Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: surfaceDark,
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
            // Prompt & Preference Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: emerald.withValues(alpha: 0.2)),
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
                                child: CircularProgressIndicator(strokeWidth: 2, color: emerald),
                              )
                            : const Icon(Icons.auto_awesome, size: 14, color: emerald),
                        label: const Text(
                          'Extract Intent',
                          style: TextStyle(fontSize: 11, color: emerald, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    key: const Key('ai_prompt_input'),
                    controller: _promptController,
                    maxLines: 3,
                    style: const TextStyle(fontSize: 13, color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: bgDark,
                      hintText: 'e.g., 6 days luxury Kerala trip with my wife in June, budget ₹80,000...',
                      hintStyle: const TextStyle(fontSize: 12, color: Colors.white38),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Extracted Parameters Badges Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _monsoonMode ? const Color(0xFF0284C7).withValues(alpha: 0.2) : gold.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _monsoonMode ? const Color(0xFF38BDF8) : gold),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_monsoonMode ? Icons.water_drop : Icons.wb_sunny, size: 12, color: _monsoonMode ? const Color(0xFF38BDF8) : gold),
                              const SizedBox(width: 4),
                              Text(
                                _monsoonMode ? '$_month · Monsoon Safe' : '$_month · Peak Season',
                                style: TextStyle(
                                  color: _monsoonMode ? const Color(0xFF38BDF8) : gold,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: emerald.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: emerald.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            '$_adults Travelers',
                            style: const TextStyle(color: emerald, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: bgDark,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Text(
                            'Budget: ₹${_estimatedBudget.toInt()}',
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Duration Slider
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
                          color: gold,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _durationDays,
                    min: 2,
                    max: 10,
                    divisions: 8,
                    activeColor: emerald,
                    inactiveColor: Colors.white10,
                    onChanged: (v) => setState(() => _durationDays = v),
                  ),

                  // Travel Style Selector
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
                              color: selected ? emerald : bgDark,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected ? emerald : Colors.white12,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                style,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: selected ? bgDark : Colors.white70,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  // Extracted Interests Chips
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _interests.map((interest) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: bgDark,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: emerald.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          '#$interest',
                          style: const TextStyle(color: emerald, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

                  // Action Button
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
                        backgroundColor: gold,
                        foregroundColor: const Color(0xFF144032),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Progress Stages Animation (mirrors high-fidelity web AIGenerationScreen)
            if (_isGenerating) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surfaceDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: gold.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: gold, size: 16),
                        const SizedBox(width: 8),
                        const Text(
                          'KeraLink Deterministic Synthesis',
                          style: TextStyle(color: gold, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Text(
                          '${((_progressStepIndex + 1) / _generationSteps.length * 100).toInt()}%',
                          style: const TextStyle(color: emerald, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: (_progressStepIndex + 1) / _generationSteps.length,
                      backgroundColor: Colors.white10,
                      valueColor: const AlwaysStoppedAnimation<Color>(emerald),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 14),
                    ...List.generate(_generationSteps.length, (idx) {
                      final isDone = idx < _progressStepIndex;
                      final isCurrent = idx == _progressStepIndex;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3.0),
                        child: Row(
                          children: [
                            if (isDone)
                              const Icon(Icons.check_circle, size: 14, color: emerald)
                            else if (isCurrent)
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: gold),
                              )
                            else
                              const Icon(Icons.radio_button_unchecked, size: 14, color: Colors.white24),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _generationSteps[idx],
                                style: TextStyle(
                                  color: isDone || isCurrent ? Colors.white : Colors.white38,
                                  fontSize: 11,
                                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                ),
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

            // Error Display
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

            // Generated Plan Preview
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: emerald.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: emerald),
                        ),
                        child: Text(
                          'Score ${_generatedPlan!.validation.score}/100',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: emerald,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: gold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: gold),
                        ),
                        child: Text(
                          'Eco ${_generatedPlan!.greenTripScore}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: gold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surfaceDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: gold.withValues(alpha: 0.3)),
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
                          '${_generatedPlan!.durationDays} Days · ${_generatedPlan!.travelStyle}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFFC5D8CD)),
                        ),
                        Text(
                          '₹${_generatedPlan!.pricing.total.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: gold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Corridor route chips
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: _generatedPlan!.corridorRoute.map((c) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: bgDark,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Text(c, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                        );
                      }).toList(),
                    ),
                    const Divider(color: Colors.white12, height: 24),

                    // Authoritative pricing breakdown summary
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: bgDark,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Stays & Heritage Resorts:', style: TextStyle(color: Colors.white60, fontSize: 11)),
                              Text('₹${_generatedPlan!.pricing.staysSubtotal.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Curated Experiences:', style: TextStyle(color: Colors.white60, fontSize: 11)),
                              Text('₹${_generatedPlan!.pricing.experiencesSubtotal.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Dedicated Transport (Sedan):', style: TextStyle(color: Colors.white60, fontSize: 11)),
                              Text('₹${_generatedPlan!.pricing.transportSubtotal.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Taxes & GST (5%):', style: TextStyle(color: Colors.white60, fontSize: 11)),
                              Text('₹${_generatedPlan!.pricing.gstAmount.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Days Preview List
                    ..._generatedPlan!.days.take(3).map((d) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: emerald.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Day ${d.dayNumber}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: emerald,
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

                    // Handover Button to Phase 5 Itinerary Builder
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        key: const Key('ai_view_details_btn'),
                        icon: const Icon(Icons.tune, size: 18),
                        label: const Text('Open Day-by-Day Itinerary Builder'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: emerald,
                          foregroundColor: const Color(0xFF0D1F17),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          textStyle: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (ctx) => ItineraryBuilderScreen(
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

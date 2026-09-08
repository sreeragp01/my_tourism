import 'package:flutter/material.dart';
import '../data/experience_repository.dart';
import '../models/experience_model.dart';
import '../../maps/presentation/live_map_screen.dart';

class ExploreKeralaScreen extends StatefulWidget {
  final ExperienceRepository experienceRepository;

  const ExploreKeralaScreen({
    super.key,
    required this.experienceRepository,
  });

  @override
  State<ExploreKeralaScreen> createState() => _ExploreKeralaScreenState();
}

class _ExploreKeralaScreenState extends State<ExploreKeralaScreen> {
  String _selectedCategory = 'ALL';
  String? _selectedDestination;
  bool _rainFriendlyOnly = false;

  bool _isLoading = true;
  String? _errorMessage;
  List<Experience> _experiences = [];

  final List<Map<String, String>> _categories = [
    {'id': 'ALL', 'label': 'All'},
    {'id': 'CULTURE', 'label': 'Culture 🪔'},
    {'id': 'WATER', 'label': 'Water 🛶'},
    {'id': 'NATURE', 'label': 'Nature 🌿'},
    {'id': 'FOOD', 'label': 'Food 🍛'},
  ];

  @override
  void initState() {
    super.initState();
    _loadExperiences();
  }

  Future<void> _loadExperiences() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await widget.experienceRepository.getExperiences(
        destination: _selectedDestination,
        category: _selectedCategory,
        rainFriendly: _rainFriendlyOnly ? true : null,
      );
      if (!mounted) return;
      setState(() {
        _experiences = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to load experiences. Please check your connection.';
        _isLoading = false;
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
          'Explore Kerala',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFF7F3E8)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined, color: Color(0xFF10B981)),
            tooltip: 'Live Corridor Map',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LiveMapScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFF142B20),
            child: Column(
              children: [
                // Category Chips
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final selected = _selectedCategory == cat['id'];
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedCategory = cat['id']!);
                          _loadExperiences();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected ? const Color(0xFF10B981) : const Color(0xFF0D1F17),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: selected ? const Color(0xFF10B981) : Colors.white12,
                            ),
                          ),
                          child: Text(
                            cat['label']!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: selected ? const Color(0xFF0D1F17) : Colors.white70,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                // Monsoon / Rain Friendly Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.umbrella_outlined, color: Color(0xFFD4AF37), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Monsoon Safe (Sheltered)',
                          style: TextStyle(
                            fontSize: 12,
                            color: _rainFriendlyOnly ? const Color(0xFFD4AF37) : Colors.white70,
                            fontWeight: _rainFriendlyOnly ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: _rainFriendlyOnly,
                      activeThumbColor: const Color(0xFFD4AF37),
                      activeTrackColor: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                      inactiveThumbColor: Colors.white38,
                      inactiveTrackColor: Colors.white10,
                      onChanged: (v) {
                        setState(() => _rainFriendlyOnly = v);
                        _loadExperiences();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Experience List Body
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_outlined, color: Color(0xFFE11D48), size: 48),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFC5D8CD), fontSize: 13),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadExperiences,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF142B20),
                  foregroundColor: const Color(0xFFF7F3E8),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_experiences.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🛶', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            const Text(
              'No experiences found for this filter',
              style: TextStyle(color: Color(0xFFF7F3E8), fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try changing category or turning off Monsoon Safe mode',
              style: TextStyle(color: Color(0xFFC5D8CD), fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedCategory = 'ALL';
                  _rainFriendlyOnly = false;
                });
                _loadExperiences();
              },
              child: const Text('Reset Filters', style: TextStyle(color: Color(0xFFD4AF37))),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _experiences.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final exp = _experiences[index];
        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFF142B20),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Image.network(
                    exp.heroImage,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 160,
                      color: const Color(0xFF1C3A2D),
                      child: const Icon(Icons.photo, size: 40, color: Colors.white24),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF144032).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        exp.category,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD4AF37),
                        ),
                      ),
                    ),
                  ),
                  if (exp.rainFriendly)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.umbrella, size: 12, color: Color(0xFF0D1F17)),
                            SizedBox(width: 4),
                            Text(
                              'RAIN SAFE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0D1F17),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.star, size: 14, color: Color(0xFFD4AF37)),
                            const SizedBox(width: 4),
                            Text(
                              '${exp.rating}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              ' (${exp.reviewCount})',
                              style: const TextStyle(fontSize: 11, color: Colors.white38),
                            ),
                          ],
                        ),
                        Text(
                          '₹${exp.pricePerPerson.toInt()}/person',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD4AF37),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      exp.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      exp.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Color(0xFFC5D8CD)),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 14, color: Color(0xFF10B981)),
                        const SizedBox(width: 6),
                        Text(
                          '${exp.hostName} • ${exp.hostRole}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF10B981)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

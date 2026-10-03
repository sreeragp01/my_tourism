import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/map_models.dart';
import '../data/map_repository.dart';

class NearbyExperiencesScreen extends StatefulWidget {
  final IMapRepository? repository;
  final double currentLat;
  final double currentLon;

  const NearbyExperiencesScreen({
    super.key,
    this.repository,
    this.currentLat = 10.0889,
    this.currentLon = 77.0595,
  });

  @override
  State<NearbyExperiencesScreen> createState() => _NearbyExperiencesScreenState();
}

class _NearbyExperiencesScreenState extends State<NearbyExperiencesScreen> {
  String _selectedCategory = 'ALL';
  List<NearbyPlace> _places = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNearby();
  }

  Future<void> _loadNearby() async {
    setState(() => _isLoading = true);
    if (widget.repository != null) {
      try {
        final category = _selectedCategory == 'ALL' ? null : _selectedCategory;
        final results = await widget.repository!.getNearby(
          lat: widget.currentLat,
          lon: widget.currentLon,
          category: category,
        );
        if (mounted) {
          setState(() {
            _places = results;
            _isLoading = false;
          });
          return;
        }
      } catch (_) {}
    }

    // High quality curated fallbacks
    if (mounted) {
      final allFallback = [
        const NearbyPlace(
          id: 'exp_lockhart_tea',
          title: 'Lockhart Estate Orthodox Tea Tasting & Factory Cupping',
          type: 'EXPERIENCE',
          category: 'CULTURE',
          distanceKm: 1.2,
          latitude: 10.0889,
          longitude: 77.0595,
          rainFriendly: true,
          rating: 4.95,
          pricePerPerson: 1200.0,
          meetingPoint: 'Lockhart Plantation Main Gate',
        ),
        const NearbyPlace(
          id: 'attr_cheeyappara',
          title: 'Cheeyappara Waterfalls Cascade Overlook',
          type: 'ATTRACTION',
          category: 'NATURE',
          distanceKm: 8.5,
          latitude: 10.0315,
          longitude: 76.8824,
          rainFriendly: false,
          rating: 4.7,
        ),
        const NearbyPlace(
          id: 'exp_spice_trail',
          title: 'Highland Organic Spice Trail & Vanilla Plantation Walk',
          type: 'EXPERIENCE',
          category: 'CULTURE',
          distanceKm: 3.4,
          latitude: 10.0750,
          longitude: 77.0420,
          rainFriendly: true,
          rating: 4.88,
          pricePerPerson: 850.0,
          meetingPoint: 'Green Valley Spice Gardens Adimali',
        ),
        const NearbyPlace(
          id: 'food_rapsy',
          title: 'Rapsy Restaurant - Malabar Parotta & Beef Fry',
          type: 'FOOD',
          category: 'FOOD',
          distanceKm: 1.8,
          latitude: 10.0850,
          longitude: 77.0620,
          rainFriendly: true,
          rating: 4.8,
        ),
      ];

      setState(() {
        if (_selectedCategory == 'ALL') {
          _places = allFallback;
        } else {
          _places = allFallback.where((p) => p.category == _selectedCategory).toList();
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const categories = ['ALL', 'CULTURE', 'NATURE', 'FOOD'];

    return Scaffold(
      backgroundColor: AppTheme.midnightTeal,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceTeal,
        elevation: 0,
        title: const Text(
          'Nearby Spots & Experiences',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textCream),
        ),
      ),
      body: Column(
        children: [
          // Filter Chips Row
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = _selectedCategory == cat;
                return ChoiceChip(
                  key: Key('category_chip_$cat'),
                  label: Text(
                    cat,
                    style: TextStyle(
                      color: isSelected ? AppTheme.midnightTeal : AppTheme.textMuted,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppTheme.oceanTeal,
                  backgroundColor: AppTheme.surfaceTeal,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedCategory = cat);
                      _loadNearby();
                    }
                  },
                );
              },
            ),
          ),

          // Content List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.oceanTeal))
                : _places.isEmpty
                    ? const Center(
                        child: Text(
                          'No nearby activities in this category.',
                          style: TextStyle(color: AppTheme.textMuted),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _places.length,
                        itemBuilder: (context, index) {
                          final place = _places[index];
                          return Card(
                            key: Key('nearby_card_${place.id}'),
                            color: AppTheme.surfaceTeal,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: const BorderSide(color: AppTheme.borderTeal),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.midnightTeal,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: AppTheme.borderTeal),
                                        ),
                                        child: Text(
                                          place.category,
                                          style: const TextStyle(color: AppTheme.oceanTeal, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          const Icon(Icons.near_me_outlined, size: 14, color: AppTheme.textMuted),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${place.distanceKm} km away',
                                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    place.title,
                                    style: const TextStyle(
                                      color: AppTheme.textCream,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.star, color: AppTheme.sunsetGold, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        place.rating.toString(),
                                        style: const TextStyle(color: AppTheme.textCream, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(width: 12),
                                      if (place.rainFriendly)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.oceanTeal.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: AppTheme.oceanTeal.withValues(alpha: 0.3)),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.umbrella_outlined, size: 12, color: AppTheme.oceanTeal),
                                              SizedBox(width: 4),
                                              Text(
                                                'Rain-Friendly',
                                                style: TextStyle(color: AppTheme.oceanTeal, fontSize: 10, fontWeight: FontWeight.w600),
                                              ),
                                            ],
                                          ),
                                        ),
                                      const Spacer(),
                                      if (place.pricePerPerson != null)
                                        Text(
                                          '₹${place.pricePerPerson!.toInt()}/person',
                                          style: const TextStyle(
                                            color: AppTheme.sunsetGold,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

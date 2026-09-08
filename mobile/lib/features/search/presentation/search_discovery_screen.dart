import 'dart:async';
import 'package:flutter/material.dart';
import '../models/search_result_model.dart';
import '../data/search_repository.dart';
import '../../home/models/destination_model.dart';
import '../../home/presentation/destination_details_screen.dart';
import '../../explore/models/experience_model.dart';
import '../../explore/models/accommodation_model.dart';

class SearchDiscoveryScreen extends StatefulWidget {
  final SearchRepository searchRepository;
  final String initialQuery;
  final String? initialCategory;

  const SearchDiscoveryScreen({
    super.key,
    required this.searchRepository,
    this.initialQuery = '',
    this.initialCategory,
  });

  @override
  State<SearchDiscoveryScreen> createState() => _SearchDiscoveryScreenState();
}

class _SearchDiscoveryScreenState extends State<SearchDiscoveryScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _searchController;
  late final TabController _tabController;
  Timer? _debounceTimer;

  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  SearchResults _results = SearchResults.empty();

  String _selectedCategory = 'ALL';
  bool? _rainFriendly;
  bool? _familyFriendly;
  double? _maxPrice;

  // Geographic Radius Filter
  String? _selectedGeoHub;
  double? _selectedLat;
  double? _selectedLng;
  double? _selectedRadiusKm;

  static const Map<String, Map<String, double>> _keralaHubs = {
    'Munnar': {'lat': 10.0889, 'lng': 77.0595},
    'Kochi': {'lat': 9.9312, 'lng': 76.2673},
    'Alleppey': {'lat': 9.4981, 'lng': 76.3388},
    'Wayanad': {'lat': 11.6854, 'lng': 76.1320},
    'Varkala': {'lat': 8.7379, 'lng': 76.7163},
  };

  final List<String> _categories = [
    'ALL',
    'NATURE',
    'CULTURE',
    'WATER',
    'FOOD',
    'ADVENTURE',
    'STAYS',
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _selectedCategory = widget.initialCategory ?? 'ALL';
    _tabController = TabController(length: 5, vsync: this);
    _performSearch();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _performSearch();
    });
  }

  Future<void> _performSearch() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final filter = SearchFilter(
      query: _searchController.text.trim(),
      category: _selectedCategory == 'ALL' ? null : _selectedCategory,
      rainFriendly: _rainFriendly,
      familyFriendly: _familyFriendly,
      maxPrice: _maxPrice,
      lat: _selectedLat,
      lng: _selectedLng,
      radiusKm: _selectedRadiusKm,
      page: 1,
      pageSize: 20,
    );

    try {
      final results = await widget.searchRepository.search(filter);
      if (!mounted) return;
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not load search results. Check network or tap retry.';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_results.hasNext) return;
    setState(() => _isLoadingMore = true);

    final nextPage = _results.page + 1;
    final filter = SearchFilter(
      query: _searchController.text.trim(),
      category: _selectedCategory == 'ALL' ? null : _selectedCategory,
      rainFriendly: _rainFriendly,
      familyFriendly: _familyFriendly,
      maxPrice: _maxPrice,
      lat: _selectedLat,
      lng: _selectedLng,
      radiusKm: _selectedRadiusKm,
      page: nextPage,
      pageSize: 20,
    );

    try {
      final moreResults = await widget.searchRepository.search(filter);
      if (!mounted) return;
      setState(() {
        _results = _results.append(moreResults);
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  void _showRadiusFilterModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF142B20),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String? tempHub = _selectedGeoHub;
        double tempRadius = _selectedRadiusKm ?? 25.0;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Geographic Proximity & Radius',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      if (tempHub != null)
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              tempHub = null;
                            });
                          },
                          child: const Text('Reset', style: TextStyle(color: Color(0xFFE11D48), fontSize: 13)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select a Kerala tourism hub to filter destinations, stays, and activities by radius:',
                    style: TextStyle(color: Color(0xFF8BA699), fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _keralaHubs.keys.map((hub) {
                      final isSelected = tempHub == hub;
                      return ChoiceChip(
                        selected: isSelected,
                        label: Text(hub),
                        selectedColor: const Color(0xFF10B981),
                        backgroundColor: const Color(0xFF0D1F17),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFFC5D8CD),
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (selected) {
                          setModalState(() {
                            tempHub = selected ? hub : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Radius Distance:', style: TextStyle(color: Colors.white, fontSize: 13)),
                      Text('${tempRadius.toInt()} km', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  Slider(
                    value: tempRadius,
                    min: 10,
                    max: 100,
                    divisions: 9,
                    activeColor: const Color(0xFF10B981),
                    inactiveColor: Colors.white12,
                    onChanged: tempHub == null
                        ? null
                        : (val) {
                            setModalState(() => tempRadius = val);
                          },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        setState(() {
                          _selectedGeoHub = tempHub;
                          if (tempHub != null) {
                            final coords = _keralaHubs[tempHub!];
                            _selectedLat = coords?['lat'];
                            _selectedLng = coords?['lng'];
                            _selectedRadiusKm = tempRadius;
                          } else {
                            _selectedLat = null;
                            _selectedLng = null;
                            _selectedRadiusKm = null;
                          }
                        });
                        _performSearch();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Apply Location Filter', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showExperienceDetail(BuildContext context, Experience exp) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF142B20),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      exp.heroImage,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 200,
                        color: const Color(0xFF1F3D2F),
                        child: const Icon(Icons.local_activity, color: Colors.white54, size: 48),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          exp.category,
                          style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (exp.rainFriendly) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.water_drop, size: 12, color: Color(0xFF38BDF8)),
                              SizedBox(width: 4),
                              Text('Monsoon Safe', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    exp.title,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Color(0xFFD4AF37), size: 16),
                      const SizedBox(width: 4),
                      Text('${exp.rating}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text(' (${exp.reviewCount} reviews)', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      const Spacer(),
                      Text('₹${exp.pricePerPerson.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFF10B981), fontSize: 20, fontWeight: FontWeight.bold)),
                      const Text(' / person', style: TextStyle(color: Colors.white60, fontSize: 12)),
                    ],
                  ),
                  const Divider(color: Colors.white12, height: 28),
                  const Text('About Experience', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),
                  Text(exp.description, style: const TextStyle(color: Color(0xFFC5D8CD), fontSize: 13, height: 1.5)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.schedule, color: Color(0xFF10B981), size: 16),
                      const SizedBox(width: 6),
                      Text('Duration: ${exp.durationHours} hours', style: const TextStyle(color: Colors.white, fontSize: 13)),
                      const SizedBox(width: 20),
                      const Icon(Icons.group, color: Color(0xFF10B981), size: 16),
                      const SizedBox(width: 6),
                      Text('Max ${exp.maxGroupSize} guests', style: const TextStyle(color: Colors.white, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFFD4AF37), size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Meeting Point: ${exp.meetingPoint}',
                          style: const TextStyle(color: Color(0xFFC5D8CD), fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.person, color: Color(0xFF10B981), size: 16),
                      const SizedBox(width: 6),
                      Text('Host: ${exp.hostName} (${exp.hostRole})', style: const TextStyle(color: Colors.white, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Selected "${exp.title}" — ready for Itinerary Builder (Wave B)'),
                            backgroundColor: const Color(0xFF10B981),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Explore & Add to Trip', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAccommodationDetail(BuildContext context, Accommodation acc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF142B20),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      acc.heroImage,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 200,
                        color: const Color(0xFF1F3D2F),
                        child: const Icon(Icons.hotel, color: Colors.white54, size: 48),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          acc.type.replaceAll('_', ' '),
                          style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.eco, size: 13, color: Color(0xFFD4AF37)),
                            const SizedBox(width: 4),
                            Text('Eco Score: ${acc.ecoGreenScore}/100', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    acc.name,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    acc.tagline,
                    style: const TextStyle(color: Color(0xFF8BA699), fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ...List.generate(
                        acc.starRating,
                        (_) => const Icon(Icons.star, color: Color(0xFFD4AF37), size: 16),
                      ),
                      const SizedBox(width: 8),
                      Text('${acc.starRating} Star Rated', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      const Spacer(),
                      Text('₹${acc.basePricePerNight.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 20, fontWeight: FontWeight.bold)),
                      const Text(' / night', style: TextStyle(color: Colors.white60, fontSize: 12)),
                    ],
                  ),
                  const Divider(color: Colors.white12, height: 28),
                  const Text('Description', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),
                  Text(acc.description, style: const TextStyle(color: Color(0xFFC5D8CD), fontSize: 13, height: 1.5)),
                  if (acc.amenities.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('Amenities & Highlights', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: acc.amenities.map((amenity) {
                        return Chip(
                          label: Text(amenity, style: const TextStyle(color: Colors.white, fontSize: 11)),
                          backgroundColor: const Color(0xFF0D1F17),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          side: const BorderSide(color: Colors.white12),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Selected "${acc.name}" — ready for Itinerary Builder (Wave B)'),
                            backgroundColor: const Color(0xFF10B981),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('View Rooms & Select Stay', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAttractionDetail(BuildContext context, Attraction att) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF142B20),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      att.image,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 200,
                        color: const Color(0xFF1F3D2F),
                        child: const Icon(Icons.photo_camera, color: Colors.white54, size: 48),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          att.category,
                          style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (att.rainFriendly) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.water_drop, size: 12, color: Color(0xFF38BDF8)),
                              SizedBox(width: 4),
                              Text('Monsoon Safe', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    att.name,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.schedule, color: Color(0xFF10B981), size: 16),
                      const SizedBox(width: 6),
                      Text('${att.openingTime} - ${att.closingTime}', style: const TextStyle(color: Colors.white, fontSize: 13)),
                      const Spacer(),
                      Text(
                        att.entryFee > 0 ? '₹${att.entryFee.toStringAsFixed(0)} entry' : 'Free Entry',
                        style: const TextStyle(color: Color(0xFF10B981), fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white12, height: 28),
                  const Text('Overview', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),
                  Text(att.description, style: const TextStyle(color: Color(0xFFC5D8CD), fontSize: 13, height: 1.5)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, color: Color(0xFFD4AF37), size: 16),
                      const SizedBox(width: 6),
                      Text('Typical Duration: ${att.typicalDurationMins} mins', style: const TextStyle(color: Colors.white, fontSize: 13)),
                      const SizedBox(width: 16),
                      const Icon(Icons.people_outline, color: Color(0xFFD4AF37), size: 16),
                      const SizedBox(width: 6),
                      Text('Crowd: ${att.crowdProfile}', style: const TextStyle(color: Colors.white, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added "${att.name}" to trip destination bucket'),
                            backgroundColor: const Color(0xFF10B981),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Add to Itinerary', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search destinations, stays, experiences...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: emerald, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(98),
          child: Column(
            children: [
              // Filter Chips Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    // Location & Radius Chip
                    FilterChip(
                      selected: _selectedGeoHub != null,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.near_me,
                            size: 14,
                            color: _selectedGeoHub != null ? Colors.white : emerald,
                          ),
                          const SizedBox(width: 4),
                          Text(_selectedGeoHub != null ? '$_selectedGeoHub (${_selectedRadiusKm?.toInt() ?? 25}km)' : 'Radius / Hub'),
                        ],
                      ),
                      selectedColor: emerald,
                      backgroundColor: surfaceDark,
                      labelStyle: TextStyle(
                        color: _selectedGeoHub != null ? Colors.white : const Color(0xFFC5D8CD),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) => _showRadiusFilterModal(),
                    ),
                    const SizedBox(width: 8),

                    // Monsoon Friendly Toggle
                    FilterChip(
                      selected: _rainFriendly == true,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.water_drop,
                            size: 14,
                            color: _rainFriendly == true ? Colors.white : const Color(0xFF38BDF8),
                          ),
                          const SizedBox(width: 4),
                          const Text('Monsoon Safe'),
                        ],
                      ),
                      selectedColor: const Color(0xFF0284C7),
                      backgroundColor: surfaceDark,
                      labelStyle: TextStyle(
                        color: _rainFriendly == true ? Colors.white : const Color(0xFFC5D8CD),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (val) {
                        setState(() => _rainFriendly = val ? true : null);
                        _performSearch();
                      },
                    ),
                    const SizedBox(width: 8),

                    // Family Friendly Toggle
                    FilterChip(
                      selected: _familyFriendly == true,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.family_restroom,
                            size: 14,
                            color: _familyFriendly == true ? Colors.white : gold,
                          ),
                          const SizedBox(width: 4),
                          const Text('Family Friendly'),
                        ],
                      ),
                      selectedColor: gold.withValues(alpha: 0.8),
                      backgroundColor: surfaceDark,
                      labelStyle: TextStyle(
                        color: _familyFriendly == true ? Colors.black87 : const Color(0xFFC5D8CD),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (val) {
                        setState(() => _familyFriendly = val ? true : null);
                        _performSearch();
                      },
                    ),
                    const SizedBox(width: 8),

                    // Category Chips
                    ..._categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: ChoiceChip(
                          selected: isSelected,
                          label: Text(cat == 'ALL' ? 'All Types' : cat),
                          selectedColor: emerald,
                          backgroundColor: surfaceDark,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : const Color(0xFFC5D8CD),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (_) {
                            setState(() => _selectedCategory = cat);
                            _performSearch();
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),

              // Tab Bar for categorized counts
              TabBar(
                controller: _tabController,
                indicatorColor: emerald,
                indicatorWeight: 3,
                labelColor: emerald,
                unselectedLabelColor: Colors.white60,
                labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                isScrollable: true,
                tabs: [
                  Tab(text: 'All (${_results.totalCount})'),
                  Tab(text: 'Destinations (${_results.destinations.length})'),
                  Tab(text: 'Experiences (${_results.experiences.length})'),
                  Tab(text: 'Stays (${_results.accommodations.length})'),
                  Tab(text: 'Attractions (${_results.attractions.length})'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF10B981)),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Color(0xFFE11D48), size: 48),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFC5D8CD), fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _performSearch,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry Search'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off, color: Colors.white38, size: 56),
              const SizedBox(height: 12),
              const Text(
                'No matching tourism experiences found',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Try searching for "Munnar", "Tea", "Kayaking", or toggle off Monsoon Safe to see all activities.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF8BA699), fontSize: 13),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _selectedCategory = 'ALL';
                    _rainFriendly = null;
                    _familyFriendly = null;
                    _selectedGeoHub = null;
                    _selectedLat = null;
                    _selectedLng = null;
                    _selectedRadiusKm = null;
                  });
                  _performSearch();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF142B20),
                  foregroundColor: const Color(0xFF10B981),
                ),
                child: const Text('Reset All Filters'),
              ),
            ],
          ),
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildAllTab(),
        _buildDestinationsList(_results.destinations),
        _buildExperiencesList(_results.experiences),
        _buildAccommodationsList(_results.accommodations),
        _buildAttractionsList(_results.attractions),
      ],
    );
  }

  Widget _buildAllTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        if (_results.destinations.isNotEmpty) ...[
          _buildSectionHeader('Destinations', _results.destinations.length, 1),
          _buildDestinationsList(_results.destinations, shrinkWrap: true),
        ],
        if (_results.experiences.isNotEmpty) ...[
          _buildSectionHeader('Curated Experiences', _results.experiences.length, 2),
          _buildExperiencesList(_results.experiences, shrinkWrap: true),
        ],
        if (_results.accommodations.isNotEmpty) ...[
          _buildSectionHeader('Heritage Stays & Resorts', _results.accommodations.length, 3),
          _buildAccommodationsList(_results.accommodations, shrinkWrap: true),
        ],
        if (_results.attractions.isNotEmpty) ...[
          _buildSectionHeader('Attractions & Sights', _results.attractions.length, 4),
          _buildAttractionsList(_results.attractions, shrinkWrap: true),
        ],
        if (_results.hasNext) _buildLoadMoreWidget(),
      ],
    );
  }

  Widget _buildLoadMoreWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Center(
        child: _isLoadingMore
            ? const CircularProgressIndicator(color: Color(0xFF10B981))
            : OutlinedButton.icon(
                onPressed: _loadMore,
                icon: const Icon(Icons.arrow_downward, size: 16),
                label: const Text('Load More Results'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF10B981),
                  side: const BorderSide(color: Color(0xFF10B981)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count, int tabIndex) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$title ($count)',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          InkWell(
            onTap: () => _tabController.animateTo(tabIndex),
            child: const Text(
              'See All',
              style: TextStyle(
                color: Color(0xFF10B981),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationsList(List<Destination> list, {bool shrinkWrap = false}) {
    if (list.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No destinations match this criteria.', style: TextStyle(color: Colors.white54)),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: list.length + (!shrinkWrap && _results.hasNext ? 1 : 0),
      itemBuilder: (ctx, idx) {
        if (idx == list.length) {
          return _buildLoadMoreWidget();
        }
        final d = list[idx];
        return Card(
          color: const Color(0xFF142B20),
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => DestinationDetailsScreen(destination: d)),
              );
            },
            child: Row(
              children: [
                Image.network(
                  d.heroImage,
                  width: 100,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 100,
                    height: 90,
                    color: const Color(0xFF1F3D2F),
                    child: const Icon(Icons.landscape, color: Colors.white54),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              d.name,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            if (d.distanceKm != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${d.distanceKm!.toStringAsFixed(1)} km',
                                  style: const TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        Text(
                          d.district,
                          style: const TextStyle(color: Color(0xFF10B981), fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          d.tagline,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFFC5D8CD), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 12.0),
                  child: Icon(Icons.chevron_right, color: Colors.white38),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExperiencesList(List<Experience> list, {bool shrinkWrap = false}) {
    if (list.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No experiences match this criteria.', style: TextStyle(color: Colors.white54)),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: list.length + (!shrinkWrap && _results.hasNext ? 1 : 0),
      itemBuilder: (ctx, idx) {
        if (idx == list.length) {
          return _buildLoadMoreWidget();
        }
        final exp = list[idx];
        return Card(
          color: const Color(0xFF142B20),
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _showExperienceDetail(context, exp),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          exp.heroImage,
                          width: 80,
                          height: 75,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 80,
                            height: 75,
                            color: const Color(0xFF1F3D2F),
                            child: const Icon(Icons.local_activity, color: Colors.white54),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exp.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Color(0xFFD4AF37), size: 14),
                                const SizedBox(width: 4),
                                Text('${exp.rating}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                                const SizedBox(width: 8),
                                Text('${exp.durationHours}h duration', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (exp.rainFriendly)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.4)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.water_drop, size: 11, color: Color(0xFF38BDF8)),
                              SizedBox(width: 4),
                              Text('Monsoon Safe', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      else
                        const SizedBox.shrink(),
                      Text(
                        '₹${exp.pricePerPerson.toStringAsFixed(0)} / person',
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccommodationsList(List<Accommodation> list, {bool shrinkWrap = false}) {
    if (list.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No accommodations match this criteria.', style: TextStyle(color: Colors.white54)),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: list.length + (!shrinkWrap && _results.hasNext ? 1 : 0),
      itemBuilder: (ctx, idx) {
        if (idx == list.length) {
          return _buildLoadMoreWidget();
        }
        final acc = list[idx];
        return Card(
          color: const Color(0xFF142B20),
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _showAccommodationDetail(context, acc),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.network(
                  acc.heroImage,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 120,
                    color: const Color(0xFF1F3D2F),
                    child: const Icon(Icons.hotel, color: Colors.white54, size: 36),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              acc.name,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${acc.ecoGreenScore} Eco',
                              style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        acc.tagline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFFC5D8CD), fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            acc.type.replaceAll('_', ' '),
                            style: const TextStyle(color: Colors.white54, fontSize: 11),
                          ),
                          Text(
                            'From ₹${acc.basePricePerNight.toStringAsFixed(0)}/night',
                            style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttractionsList(List<Attraction> list, {bool shrinkWrap = false}) {
    if (list.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No attractions match this criteria.', style: TextStyle(color: Colors.white54)),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: list.length + (!shrinkWrap && _results.hasNext ? 1 : 0),
      itemBuilder: (ctx, idx) {
        if (idx == list.length) {
          return _buildLoadMoreWidget();
        }
        final att = list[idx];
        return Card(
          color: const Color(0xFF142B20),
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _showAttractionDetail(context, att),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      att.image,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 70,
                        height: 70,
                        color: const Color(0xFF1F3D2F),
                        child: const Icon(Icons.photo_camera, color: Colors.white54),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              att.name,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            if (att.distanceKm != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${att.distanceKm!.toStringAsFixed(1)} km',
                                  style: const TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        Text(
                          '${att.category} • ${att.openingTime} - ${att.closingTime}',
                          style: const TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (att.rainFriendly)
                              const Padding(
                                padding: EdgeInsets.only(right: 6.0),
                                child: Icon(Icons.water_drop, size: 12, color: Color(0xFF38BDF8)),
                              ),
                            Text(
                              att.entryFee > 0 ? 'Entry: ₹${att.entryFee.toStringAsFixed(0)}' : 'Free Entry',
                              style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

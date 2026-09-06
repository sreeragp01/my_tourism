import 'package:flutter/material.dart';
import '../data/destination_repository.dart';
import '../models/destination_model.dart';
import 'destination_details_screen.dart';

class HomeDiscoverScreen extends StatefulWidget {
  final String userName;
  final VoidCallback onOpenPlanner;
  final VoidCallback onOpenCompanion;
  final VoidCallback? onLogout;
  final DestinationRepository destinationRepository;

  const HomeDiscoverScreen({
    super.key,
    this.userName = 'Sreerag',
    required this.onOpenPlanner,
    required this.onOpenCompanion,
    this.onLogout,
    required this.destinationRepository,
  });

  @override
  State<HomeDiscoverScreen> createState() => _HomeDiscoverScreenState();
}

class _HomeDiscoverScreenState extends State<HomeDiscoverScreen> {
  String _searchQuery = '';
  String? _selectedCategory;
  bool _isLoading = true;
  String? _errorMessage;
  List<Destination> _destinations = [];

  final List<Map<String, String>> _categories = [
    {'id': 'ALL', 'label': 'All', 'icon': '🌴'},
    {'id': 'Hills', 'label': 'Hills', 'icon': '⛰️'},
    {'id': 'Backwaters', 'label': 'Backwaters', 'icon': '🛶'},
    {'id': 'Culture', 'label': 'Culture', 'icon': '🪔'},
    {'id': 'Beaches', 'label': 'Beaches', 'icon': '🏖️'},
    {'id': 'Wildlife', 'label': 'Wildlife', 'icon': '🐘'},
  ];

  @override
  void initState() {
    super.initState();
    _loadDestinations();
  }

  Future<void> _loadDestinations({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await widget.destinationRepository.getDestinations(forceRefresh: forceRefresh);
      if (!mounted) return;
      setState(() {
        _destinations = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to load destinations. Check your connection.';
        _isLoading = false;
      });
    }
  }

  List<Destination> get _filteredDestinations {
    var result = _destinations;
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((d) {
        return d.name.toLowerCase().contains(q) ||
            d.district.toLowerCase().contains(q) ||
            d.tagline.toLowerCase().contains(q);
      }).toList();
    }
    if (_selectedCategory != null && _selectedCategory != 'ALL') {
      result = result.where((d) => d.tags.contains(_selectedCategory)).toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1F17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF142B20),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good morning, ${widget.userName} 🌴',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF7F3E8),
              ),
            ),
            Text(
              'Explore God\'s Own Country',
              style: TextStyle(
                fontSize: 12,
                color: const Color(0xFFC5D8CD).withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.forum_outlined, color: Color(0xFF10B981)),
            tooltip: 'Live Companion',
            onPressed: widget.onOpenCompanion,
          ),
          if (widget.onLogout != null)
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.white70, size: 20),
              tooltip: 'Sign Out',
              onPressed: widget.onLogout,
            ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFFD4AF37),
        backgroundColor: const Color(0xFF142B20),
        onRefresh: () => _loadDestinations(forceRefresh: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Smart Search Bar
              TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF142B20),
                  hintText: 'Search destinations (e.g. Munnar, Alleppey)...',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF10B981), size: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),

              const SizedBox(height: 18),

              // AI Planner Banner
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF144032), Color(0xFF0A1D19)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'AI TRAVEL ARCHITECT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD4AF37),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Plan your perfect\nKerala journey',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Monsoon-adaptive routes, authentic village homestays, and green scores.',
                      style: TextStyle(fontSize: 12, color: Color(0xFFC5D8CD)),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: widget.onOpenPlanner,
                      icon: const Icon(Icons.auto_awesome, size: 16),
                      label: const Text('Craft Itinerary'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        foregroundColor: const Color(0xFF144032),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Categories Chips
              const Text(
                'Explore by Interest',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF7F3E8),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final selected = _selectedCategory == cat['id'] || (_selectedCategory == null && cat['id'] == 'ALL');
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedCategory = cat['id']);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? const Color(0xFF10B981) : const Color(0xFF142B20),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected ? const Color(0xFF10B981) : const Color(0xFF10B981).withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(cat['icon']!, style: const TextStyle(fontSize: 13)),
                            const SizedBox(width: 6),
                            Text(
                              cat['label']!,
                              style: TextStyle(
                                fontSize: 12,
                                color: selected ? const Color(0xFF0D1F17) : const Color(0xFFF7F3E8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 28),

              // Featured Destinations Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Featured Destinations',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF7F3E8),
                    ),
                  ),
                  if (!_isLoading)
                    Text(
                      '${_filteredDestinations.length} Corridors',
                      style: const TextStyle(fontSize: 12, color: Color(0xFFD4AF37)),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Destination Content Body with States
              _buildDestinationList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDestinationList() {
    if (_isLoading) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFFD4AF37)),
            SizedBox(height: 12),
            Text(
              'Fetching live Kerala corridors from Django...',
              style: TextStyle(color: Color(0xFFC5D8CD), fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF142B20),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            const Icon(Icons.wifi_off, color: Color(0xFFE11D48), size: 36),
            const SizedBox(height: 10),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: () => _loadDestinations(forceRefresh: true),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry Connection'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: const Color(0xFF0D1F17),
              ),
            ),
          ],
        ),
      );
    }

    if (_filteredDestinations.isEmpty) {
      return Container(
        height: 140,
        alignment: Alignment.center,
        child: const Text(
          'No destinations match your search',
          style: TextStyle(color: Color(0xFFC5D8CD), fontSize: 13),
        ),
      );
    }

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: _filteredDestinations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final d = _filteredDestinations[index];
        final tag = d.tags.isNotEmpty ? d.tags.first : d.district;

        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DestinationDetailsScreen(
                  destination: d,
                  onPlanForDestination: widget.onOpenPlanner,
                ),
              ),
            );
          },
          child: Container(
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
                      d.heroImage,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 160,
                        color: const Color(0xFF1C3A2D),
                        child: const Icon(Icons.landscape, size: 40, color: Colors.white30),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF144032).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD4AF37),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${d.district} Dist.',
                          style: const TextStyle(fontSize: 10, color: Colors.white70),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              d.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              d.tagline,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFC5D8CD),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFD4AF37)),
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
}

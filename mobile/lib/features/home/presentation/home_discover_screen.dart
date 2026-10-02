import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../data/destination_repository.dart';
import '../models/destination_model.dart';
import 'destination_details_screen.dart';
import '../../search/data/search_repository.dart';
import '../../search/presentation/search_discovery_screen.dart';
import '../../maps/presentation/live_map_screen.dart';
import '../../packages/presentation/packages_screen.dart';
import '../../packages/data/package_repository.dart';
import '../../transport/presentation/cab_booking_screen.dart';
import '../../transport/data/transport_repository.dart';

class HomeDiscoverScreen extends StatefulWidget {
  final String userName;
  final VoidCallback onOpenPlanner;
  final VoidCallback onOpenCompanion;
  final VoidCallback? onOpenSafety;
  final VoidCallback? onOpenExplore;
  final VoidCallback? onLogout;
  final DestinationRepository destinationRepository;
  final SearchRepository? searchRepository;

  const HomeDiscoverScreen({
    super.key,
    this.userName = 'Sreerag',
    required this.onOpenPlanner,
    required this.onOpenCompanion,
    this.onOpenSafety,
    this.onOpenExplore,
    this.onLogout,
    required this.destinationRepository,
    this.searchRepository,
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

  final List<Map<String, String>> _categories = const [
    {'id': 'ALL', 'label': 'All Escapes', 'icon': '🌴'},
    {'id': 'Hills', 'label': 'Misty Hills', 'icon': '⛰️'},
    {'id': 'Backwaters', 'label': 'Backwaters', 'icon': '🛶'},
    {'id': 'Culture', 'label': 'Heritage', 'icon': '🪔'},
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
      final list = await widget.destinationRepository
          .getDestinations(forceRefresh: forceRefresh);
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

  void _openSearch([String initialQuery = '', String? initialCategory]) {
    final searchRepo = widget.searchRepository ??
        SearchRepository(apiClient: widget.destinationRepository.apiClient);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SearchDiscoveryScreen(
          searchRepository: searchRepo,
          initialQuery: initialQuery,
          initialCategory: initialCategory,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.midnightTeal,
      appBar: AppBar(
        backgroundColor: AppTheme.midnightTeal,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'KeraLink',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.sunsetGold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.oceanTeal.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppTheme.oceanTeal.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Text(
                    'KERALA',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.oceanTeal,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Where in Kerala are you exploring, ${widget.userName}?',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textMuted.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
        actions: [
          // Emergency SOS Shield Button in Top Bar
          IconButton(
            key: const Key('appbar_safety_btn'),
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.sunsetGold.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.sunsetGold.withValues(alpha: 0.5),
                ),
              ),
              child: const Icon(
                Icons.shield_rounded,
                color: AppTheme.sunsetGold,
                size: 18,
              ),
            ),
            tooltip: 'Emergency SOS & Safety Hub',
            onPressed: widget.onOpenSafety,
          ),
          if (widget.onLogout != null)
            IconButton(
              icon: const Icon(Icons.logout_rounded,
                  color: AppTheme.textMuted, size: 20),
              tooltip: 'Sign Out',
              onPressed: widget.onLogout,
            ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.oceanTeal,
        backgroundColor: AppTheme.surfaceTeal,
        onRefresh: () => _loadDestinations(forceRefresh: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Smart Travel Search Bar with Dates Pill
              _buildSmartSearchBar(),

              const SizedBox(height: 18),

              // Quick Service Hub (Clean 4-Pill Single Row)
              _buildQuickServiceHub(),

              const SizedBox(height: 22),

              // Featured Twilight Circuit Hero Card
              _buildFeaturedCircuitCard(),

              const SizedBox(height: 24),

              // Curated Collections Carousel
              _buildCuratedCollections(),

              const SizedBox(height: 24),

              // Categories Filter Chips
              _buildCategorySelector(),

              const SizedBox(height: 16),

              // Destination Cards Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Curated Destinations',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textCream,
                    ),
                  ),
                  if (!_isLoading)
                    Text(
                      '${_filteredDestinations.length} Corridors',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.sunsetGold),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Destination Content Body with States
              _buildDestinationList(),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmartSearchBar() {
    return Column(
      children: [
        TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          onSubmitted: (v) => _openSearch(v),
          style: const TextStyle(color: AppTheme.textCream, fontSize: 13),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.surfaceTeal,
            hintText: 'Where in Kerala do you want to go?',
            hintStyle:
                const TextStyle(color: AppTheme.textMuted, fontSize: 13),
            prefixIcon: IconButton(
              icon: const Icon(Icons.search,
                  color: AppTheme.oceanTeal, size: 20),
              onPressed: () => _openSearch(_searchQuery),
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.tune,
                  color: AppTheme.sunsetGold, size: 18),
              onPressed: () => _openSearch(_searchQuery),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppTheme.borderTeal),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppTheme.borderTeal),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  const BorderSide(color: AppTheme.oceanTeal, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 8),
        // Dates & Guests Filter Pill
        InkWell(
          onTap: widget.onOpenPlanner,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.sunsetGold.withValues(alpha: 0.3),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_month,
                    color: AppTheme.sunsetGold, size: 14),
                SizedBox(width: 6),
                Text(
                  'Nov 12 – 18  •  2 Travelers',
                  style: TextStyle(
                    color: AppTheme.textCream,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 6),
                Icon(Icons.keyboard_arrow_right,
                    color: AppTheme.sunsetGold, size: 14),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickServiceHub() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _ServiceButton(
          icon: Icons.auto_awesome,
          label: 'AI Itinerary',
          color: AppTheme.sunsetGold,
          onTap: widget.onOpenPlanner,
        ),
        _ServiceButton(
          icon: Icons.luggage_outlined,
          label: 'Tour Packages',
          color: AppTheme.oceanTeal,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PackagesScreen(
                  repository: PackageRepository(
                    apiClient: widget.destinationRepository.apiClient,
                  ),
                ),
              ),
            );
          },
        ),
        _ServiceButton(
          icon: Icons.local_taxi_outlined,
          label: 'Airport Cabs',
          color: AppTheme.sunsetCoral,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CabBookingScreen(
                  repository: TransportRepository(
                    apiClient: widget.destinationRepository.apiClient,
                  ),
                ),
              ),
            );
          },
        ),
        _ServiceButton(
          icon: Icons.map_outlined,
          label: 'Live Map',
          color: const Color(0xFF38BDF8),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LiveMapScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFeaturedCircuitCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceTeal,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.borderTeal,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Image Header with Badges
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    'https://images.unsplash.com/photo-1602216056096-3b40cc0c9944?auto=format&fit=crop&w=1200&q=80',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppTheme.surfaceElevated,
                      child: const Center(
                        child: Icon(Icons.sailing,
                            color: AppTheme.oceanTeal, size: 40),
                      ),
                    ),
                  ),
                ),
              ),
              // Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.2),
                        AppTheme.midnightTeal.withValues(alpha: 0.85),
                      ],
                    ),
                  ),
                ),
              ),
              // Best Seller Badge
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.sunsetGold,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'BEST SELLER',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              // Rating Badge
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.star, color: AppTheme.sunsetGold, size: 12),
                      SizedBox(width: 4),
                      Text(
                        '4.9 (128)',
                        style: TextStyle(
                          color: AppTheme.textCream,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Title & Price on Image
              const Positioned(
                bottom: 12,
                left: 14,
                right: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Backwater Sunset Cruise & Kayak',
                      style: TextStyle(
                        color: AppTheme.textCream,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            color: AppTheme.oceanTeal, size: 12),
                        SizedBox(width: 4),
                        Text(
                          'Alleppey • Punnamada Backwaters',
                          style: TextStyle(
                              color: AppTheme.textMuted, fontSize: 11),
                        ),
                        Spacer(),
                        Text(
                          'From ₹12,500',
                          style: TextStyle(
                            color: AppTheme.sunsetGold,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Route Milestone Dots
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const _RouteDot(label: 'Kochi', isStart: true),
                Expanded(
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.oceanTeal,
                          AppTheme.sunsetGold.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                  ),
                ),
                const _RouteDot(label: 'Munnar Hills'),
                Expanded(
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.sunsetGold.withValues(alpha: 0.6),
                          AppTheme.sunsetCoral,
                        ],
                      ),
                    ),
                  ),
                ),
                const _RouteDot(label: 'Alleppey', isEnd: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCuratedCollections() {
    final escapes = [
      {
        'title': 'Munnar Tea Hills',
        'tag': 'Misty Hills',
        'rating': '4.8 ★',
        'price': '₹4,500/night',
        'image':
            'https://images.unsplash.com/photo-1549399542-7e3f8b79c341?auto=format&fit=crop&w=600&q=80',
      },
      {
        'title': 'Varkala Red Cliff',
        'tag': 'Arabian Sea',
        'rating': '4.8 ★',
        'price': '₹3,200/night',
        'image':
            'https://images.unsplash.com/photo-1512343879784-a960bf40e7f2?auto=format&fit=crop&w=600&q=80',
      },
      {
        'title': 'Thekkady Jungle Safari',
        'tag': 'Periyar Wildlife',
        'rating': '4.7 ★',
        'price': '₹4,200/night',
        'image':
            'https://images.unsplash.com/photo-1544735716-392fe2489ffa?auto=format&fit=crop&w=600&q=80',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Popular Kerala Escapes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textCream,
              ),
            ),
            Text(
              'See All',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.oceanTeal,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: escapes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final e = escapes[index];
              return Container(
                width: 160,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceTeal,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderTeal),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              e['image']!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: AppTheme.surfaceElevated,
                                child: const Icon(Icons.landscape,
                                    color: AppTheme.oceanTeal),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  e['rating']!,
                                  style: const TextStyle(
                                    color: AppTheme.sunsetGold,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e['title']!,
                            style: const TextStyle(
                              color: AppTheme.textCream,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            e['price']!,
                            style: const TextStyle(
                              color: AppTheme.oceanTeal,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Explore by Interest',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textCream,
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
              final selected = _selectedCategory == cat['id'] ||
                  (_selectedCategory == null && cat['id'] == 'ALL');
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedCategory = cat['id']);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.oceanTeal
                        : AppTheme.surfaceTeal,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? AppTheme.oceanTeal
                          : AppTheme.borderTeal,
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
                          color: selected
                              ? AppTheme.midnightTeal
                              : AppTheme.textCream,
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
      ],
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
            CircularProgressIndicator(color: AppTheme.sunsetGold),
            SizedBox(height: 12),
            Text(
              'Fetching live Kerala corridors from Django...',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceTeal,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderTeal),
        ),
        child: Column(
          children: [
            const Icon(Icons.wifi_off, color: AppTheme.emergencyRed, size: 36),
            const SizedBox(height: 10),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textCream, fontSize: 13),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: () => _loadDestinations(forceRefresh: true),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry Connection'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.sunsetGold,
                foregroundColor: AppTheme.midnightTeal,
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
          style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceTeal,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.borderTeal),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 76,
                    height: 76,
                    child: d.heroImage.isNotEmpty
                        ? Image.network(
                            d.heroImage,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppTheme.surfaceElevated,
                              child: const Icon(Icons.landscape,
                                  color: AppTheme.oceanTeal),
                            ),
                          )
                        : Container(
                            color: AppTheme.surfaceElevated,
                            child: const Icon(Icons.landscape,
                                color: AppTheme.oceanTeal),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              d.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textCream,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.oceanTeal.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppTheme.oceanTeal,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        d.tagline,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 12, color: AppTheme.sunsetGold),
                          const SizedBox(width: 3),
                          Text(
                            d.district,
                            style: const TextStyle(
                                fontSize: 11, color: AppTheme.textMuted),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.calendar_today,
                              size: 11, color: AppTheme.oceanTeal),
                          const SizedBox(width: 3),
                          Text(
                            '${d.averageStayDays} Days avg',
                            style: const TextStyle(
                                fontSize: 11, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    color: AppTheme.borderTeal, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ServiceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ServiceButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.4), width: 1.2),
            ),
            child: Center(
              child: Icon(icon, color: color, size: 24),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textCream,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteDot extends StatelessWidget {
  final String label;
  final bool isStart;
  final bool isEnd;

  const _RouteDot({
    required this.label,
    this.isStart = false,
    this.isEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    Color dotColor = AppTheme.sunsetGold;
    if (isStart) dotColor = AppTheme.oceanTeal;
    if (isEnd) dotColor = AppTheme.sunsetCoral;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: dotColor.withValues(alpha: 0.5),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

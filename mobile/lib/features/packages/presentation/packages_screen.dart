import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../data/package_repository.dart';
import '../models/package_models.dart';
import 'package_detail_screen.dart';

class PackagesScreen extends StatefulWidget {
  final IPackageRepository? repository;

  const PackagesScreen({super.key, this.repository});

  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  // Option B: Coastal Twilight Teal & Golden Sunset
  static const Color bgDark = AppTheme.midnightTeal;
  static const Color surfaceDark = AppTheme.surfaceTeal;
  static const Color borderSubtle = AppTheme.borderTeal;
  static const Color emerald = AppTheme.oceanTeal;
  static const Color gold = AppTheme.sunsetGold;
  static const Color textPrimary = AppTheme.textCream;
  static const Color textMuted = AppTheme.textMuted;
  static const Color textSubtle = AppTheme.textSubtle;

  late final IPackageRepository _repo;
  List<TourPackage> _packages = [];
  bool _isLoading = true;
  String _selectedCategory = 'ALL';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _categories = const [
    {'key': 'ALL', 'label': 'All Packages', 'icon': '🌴'},
    {'key': 'HILL_STATION', 'label': 'Hill Stations', 'icon': '⛰️'},
    {'key': 'BACKWATERS', 'label': 'Houseboats', 'icon': '⛵'},
    {'key': 'ADVENTURE', 'label': 'Wildlife', 'icon': '🐘'},
    {'key': 'HONEYMOON', 'label': 'Honeymoon', 'icon': '❤️'},
    {'key': 'FAMILY', 'label': 'Family Circuits', 'icon': '👨‍👩‍👧‍👦'},
  ];

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? PackageRepository(apiClient: null as dynamic);
    _loadPackages();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPackages() async {
    setState(() => _isLoading = true);
    try {
      final list = await _repo.getPackages(
        category: _selectedCategory,
        query: _searchQuery,
      );
      if (mounted) {
        setState(() {
          _packages = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onCategorySelected(String key) {
    if (_selectedCategory == key) return;
    setState(() => _selectedCategory = key);
    _loadPackages();
  }

  void _onSearchChanged(String val) {
    setState(() => _searchQuery = val.trim());
    _loadPackages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: surfaceDark,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tour Packages & Operators',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            Text(
              'Direct from DTPC & Kerala Tourism verified companies',
              style: TextStyle(fontSize: 11, color: emerald),
            ),
          ],
        ),
        actions: [
          IconButton(
            key: const Key('refresh_packages_btn'),
            icon: const Icon(Icons.refresh, color: emerald),
            onPressed: _loadPackages,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: surfaceDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderSubtle),
              ),
              child: TextField(
                key: const Key('packages_search_input'),
                controller: _searchController,
                style: const TextStyle(color: textPrimary, fontSize: 14),
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search Munnar, Houseboat, Wayanad...',
                  hintStyle: const TextStyle(color: textSubtle, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: emerald, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: textMuted, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
          ),

          // Categories Filter Row
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat['key'];
                return ChoiceChip(
                  key: Key('cat_chip_${cat['key']}'),
                  label: Text('${cat['icon']} ${cat['label']}'),
                  selected: isSelected,
                  selectedColor: emerald,
                  backgroundColor: surfaceDark,
                  labelStyle: TextStyle(
                    color: isSelected ? bgDark : textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  side: BorderSide(
                    color: isSelected ? emerald : borderSubtle,
                  ),
                  onSelected: (_) => _onCategorySelected(cat['key']!),
                );
              },
            ),
          ),

          // Main Package Cards List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: emerald),
                  )
                : _packages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _packages.length,
                        itemBuilder: (ctx, idx) => _buildPackageCard(_packages[idx]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.travel_explore_outlined, color: borderSubtle, size: 64),
          const SizedBox(height: 12),
          const Text(
            'No matching tour packages found',
            style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try searching a different destination or select "All Packages"',
            style: TextStyle(color: textMuted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: emerald),
            onPressed: () {
              _searchController.clear();
              _onCategorySelected('ALL');
            },
            child: const Text('Reset Filters', style: TextStyle(color: bgDark, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(TourPackage package) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: surfaceDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Cover with Tags
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    color: bgDark,
                    child: Image.network(
                      package.heroImage,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.landscape_rounded, color: emerald, size: 48),
                      ),
                    ),
                  ),
                ),
              ),
              // Gradient Shade
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.4),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
              ),
              // Duration Pill
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: bgDark.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: emerald),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.schedule, color: emerald, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        package.duration,
                        style: const TextStyle(color: textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              // Savings Tag
              if (package.savingsPercent > 0)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.emergencyRed,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${package.savingsPercent}% OFF',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              // Rating Badge
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: gold, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${package.rating} (${package.reviewCount})',
                        style: const TextStyle(color: textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Details Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Operator Verified Pill
                Row(
                  children: [
                    const Icon(Icons.verified, color: emerald, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        package.operator.name,
                        style: const TextStyle(color: emerald, fontSize: 12, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: borderSubtle.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('DTPC Partner', style: TextStyle(color: textMuted, fontSize: 10)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Title
                Text(
                  package.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),

                // Tagline
                Text(
                  package.tagline,
                  style: const TextStyle(color: textMuted, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Route Chips
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: package.destinationsCovered.take(4).map((d) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: bgDark,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: borderSubtle),
                      ),
                      child: Text(d, style: const TextStyle(color: textMuted, fontSize: 10)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                const Divider(color: borderSubtle, height: 1),
                const SizedBox(height: 12),

                // Price and Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Starting from', style: TextStyle(color: textSubtle, fontSize: 10)),
                        Row(
                          children: [
                            Text(
                              '₹${package.pricePerPerson.toInt()}',
                              style: const TextStyle(
                                color: gold,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(' / person', style: TextStyle(color: textMuted, fontSize: 11)),
                            if (package.originalPrice != null) ...[
                              const SizedBox(width: 6),
                              Text(
                                '₹${package.originalPrice!.toInt()}',
                                style: const TextStyle(
                                  color: textSubtle,
                                  fontSize: 11,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      key: Key('view_pkg_${package.slug}'),
                      icon: const Icon(Icons.arrow_forward, size: 16, color: bgDark),
                      label: const Text('View Details', style: TextStyle(color: bgDark, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gold,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PackageDetailScreen(
                              package: package,
                              repository: _repo,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

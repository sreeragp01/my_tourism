import 'package:flutter/material.dart';
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
    // Default to mock repo if not supplied
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
      backgroundColor: const Color(0xFF0D1F17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF142B20),
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tour Packages & Operators',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF7F3E8),
              ),
            ),
            Text(
              'Direct from DTPC & Kerala Tourism verified companies',
              style: TextStyle(fontSize: 11, color: Color(0xFF10B981)),
            ),
          ],
        ),
        actions: [
          IconButton(
            key: const Key('refresh_packages_btn'),
            icon: const Icon(Icons.refresh, color: Color(0xFF10B981)),
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
                color: const Color(0xFF142B20),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF2D5A43)),
              ),
              child: TextField(
                key: const Key('packages_search_input'),
                controller: _searchController,
                style: const TextStyle(color: Color(0xFFF7F3E8), fontSize: 14),
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search Munnar, Houseboat, Wayanad...',
                  hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF10B981), size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white70, size: 18),
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
                  selectedColor: const Color(0xFF10B981),
                  backgroundColor: const Color(0xFF142B20),
                  labelStyle: TextStyle(
                    color: isSelected ? const Color(0xFF0D1F17) : const Color(0xFFF7F3E8),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  side: BorderSide(
                    color: isSelected ? const Color(0xFF10B981) : const Color(0xFF2D5A43),
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
                    child: CircularProgressIndicator(color: Color(0xFF10B981)),
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
          const Icon(Icons.travel_explore_outlined, color: Color(0xFF2D5A43), size: 64),
          const SizedBox(height: 12),
          const Text(
            'No matching tour packages found',
            style: TextStyle(color: Color(0xFFF7F3E8), fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try searching a different destination or select "All Packages"',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            onPressed: () {
              _searchController.clear();
              _onCategorySelected('ALL');
            },
            child: const Text('Reset Filters', style: TextStyle(color: Color(0xFF0D1F17), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(TourPackage package) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF142B20),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2D5A43)),
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
                    color: const Color(0xFF0D1F17),
                    child: Image.network(
                      package.heroImage,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.landscape_rounded, color: Color(0xFF10B981), size: 48),
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
                    color: const Color(0xFF0D1F17).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF10B981)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.schedule, color: Color(0xFF10B981), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        package.duration,
                        style: const TextStyle(color: Color(0xFFF7F3E8), fontSize: 11, fontWeight: FontWeight.bold),
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
                      color: const Color(0xFFE11D48),
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
                      const Icon(Icons.star, color: Color(0xFFF59E0B), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${package.rating} (${package.reviewCount})',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
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
                    const Icon(Icons.verified, color: Color(0xFF10B981), size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        package.operator.name,
                        style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D5A43).withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('DTPC Partner', style: TextStyle(color: Color(0xFFC5D8CD), fontSize: 10)),
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
                    color: Color(0xFFF7F3E8),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),

                // Tagline
                Text(
                  package.tagline,
                  style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
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
                        color: const Color(0xFF0D1F17),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF2D5A43)),
                      ),
                      child: Text(d, style: const TextStyle(color: Color(0xFFC5D8CD), fontSize: 10)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                const Divider(color: Color(0xFF2D5A43), height: 1),
                const SizedBox(height: 12),

                // Price and Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Starting from', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 10)),
                        Row(
                          children: [
                            Text(
                              '₹${package.pricePerPerson.toInt()}',
                              style: const TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(' / person', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11)),
                            if (package.originalPrice != null) ...[
                              const SizedBox(width: 6),
                              Text(
                                '₹${package.originalPrice!.toInt()}',
                                style: const TextStyle(
                                  color: Color(0xFF6B7280),
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
                      icon: const Icon(Icons.arrow_forward, size: 16, color: Color(0xFF0D1F17)),
                      label: const Text('View Details', style: TextStyle(color: Color(0xFF0D1F17), fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
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

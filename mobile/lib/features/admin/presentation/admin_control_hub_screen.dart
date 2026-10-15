import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/login_screen.dart';
import '../../main/presentation/main_nav_screen.dart';
import '../data/admin_repository.dart';
import '../models/admin_models.dart';
import 'add_package_dialog.dart';
import 'add_driver_dialog.dart';
import 'add_destination_dialog.dart';

class AdminControlHubScreen extends StatefulWidget {
  final AuthRepository authRepository;

  const AdminControlHubScreen({
    super.key,
    required this.authRepository,
  });

  @override
  State<AdminControlHubScreen> createState() => _AdminControlHubScreenState();
}

class _AdminControlHubScreenState extends State<AdminControlHubScreen> {
  int _currentTab = 0;
  late final AdminRepository _adminRepo;

  AdminStats? _stats;
  List<AdminUser> _users = [];
  List<AdminDriver> _drivers = [];
  List<Map<String, dynamic>> _packages = [];
  List<Map<String, dynamic>> _destinations = [];

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _adminRepo = AdminRepository(apiClient: widget.authRepository.apiClient);
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _adminRepo.getStats().catchError((_) => const AdminStats(
              totalUsers: 0,
              activeUsers: 0,
              totalBookings: 0,
              grossGmv: 0.0,
              totalPackages: 0,
              totalDrivers: 0,
              totalDestinations: 0,
            )),
        _adminRepo.getUsers().catchError((_) => <AdminUser>[]),
        _adminRepo.getDrivers().catchError((_) => <AdminDriver>[]),
        _adminRepo.getPackages().catchError((_) => <Map<String, dynamic>>[]),
        _adminRepo.getDestinations().catchError((_) => <Map<String, dynamic>>[]),
      ]);

      if (mounted) {
        setState(() {
          _stats = results[0] as AdminStats;
          _users = results[1] as List<AdminUser>;
          _drivers = results[2] as List<AdminDriver>;
          _packages = results[3] as List<Map<String, dynamic>>;
          _destinations = results[4] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading admin data: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _switchToTouristMode() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MainNavScreen(authRepository: widget.authRepository),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceTeal,
        title: const Text('Sign Out', style: TextStyle(color: AppTheme.textCream)),
        content: const Text(
          'Are you sure you want to end your admin session?',
          style: TextStyle(color: AppTheme.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.oceanTeal),
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.authRepository.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LoginScreen(authRepository: widget.authRepository)),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.midnightTeal,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceTeal,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.6)),
                  ),
                  child: const Text(
                    'SUPER ADMIN',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'KeraLink Command Hub',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textCream),
                ),
              ],
            ),
            const Text(
              'God\'s Own Country Platform Management',
              style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: _switchToTouristMode,
            icon: const Icon(Icons.travel_explore, size: 16, color: AppTheme.sunsetGold),
            label: const Text(
              'Tourist Mode',
              style: TextStyle(color: AppTheme.sunsetGold, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout, size: 20, color: AppTheme.textMuted),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.sunsetGold),
            )
          : RefreshIndicator(
              color: AppTheme.sunsetGold,
              backgroundColor: AppTheme.surfaceTeal,
              onRefresh: _loadAllData,
              child: _buildBody(),
            ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfaceTeal,
          border: Border(top: BorderSide(color: AppTheme.borderTeal, width: 0.8)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentTab,
          onTap: (idx) => setState(() => _currentTab = idx),
          backgroundColor: AppTheme.surfaceTeal,
          selectedItemColor: AppTheme.sunsetGold,
          unselectedItemColor: AppTheme.textMuted,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Overview',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.card_travel_outlined),
              activeIcon: Icon(Icons.card_travel),
              label: 'Packages',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.directions_car_outlined),
              activeIcon: Icon(Icons.directions_car),
              label: 'Drivers',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.location_on_outlined),
              activeIcon: Icon(Icons.location_on),
              label: 'Locations',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentTab) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return _buildPackagesTab();
      case 2:
        return _buildDriversTab();
      case 3:
        return _buildLocationsTab();
      default:
        return _buildOverviewTab();
    }
  }

  // ===========================================================================
  // TAB 0: OVERVIEW & USER MONETIZATION
  // ===========================================================================
  Widget _buildOverviewTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_error != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.redAccent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
        // KPI Grid
        const Text(
          'Platform Financials & Traction',
          style: TextStyle(color: AppTheme.sunsetGold, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Gross Platform GMV',
                '₹${(_stats?.grossGmv ?? 0).toStringAsFixed(0)}',
                Icons.currency_rupee,
                AppTheme.sunsetGold,
                '+28% Growth',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                'Total Bookings',
                '${_stats?.totalBookings ?? 0}',
                Icons.book_online,
                AppTheme.oceanTeal,
                'Active Trips',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Registered Users',
                '${_stats?.totalUsers ?? 0}',
                Icons.people,
                Colors.tealAccent,
                '${_stats?.activeUsers ?? 0} active',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                'Verified Drivers',
                '${_stats?.totalDrivers ?? _drivers.length}',
                Icons.directions_car,
                Colors.amberAccent,
                'Kerala Fleet',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // User Monetization Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'User Monetization & Roster',
              style: TextStyle(color: AppTheme.sunsetGold, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            Text(
              '${_users.length} Users',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (_users.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceTeal,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'No registered users found.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
            ),
          )
        else
          ..._users.map((u) => _buildUserCard(u)),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, String sub) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceTeal,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderTeal),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(sub, style: const TextStyle(fontSize: 10, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildUserCard(AdminUser user) {
    final isAdmin = user.roles.contains('ADMIN') || user.roles.contains('SUPER_ADMIN');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceTeal,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isAdmin ? AppTheme.sunsetGold.withValues(alpha: 0.5) : AppTheme.borderTeal),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isAdmin ? AppTheme.sunsetGold : AppTheme.oceanTeal,
            radius: 20,
            child: Text(
              user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : 'U',
              style: const TextStyle(color: AppTheme.midnightTeal, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.fullName,
                        style: const TextStyle(color: AppTheme.textCream, fontWeight: FontWeight.bold, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: isAdmin ? Colors.redAccent.withValues(alpha: 0.2) : Colors.teal.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isAdmin ? 'ADMIN' : 'TOURIST',
                        style: TextStyle(
                          color: isAdmin ? Colors.redAccent : Colors.tealAccent,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(user.email, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                const SizedBox(height: 3),
                Text(
                  '🌱 Eco-Score: ${user.ecoScore} pts · ${user.ecoTier} · ${user.tripsCompleted} Trips',
                  style: const TextStyle(color: AppTheme.sunsetGold, fontSize: 10),
                ),
              ],
            ),
          ),
          Switch(
            value: user.isActive,
            activeTrackColor: AppTheme.sunsetGold,
            onChanged: (val) async {
              final ok = await _adminRepo.toggleUserStatus(user.id);
              if (ok) {
                _loadAllData();
              }
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1: PACKAGES MANAGER
  // ===========================================================================
  Widget _buildPackagesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tour Packages Market',
                  style: TextStyle(color: AppTheme.sunsetGold, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_packages.length} Packages Live',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () => AddPackageDialog.show(context, _adminRepo, _loadAllData),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Package', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.sunsetGold,
                foregroundColor: AppTheme.midnightTeal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (_packages.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceTeal,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'No tour packages yet. Tap "+ Add Package" to publish one!',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
            ),
          )
        else
          ..._packages.map((pkg) => _buildPackageCard(pkg)),
      ],
    );
  }

  Widget _buildPackageCard(Map<String, dynamic> pkg) {
    final title = pkg['title']?.toString() ?? 'Package';
    final price = pkg['price_per_person']?.toString() ?? '0';
    final days = pkg['duration_days']?.toString() ?? '3';
    final nights = pkg['duration_nights']?.toString() ?? '2';
    final category = pkg['category']?.toString() ?? 'HILL_STATION';
    final hero = pkg['hero_image']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceTeal,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderTeal),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hero.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: Image.network(
                hero,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 120,
                  color: AppTheme.midnightTeal,
                  child: const Center(child: Icon(Icons.landscape, color: AppTheme.textMuted)),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.oceanTeal.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        category.replaceAll('_', ' '),
                        style: const TextStyle(color: AppTheme.sunsetGold, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      '₹$price / person',
                      style: const TextStyle(color: AppTheme.sunsetGold, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: const TextStyle(color: AppTheme.textCream, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '⏱ ${days}D / ${nights}N · ${pkg['operator_name'] ?? 'Verified Operator'}',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 2: DRIVERS FLEET
  // ===========================================================================
  Widget _buildDriversTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chauffeur Fleet Hub',
                  style: TextStyle(color: AppTheme.sunsetGold, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_drivers.length} Drivers Verified',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () => AddDriverDialog.show(context, _adminRepo, _loadAllData),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Driver', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.sunsetGold,
                foregroundColor: AppTheme.midnightTeal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (_drivers.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceTeal,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'No drivers enrolled. Tap "+ Add Driver" to onboard one!',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
            ),
          )
        else
          ..._drivers.map((driver) => _buildDriverCard(driver)),
      ],
    );
  }

  Widget _buildDriverCard(AdminDriver driver) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceTeal,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderTeal),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified_user, color: Colors.greenAccent, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    driver.name,
                    style: const TextStyle(color: AppTheme.textCream, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.oceanTeal.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  driver.vehiclePlateNumber,
                  style: const TextStyle(color: AppTheme.sunsetGold, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.directions_car, color: AppTheme.textMuted, size: 14),
              const SizedBox(width: 4),
              Text(
                '${driver.vehicleType} · ${driver.district}',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
              ),
              const Spacer(),
              const Icon(Icons.star, color: AppTheme.sunsetGold, size: 14),
              const SizedBox(width: 2),
              Text(
                '${driver.rating} (${driver.tripsCompleted} trips)',
                style: const TextStyle(color: AppTheme.textCream, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '📞 ${driver.phone} · License: ${driver.licenseNumber}',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 3: LOCATIONS & DESTINATIONS
  // ===========================================================================
  Widget _buildLocationsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kerala Locations Catalog',
                  style: TextStyle(color: AppTheme.sunsetGold, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_destinations.length} Verified Destinations',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () => AddDestinationDialog.show(context, _adminRepo, _loadAllData),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Location', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.sunsetGold,
                foregroundColor: AppTheme.midnightTeal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (_destinations.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceTeal,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'No locations found. Tap "+ Add Location" to register one!',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
            ),
          )
        else
          ..._destinations.map((dest) => _buildDestinationCard(dest)),
      ],
    );
  }

  Widget _buildDestinationCard(Map<String, dynamic> dest) {
    final name = dest['name']?.toString() ?? 'Destination';
    final district = dest['district']?.toString() ?? 'Kerala';
    final tagline = dest['tagline']?.toString() ?? '';
    final lat = dest['latitude']?.toString() ?? '';
    final lng = dest['longitude']?.toString() ?? '';
    final hero = dest['hero_image']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceTeal,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderTeal),
      ),
      child: Row(
        children: [
          if (hero.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: Image.network(
                hero,
                width: 90,
                height: 90,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 90,
                  height: 90,
                  color: AppTheme.midnightTeal,
                  child: const Icon(Icons.image, color: AppTheme.textMuted),
                ),
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(color: AppTheme.textCream, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.oceanTeal.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          district,
                          style: const TextStyle(color: AppTheme.sunsetGold, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (tagline.isNotEmpty)
                    Text(
                      tagline,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    '📍 $lat, $lng',
                    style: const TextStyle(color: Colors.white60, fontSize: 10, fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

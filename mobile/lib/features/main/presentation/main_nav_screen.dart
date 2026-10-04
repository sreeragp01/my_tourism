import 'package:flutter/material.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_token_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/login_screen.dart';
import '../../home/data/destination_repository.dart';
import '../../home/presentation/home_discover_screen.dart';
import '../../explore/data/experience_repository.dart';
import '../../explore/presentation/explore_kerala_screen.dart';
import '../../ai_planner/presentation/ai_planner_screen.dart';
import '../../companion/presentation/live_companion_screen.dart';
import '../../companion/data/companion_repository.dart';
import '../../trips/presentation/my_trips_screen.dart';
import '../../safety/presentation/safety_hub_screen.dart';
import '../../search/data/search_repository.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../profile/data/profile_repository.dart';

class MainNavScreen extends StatefulWidget {
  final AuthRepository? authRepository;
  final DestinationRepository? destinationRepository;
  final ExperienceRepository? experienceRepository;
  final IProfileRepository? profileRepository;

  const MainNavScreen({
    super.key,
    this.authRepository,
    this.destinationRepository,
    this.experienceRepository,
    this.profileRepository,
  });

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _currentIndex = 0;
  late final DestinationRepository _destRepo;
  late final ExperienceRepository _expRepo;
  late final SearchRepository _searchRepo;
  late final CompanionRepository _compRepo;
  late final IProfileRepository _profileRepo;
  late final ApiClient _apiClient;

  @override
  void initState() {
    super.initState();
    final storage = widget.authRepository?.storage ?? SecureTokenStorage();
    _apiClient = widget.authRepository?.apiClient ??
        ApiClient(
          config: AppConfig.fromEnvironment(),
          storage: storage,
        );

    _destRepo = widget.destinationRepository ??
        DestinationRepository(apiClient: _apiClient, storage: storage);

    _expRepo = widget.experienceRepository ??
        ExperienceRepository(apiClient: _apiClient);

    _searchRepo = SearchRepository(apiClient: _apiClient);
    _compRepo = CompanionRepository(apiClient: _apiClient);
    _profileRepo = widget.profileRepository ?? ProfileRepository(apiClient: _apiClient);
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceTeal,
        title: const Text('Sign Out', style: TextStyle(color: AppTheme.textCream)),
        content: const Text(
          'Are you sure you want to sign out of your KeraLink account?',
          style: TextStyle(color: AppTheme.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emergencyRed),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && widget.authRepository != null) {
      await widget.authRepository!.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => LoginScreen(authRepository: widget.authRepository!),
        ),
        (route) => false,
      );
    }
  }

  void _openSafetyHub() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SafetyHubScreen(),
      ),
    );
  }

  void _openExploreAll() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExploreKeralaScreen(experienceRepository: _expRepo),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = (widget.authRepository?.currentUser?.firstName != null &&
            widget.authRepository!.currentUser!.firstName.trim().isNotEmpty)
        ? widget.authRepository!.currentUser!.firstName.trim()
        : 'Traveler';

    final screens = [
      HomeDiscoverScreen(
        userName: userName,
        destinationRepository: _destRepo,
        searchRepository: _searchRepo,
        onOpenPlanner: () => setState(() => _currentIndex = 1),
        onOpenCompanion: () => setState(() => _currentIndex = 3),
        onOpenSafety: _openSafetyHub,
        onOpenExplore: _openExploreAll,
        onOpenProfile: () => setState(() => _currentIndex = 4),
        onLogout: widget.authRepository != null ? _handleLogout : null,
      ),
      const AIPlannerScreen(),
      const MyTripsScreen(),
      LiveCompanionScreen(repository: _compRepo, userName: userName),
      ProfileScreen(
        repository: _profileRepo,
        onLogout: widget.authRepository != null ? _handleLogout : null,
      ),
    ];

    return Scaffold(
      backgroundColor: AppTheme.midnightTeal,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfaceTeal,
          border: Border(
            top: BorderSide(color: AppTheme.borderTeal, width: 0.8),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          backgroundColor: AppTheme.surfaceTeal,
          indicatorColor: AppTheme.oceanTeal.withValues(alpha: 0.25),
          elevation: 0,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.explore_outlined, color: AppTheme.textMuted),
              selectedIcon: Icon(Icons.explore, color: AppTheme.sunsetGold),
              label: 'Explore',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined, color: AppTheme.textMuted),
              selectedIcon: Icon(Icons.calendar_month, color: AppTheme.sunsetGold),
              label: 'Plan',
            ),
            NavigationDestination(
              icon: Icon(Icons.confirmation_number_outlined, color: AppTheme.textMuted),
              selectedIcon: Icon(Icons.confirmation_number, color: AppTheme.sunsetGold),
              label: 'My Trips',
            ),
            NavigationDestination(
              icon: Icon(Icons.forum_outlined, color: AppTheme.textMuted),
              selectedIcon: Icon(Icons.forum, color: AppTheme.sunsetGold),
              label: 'AI Guide',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded, color: AppTheme.textMuted),
              selectedIcon: Icon(Icons.person_rounded, color: AppTheme.sunsetGold),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

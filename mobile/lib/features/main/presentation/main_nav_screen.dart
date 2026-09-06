import 'package:flutter/material.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_token_storage.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/login_screen.dart';
import '../../home/data/destination_repository.dart';
import '../../home/presentation/home_discover_screen.dart';
import '../../explore/data/experience_repository.dart';
import '../../explore/presentation/explore_kerala_screen.dart';
import '../../ai_planner/presentation/ai_planner_screen.dart';
import '../../companion/presentation/live_companion_screen.dart';
import '../../trips/presentation/my_trips_screen.dart';
import '../../safety/presentation/safety_hub_screen.dart';

class MainNavScreen extends StatefulWidget {
  final AuthRepository? authRepository;
  final DestinationRepository? destinationRepository;
  final ExperienceRepository? experienceRepository;

  const MainNavScreen({
    super.key,
    this.authRepository,
    this.destinationRepository,
    this.experienceRepository,
  });

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _currentIndex = 0;
  late final DestinationRepository _destRepo;
  late final ExperienceRepository _expRepo;

  @override
  void initState() {
    super.initState();
    if (widget.destinationRepository != null) {
      _destRepo = widget.destinationRepository!;
    } else {
      final storage = widget.authRepository?.storage ?? SecureTokenStorage();
      final client = widget.authRepository?.apiClient ??
          ApiClient(
            config: AppConfig.fromEnvironment(),
            storage: storage,
          );
      _destRepo = DestinationRepository(apiClient: client, storage: storage);
    }

    if (widget.experienceRepository != null) {
      _expRepo = widget.experienceRepository!;
    } else {
      final client = widget.authRepository?.apiClient ??
          ApiClient(
            config: AppConfig.fromEnvironment(),
            storage: widget.authRepository?.storage ?? SecureTokenStorage(),
          );
      _expRepo = ExperienceRepository(apiClient: client);
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF142B20),
        title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to sign out of your KeraLink account?',
          style: TextStyle(color: Color(0xFFC5D8CD)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE11D48)),
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

  @override
  Widget build(BuildContext context) {
    final userName = widget.authRepository?.currentUser?.firstName ?? 'Sreerag';

    final screens = [
      HomeDiscoverScreen(
        userName: userName,
        destinationRepository: _destRepo,
        onOpenPlanner: () => setState(() => _currentIndex = 2),
        onOpenCompanion: () => setState(() => _currentIndex = 3),
        onLogout: widget.authRepository != null ? _handleLogout : null,
      ),
      ExploreKeralaScreen(experienceRepository: _expRepo),
      const AIPlannerScreen(),
      const LiveCompanionScreen(),
      const MyTripsScreen(),
      const SafetyHubScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: const Color(0xFF142B20),
        indicatorColor: const Color(0xFF10B981).withValues(alpha: 0.25),
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.home, color: Color(0xFF10B981)),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.explore, color: Color(0xFF10B981)),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.auto_awesome, color: Color(0xFFD4AF37)),
            label: 'AI Plan',
          ),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.forum, color: Color(0xFF10B981)),
            label: 'Companion',
          ),
          NavigationDestination(
            icon: Icon(Icons.confirmation_number_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.confirmation_number, color: Color(0xFF10B981)),
            label: 'My Trips',
          ),
          NavigationDestination(
            icon: Icon(Icons.shield_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.shield, color: Color(0xFFE11D48)),
            label: 'Safety',
          ),
        ],
      ),
    );
  }
}

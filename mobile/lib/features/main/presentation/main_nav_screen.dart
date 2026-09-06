import 'package:flutter/material.dart';
import '../../home/presentation/home_discover_screen.dart';
import '../../ai_planner/presentation/ai_planner_screen.dart';
import '../../companion/presentation/live_companion_screen.dart';
import '../../trips/presentation/my_trips_screen.dart';
import '../../safety/presentation/safety_hub_screen.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeDiscoverScreen(
        onOpenPlanner: () => setState(() => _currentIndex = 1),
        onOpenCompanion: () => setState(() => _currentIndex = 2),
      ),
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
            icon: Icon(Icons.explore_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.explore, color: Color(0xFF10B981)),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.auto_awesome, color: Color(0xFFD4AF37)),
            label: 'AI Planner',
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

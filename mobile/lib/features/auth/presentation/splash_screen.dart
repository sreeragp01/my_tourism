import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../data/auth_repository.dart';
import 'login_screen.dart';
import '../../main/presentation/main_nav_screen.dart';

class SplashScreen extends StatefulWidget {
  final AuthRepository authRepository;

  const SplashScreen({
    super.key,
    required this.authRepository,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkInitialSession();
  }

  Future<void> _checkInitialSession() async {
    // Artificial minimum delay for smooth visual transition
    await Future.delayed(const Duration(milliseconds: 600));

    final isAuthenticated = await widget.authRepository.checkSession();

    if (!mounted) return;

    if (isAuthenticated) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MainNavScreen(authRepository: widget.authRepository),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => LoginScreen(authRepository: widget.authRepository),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.midnightTeal,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.sunsetGold, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.oceanTeal.withValues(alpha: 0.25),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.asset(
                  'assets/images/app_logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppTheme.surfaceTeal,
                    child: const Center(
                      child: Text('🌴', style: TextStyle(fontSize: 40)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'KeraLink',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.textCream,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'God\'s Own Country • AI Travel Companion',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 36),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppTheme.sunsetGold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

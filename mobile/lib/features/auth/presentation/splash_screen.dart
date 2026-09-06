import 'package:flutter/material.dart';
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
      backgroundColor: const Color(0xFF0A1D19),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF144032),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Center(
                child: Text('🌴', style: TextStyle(fontSize: 40)),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'KeraLink',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF7F3E8),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'God\'s Own Country • AI Travel Companion',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFFC5D8CD),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 36),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFFD4AF37),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

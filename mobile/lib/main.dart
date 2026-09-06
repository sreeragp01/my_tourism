import 'package:flutter/material.dart';
import 'package:keralink_mobile/features/main/presentation/main_nav_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KeraLinkApp());
}

class KeraLinkApp extends StatelessWidget {
  const KeraLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KeraLink Tourism',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF142B20),
        scaffoldBackgroundColor: const Color(0xFF0D1F17),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF10B981),
          secondary: Color(0xFFD4AF37),
          surface: Color(0xFF142B20),
        ),
        useMaterial3: true,
      ),
      home: const MainNavScreen(),
    );
  }
}

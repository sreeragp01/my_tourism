import 'package:flutter/material.dart';
import 'package:keralink_mobile/core/config/app_config.dart';
import 'package:keralink_mobile/core/network/api_client.dart';
import 'package:keralink_mobile/core/storage/secure_token_storage.dart';
import 'package:keralink_mobile/features/auth/data/auth_repository.dart';
import 'package:keralink_mobile/features/auth/presentation/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();
  final storage = SecureTokenStorage();
  final apiClient = ApiClient(config: config, storage: storage);
  final authRepository = AuthRepository(apiClient: apiClient, storage: storage);

  runApp(KeraLinkApp(authRepository: authRepository));
}

class KeraLinkApp extends StatelessWidget {
  final AuthRepository authRepository;

  const KeraLinkApp({
    super.key,
    required this.authRepository,
  });

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
      home: SplashScreen(authRepository: authRepository),
    );
  }
}

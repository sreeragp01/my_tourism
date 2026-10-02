import 'package:flutter/material.dart';
import 'package:keralink_mobile/core/config/app_config.dart';
import 'package:keralink_mobile/core/network/api_client.dart';
import 'package:keralink_mobile/core/storage/secure_token_storage.dart';
import 'package:keralink_mobile/features/auth/data/auth_repository.dart';
import 'package:keralink_mobile/features/auth/presentation/splash_screen.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();
  final storage = SecureTokenStorage();
  final apiClient = ApiClient(config: config, storage: storage);
  await apiClient.init();
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
      theme: AppTheme.theme,
      home: SplashScreen(authRepository: authRepository),
    );
  }
}

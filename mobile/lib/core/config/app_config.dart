import 'package:flutter/foundation.dart';

enum AppEnvironment {
  development,
  staging,
  production,
}

class AppConfig {
  final AppEnvironment environment;
  final String? customBaseUrl;

  const AppConfig({
    required this.environment,
    this.customBaseUrl,
  });

  static AppEnvironment _parseEnvironment(String name) {
    switch (name.toLowerCase()) {
      case 'staging':
        return AppEnvironment.staging;
      case 'production':
      case 'prod':
        return AppEnvironment.production;
      case 'development':
      case 'dev':
      default:
        return AppEnvironment.development;
    }
  }

  /// Factory creating configuration from compile-time flags (--dart-define)
  factory AppConfig.fromEnvironment() {
    const envStr = String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
    const customUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    return AppConfig(
      environment: _parseEnvironment(envStr),
      customBaseUrl: customUrl.isNotEmpty ? customUrl : null,
    );
  }

  String get apiBaseUrl {
    if (customBaseUrl != null && customBaseUrl!.isNotEmpty) {
      return customBaseUrl!;
    }

    switch (environment) {
      case AppEnvironment.production:
        return 'https://api.keralink.org/api/v1';

      case AppEnvironment.staging:
        return 'https://staging-api.keralink.org/api/v1';

      case AppEnvironment.development:
        // Safe check for Android emulator loopback vs standard localhost
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
          return 'http://10.0.2.2:8000/api/v1';
        }
        return 'http://127.0.0.1:8000/api/v1';
    }
  }

  bool get isProduction => environment == AppEnvironment.production;
  bool get isDevelopment => environment == AppEnvironment.development;
}

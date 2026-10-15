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
    const envStr = String.fromEnvironment(
      'ENVIRONMENT',
      defaultValue: 'production',
    );
    const customUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    return AppConfig(
      environment: _parseEnvironment(envStr),
      customBaseUrl: customUrl.isNotEmpty ? customUrl : null,
    );
  }

  AppConfig copyWith({
    AppEnvironment? environment,
    String? customBaseUrl,
  }) {
    return AppConfig(
      environment: environment ?? this.environment,
      customBaseUrl: customBaseUrl ?? this.customBaseUrl,
    );
  }

  static const String liveProductionUrl = 'https://my-tourism.onrender.com/api/v1';

  List<String> get candidateBaseUrls {
    if (customBaseUrl != null && customBaseUrl!.isNotEmpty) {
      return [customBaseUrl!];
    }
    return const [liveProductionUrl];
  }

  String get apiBaseUrl {
    if (customBaseUrl != null && customBaseUrl!.isNotEmpty) {
      return customBaseUrl!;
    }
    return liveProductionUrl;
  }

  bool get isProduction => environment == AppEnvironment.production;
  bool get isDevelopment => environment == AppEnvironment.development;
}

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:keralink_mobile/core/config/app_config.dart';
import 'package:keralink_mobile/core/network/api_client.dart';
import 'package:keralink_mobile/core/storage/secure_token_storage.dart';
import 'package:keralink_mobile/features/auth/data/auth_repository.dart';
import 'package:keralink_mobile/features/auth/presentation/login_screen.dart';
import 'package:keralink_mobile/features/auth/presentation/splash_screen.dart';
import 'package:keralink_mobile/main.dart';

void main() {
  testWidgets('KeraLink App Initial Launch & Splash to Login transition test', (WidgetTester tester) async {
    final storage = InMemoryTokenStorage();
    const config = AppConfig(environment: AppEnvironment.development);
    final client = ApiClient(config: config, storage: storage, httpClient: MockClient((_) async => http.Response('{}', 200)));
    final authRepo = AuthRepository(apiClient: client, storage: storage);

    await tester.pumpWidget(KeraLinkApp(authRepository: authRepo));

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('KeraLink'), findsOneWidget);

    // Settle the 600ms splash screen timer and route transition
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // Verifies transition to LoginScreen when unauthenticated
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Welcome to KeraLink'), findsOneWidget);
  });
}

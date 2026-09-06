import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:keralink_mobile/core/config/app_config.dart';
import 'package:keralink_mobile/core/errors/api_exception.dart';
import 'package:keralink_mobile/core/network/api_client.dart';
import 'package:keralink_mobile/core/storage/secure_token_storage.dart';
import 'package:keralink_mobile/features/auth/data/auth_repository.dart';

void main() {
  group('AppConfig Environment Tests', () {
    test('Default development environment URL selection', () {
      const config = AppConfig(environment: AppEnvironment.development);
      expect(config.isDevelopment, isTrue);
      expect(config.isProduction, isFalse);
      expect(config.apiBaseUrl, contains('8000/api/v1'));
    });

    test('Staging environment URL selection', () {
      const config = AppConfig(environment: AppEnvironment.staging);
      expect(config.apiBaseUrl, 'https://staging-api.keralink.org/api/v1');
    });

    test('Production environment URL selection', () {
      const config = AppConfig(environment: AppEnvironment.production);
      expect(config.isProduction, isTrue);
      expect(config.apiBaseUrl, 'https://api.keralink.org/api/v1');
    });

    test('Custom base URL override takes precedence', () {
      const config = AppConfig(
        environment: AppEnvironment.production,
        customBaseUrl: 'https://custom-gateway.keralink.travel/api/v1',
      );
      expect(config.apiBaseUrl, 'https://custom-gateway.keralink.travel/api/v1');
    });
  });

  group('ApiException Hierarchy & Parsing Tests', () {
    test('Parses structured backend error format', () {
      final json = {
        'success': false,
        'error': {
          'code': 'INVALID_CREDENTIALS',
          'message': 'Invalid email or password',
        },
      };

      final ex = ApiException.fromJson(json, 401);
      expect(ex, isA<UnauthorizedException>());
      expect(ex.code, 'INVALID_CREDENTIALS');
      expect(ex.message, 'Invalid email or password');
    });

    test('Detects and instantiates TokenReplayException', () {
      final json = {
        'success': false,
        'error': {
          'code': 'TOKEN_REPLAY_DETECTED',
          'message': 'Security alert: Token reuse detected.',
        },
      };

      final ex = ApiException.fromJson(json, 401);
      expect(ex, isA<TokenReplayException>());
      expect(ex.code, 'TOKEN_REPLAY_DETECTED');
    });

    test('Detects and instantiates TokenExpiredException', () {
      final json = {
        'success': false,
        'error': {
          'code': 'TOKEN_EXPIRED',
          'message': 'Refresh token has expired',
        },
      };

      final ex = ApiException.fromJson(json, 401);
      expect(ex, isA<TokenExpiredException>());
    });

    test('Parses DRF validation error map', () {
      final json = {
        'email': ['Enter a valid email address.'],
        'password': ['This password is too short.'],
      };

      final ex = ApiException.fromJson(json, 400);
      expect(ex, isA<ValidationException>());
      expect(ex.message, contains('Enter a valid email address.'));
      expect(ex.message, contains('This password is too short.'));
    });
  });

  group('SecureTokenStorage (In-Memory) Tests', () {
    late ISecureTokenStorage storage;

    setUp(() {
      storage = InMemoryTokenStorage();
    });

    test('Saves, retrieves, and clears tokens safely', () async {
      await storage.saveTokens(
        accessToken: 'acc_123',
        refreshToken: 'ref_456',
        expiresAt: '2026-10-01T00:00:00Z',
      );

      expect(await storage.getAccessToken(), 'acc_123');
      expect(await storage.getRefreshToken(), 'ref_456');
      expect(await storage.getRefreshTokenExpiresAt(), '2026-10-01T00:00:00Z');

      await storage.clearTokens();
      expect(await storage.getAccessToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);
    });

    test('Saves and retrieves user JSON payload', () async {
      await storage.saveUserData('{"name": "Sreerag"}');
      expect(await storage.getUserData(), '{"name": "Sreerag"}');

      await storage.clearAll();
      expect(await storage.getUserData(), isNull);
    });
  });

  group('ApiClient Networking & 401 Token Refresh Interceptor Tests', () {
    const config = AppConfig(
      environment: AppEnvironment.development,
      customBaseUrl: 'http://test-server/api/v1',
    );

    test('Attaches Bearer access token to authenticated requests', () async {
      final storage = InMemoryTokenStorage();
      await storage.saveTokens(accessToken: 'initial_access_token', refreshToken: 'initial_refresh');

      final mockClient = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer initial_access_token');
        return http.Response(jsonEncode({'success': true, 'data': 'protected_data'}), 200);
      });

      final client = ApiClient(config: config, storage: storage, httpClient: mockClient);
      final response = await client.get('/destinations/');
      expect(response['data'], 'protected_data');
    });

    test('401 Interception: Successfully refreshes token and retries request', () async {
      final storage = InMemoryTokenStorage();
      await storage.saveTokens(accessToken: 'expired_access_token', refreshToken: 'valid_refresh_token');

      int attempts = 0;
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/auth/refresh/')) {
          final body = jsonDecode(request.body);
          expect(body['refresh_token'], 'valid_refresh_token');
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'access_token': 'new_rotated_access_token',
                'refresh_token': 'new_rotated_refresh_token',
                'refresh_token_expires_at': '2026-12-31T00:00:00Z',
              },
            }),
            200,
          );
        }

        if (request.url.path.endsWith('/destinations/')) {
          attempts++;
          if (attempts == 1) {
            // First attempt: token expired
            return http.Response(
              jsonEncode({'success': false, 'message': 'Access token expired'}),
              401,
            );
          } else {
            // Second attempt: verify rotated token is attached
            expect(request.headers['Authorization'], 'Bearer new_rotated_access_token');
            return http.Response(jsonEncode({'destinations': ['Munnar', 'Alleppey']}), 200);
          }
        }

        return http.Response('Not Found', 404);
      });

      final client = ApiClient(config: config, storage: storage, httpClient: mockClient);
      final data = await client.get('/destinations/');

      expect(attempts, 2);
      expect(data['destinations'], contains('Munnar'));
      // Verify storage was updated with rotated tokens
      expect(await storage.getAccessToken(), 'new_rotated_access_token');
      expect(await storage.getRefreshToken(), 'new_rotated_refresh_token');
    });

    test('401 Interception: Token Replay / Expired Refresh triggers logout', () async {
      final storage = InMemoryTokenStorage();
      await storage.saveTokens(accessToken: 'bad_access', refreshToken: 'compromised_replay_refresh');

      bool sessionExpiredTriggered = false;

      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/auth/refresh/')) {
          // Backend detects replay attack and returns 401
          return http.Response(
            jsonEncode({
              'success': false,
              'error': {
                'code': 'TOKEN_REPLAY_DETECTED',
                'message': 'Token reuse detected. Session revoked.',
              },
            }),
            401,
          );
        }
        return http.Response('Unauthorized', 401);
      });

      final client = ApiClient(
        config: config,
        storage: storage,
        httpClient: mockClient,
        onSessionExpired: () {
          sessionExpiredTriggered = true;
        },
      );

      await expectLater(
        () => client.get('/destinations/'),
        throwsA(isA<UnauthorizedException>()),
      );

      // Tokens should be cleared and callback invoked
      expect(await storage.getAccessToken(), isNull);
      expect(sessionExpiredTriggered, isTrue);
    });
  });

  group('AuthRepository Integration Tests (Login, Register, Logout, Session Check)', () {
    const config = AppConfig(
      environment: AppEnvironment.development,
      customBaseUrl: 'http://test-server/api/v1',
    );

    test('login() saves tokens, restores user, and sets authenticated status', () async {
      final storage = InMemoryTokenStorage();

      final mockClient = MockClient((request) async {
        expect(request.url.path.endsWith('/auth/login/'), isTrue);
        final body = jsonDecode(request.body);
        expect(body['email'], 'traveler@keralink.travel');

        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'user': {
                'id': 'usr-1234',
                'email': 'traveler@keralink.travel',
                'first_name': 'Sreerag',
                'last_name': 'P',
                'roles': ['CUSTOMER'],
              },
              'tokens': {
                'access_token': 'jwt_access_abc',
                'refresh_token': 'jwt_refresh_xyz',
                'refresh_token_expires_at': '2026-11-01T00:00:00Z',
              },
            },
          }),
          200,
        );
      });

      final client = ApiClient(config: config, storage: storage, httpClient: mockClient);
      final repo = AuthRepository(apiClient: client, storage: storage);

      expect(repo.isAuthenticated, isFalse);

      final user = await repo.login(email: 'traveler@keralink.travel', password: 'SecretPassword123');

      expect(user.email, 'traveler@keralink.travel');
      expect(user.fullName, 'Sreerag P');
      expect(repo.isAuthenticated, isTrue);
      expect(repo.currentUser?.id, 'usr-1234');
      expect(await storage.getAccessToken(), 'jwt_access_abc');
    });

    test('register() posts user details and returns User model', () async {
      final storage = InMemoryTokenStorage();

      final mockClient = MockClient((request) async {
        expect(request.url.path.endsWith('/auth/register/'), isTrue);
        final body = jsonDecode(request.body);
        expect(body['email'], 'newuser@keralink.travel');
        expect(body['first_name'], 'Ananya');

        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'id': 'usr-5678',
              'email': 'newuser@keralink.travel',
              'first_name': 'Ananya',
              'last_name': 'Menon',
              'roles': ['CUSTOMER'],
            },
          }),
          201,
        );
      });

      final client = ApiClient(config: config, storage: storage, httpClient: mockClient);
      final repo = AuthRepository(apiClient: client, storage: storage);

      final user = await repo.register(
        email: 'newuser@keralink.travel',
        password: 'Password123',
        firstName: 'Ananya',
        lastName: 'Menon',
      );

      expect(user.id, 'usr-5678');
      expect(user.fullName, 'Ananya Menon');
    });

    test('checkSession() returns false when no refresh token exists', () async {
      final storage = InMemoryTokenStorage();
      final client = ApiClient(config: config, storage: storage, httpClient: MockClient((_) async => http.Response('', 200)));
      final repo = AuthRepository(apiClient: client, storage: storage);

      final hasSession = await repo.checkSession();
      expect(hasSession, isFalse);
      expect(repo.isAuthenticated, isFalse);
    });

    test('checkSession() restores user when valid refresh token exists', () async {
      final storage = InMemoryTokenStorage();
      await storage.saveTokens(
        accessToken: 'valid_acc',
        refreshToken: 'valid_ref',
        expiresAt: DateTime.now().add(const Duration(days: 7)).toIso8601String(),
      );
      await storage.saveUserData(jsonEncode({
        'id': 'usr-999',
        'email': 'restored@keralink.travel',
        'first_name': 'Rahul',
        'last_name': 'Nair',
        'roles': ['CUSTOMER'],
      }));

      final client = ApiClient(config: config, storage: storage, httpClient: MockClient((_) async => http.Response('', 200)));
      final repo = AuthRepository(apiClient: client, storage: storage);

      final hasSession = await repo.checkSession();
      expect(hasSession, isTrue);
      expect(repo.isAuthenticated, isTrue);
      expect(repo.currentUser?.fullName, 'Rahul Nair');
    });

    test('logout() clears all stored tokens and resets auth status', () async {
      final storage = InMemoryTokenStorage();
      await storage.saveTokens(accessToken: 'acc', refreshToken: 'ref');
      await storage.saveUserData('{"name": "test"}');

      final client = ApiClient(config: config, storage: storage, httpClient: MockClient((_) async => http.Response('', 200)));
      final repo = AuthRepository(apiClient: client, storage: storage);

      await repo.logout();

      expect(repo.isAuthenticated, isFalse);
      expect(repo.currentUser, isNull);
      expect(await storage.getAccessToken(), isNull);
      expect(await storage.getUserData(), isNull);
    });
  });
}

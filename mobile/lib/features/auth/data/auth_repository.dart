import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_token_storage.dart';
import '../models/auth_models.dart';

enum AuthStatus {
  unknown,
  authenticated,
  unauthenticated,
}

class AuthRepository {
  final ApiClient apiClient;
  final ISecureTokenStorage storage;

  final ValueNotifier<AuthStatus> statusNotifier = ValueNotifier<AuthStatus>(AuthStatus.unknown);
  User? _currentUser;

  AuthRepository({
    required this.apiClient,
    required this.storage,
  }) {
    apiClient.onSessionExpired = () {
      _currentUser = null;
      statusNotifier.value = AuthStatus.unauthenticated;
    };
  }

  User? get currentUser => _currentUser;
  bool get isAuthenticated => statusNotifier.value == AuthStatus.authenticated;

  /// Check stored refresh token and restore user session on app launch
  Future<bool> checkSession() async {
    final refreshToken = await storage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      _currentUser = null;
      statusNotifier.value = AuthStatus.unauthenticated;
      return false;
    }

    final expiresAtStr = await storage.getRefreshTokenExpiresAt();
    if (expiresAtStr != null) {
      try {
        final expiresAt = DateTime.parse(expiresAtStr);
        if (DateTime.now().isAfter(expiresAt)) {
          await logout();
          return false;
        }
      } catch (_) {}
    }

    // Restore cached user profile
    final userDataStr = await storage.getUserData();
    if (userDataStr != null && userDataStr.isNotEmpty) {
      try {
        _currentUser = User.fromJson(jsonDecode(userDataStr));
      } catch (_) {}
    }

    statusNotifier.value = AuthStatus.authenticated;
    return true;
  }

  /// Login with email and password
  Future<User> login({
    required String email,
    required String password,
    String? deviceName,
    String? platform,
  }) async {
    final response = await apiClient.post(
      ApiConstants.login,
      body: {
        'email': email.trim().toLowerCase(),
        'password': password,
        'device_name': deviceName ?? 'KeraLink Flutter Mobile',
        'platform': platform ?? 'ANDROID',
      },
      requiresAuth: false,
    );

    final authResp = AuthResponse.fromJson(response as Map<String, dynamic>);

    await storage.saveTokens(
      accessToken: authResp.tokens.accessToken,
      refreshToken: authResp.tokens.refreshToken,
      expiresAt: authResp.tokens.refreshTokenExpiresAt?.toIso8601String(),
    );

    await storage.saveUserData(jsonEncode(authResp.user.toJson()));

    _currentUser = authResp.user;
    statusNotifier.value = AuthStatus.authenticated;
    return _currentUser!;
  }

  /// Register new customer account
  Future<User> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    final response = await apiClient.post(
      ApiConstants.register,
      body: {
        'email': email.trim().toLowerCase(),
        'password': password,
        'first_name': firstName.trim(),
        'last_name': lastName.trim(),
        if (phone != null && phone.isNotEmpty) 'phone': phone.trim(),
      },
      requiresAuth: false,
    );

    final data = response['data'] is Map<String, dynamic> ? response['data'] as Map<String, dynamic> : response;
    return User.fromJson(data as Map<String, dynamic>);
  }

  /// Explicit user logout
  Future<void> logout() async {
    await storage.clearAll();
    _currentUser = null;
    statusNotifier.value = AuthStatus.unauthenticated;
  }
}

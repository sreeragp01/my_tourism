import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class ISecureTokenStorage {
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<String?> getRefreshTokenExpiresAt();
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    String? expiresAt,
  });
  Future<void> clearTokens();
  Future<String?> getUserData();
  Future<void> saveUserData(String jsonString);
  Future<void> clearAll();
}

class SecureTokenStorage implements ISecureTokenStorage {
  final FlutterSecureStorage _storage;

  static const String _keyAccessToken = 'kl_access_token';
  static const String _keyRefreshToken = 'kl_refresh_token';
  static const String _keyRefreshExpiresAt = 'kl_refresh_expires_at';
  static const String _keyUserData = 'kl_user_data';

  SecureTokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<String?> getAccessToken() async {
    return _storage.read(key: _keyAccessToken);
  }

  @override
  Future<String?> getRefreshToken() async {
    return _storage.read(key: _keyRefreshToken);
  }

  @override
  Future<String?> getRefreshTokenExpiresAt() async {
    return _storage.read(key: _keyRefreshExpiresAt);
  }

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    String? expiresAt,
  }) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
    if (expiresAt != null) {
      await _storage.write(key: _keyRefreshExpiresAt, value: expiresAt);
    }
  }

  @override
  Future<void> clearTokens() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
    await _storage.delete(key: _keyRefreshExpiresAt);
  }

  @override
  Future<String?> getUserData() async {
    return _storage.read(key: _keyUserData);
  }

  @override
  Future<void> saveUserData(String jsonString) async {
    await _storage.write(key: _keyUserData, value: jsonString);
  }

  @override
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}

/// In-memory implementation for unit testing without platform channels
class InMemoryTokenStorage implements ISecureTokenStorage {
  final Map<String, String> _data = {};

  @override
  Future<String?> getAccessToken() async => _data['access'];

  @override
  Future<String?> getRefreshToken() async => _data['refresh'];

  @override
  Future<String?> getRefreshTokenExpiresAt() async => _data['expires_at'];

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    String? expiresAt,
  }) async {
    _data['access'] = accessToken;
    _data['refresh'] = refreshToken;
    if (expiresAt != null) {
      _data['expires_at'] = expiresAt;
    }
  }

  @override
  Future<void> clearTokens() async {
    _data.remove('access');
    _data.remove('refresh');
    _data.remove('expires_at');
  }

  @override
  Future<String?> getUserData() async => _data['user'];

  @override
  Future<void> saveUserData(String jsonString) async {
    _data['user'] = jsonString;
  }

  @override
  Future<void> clearAll() async {
    _data.clear();
  }
}

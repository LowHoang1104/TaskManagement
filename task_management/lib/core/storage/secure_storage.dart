import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keys for secure storage
class _SecureKeys {
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String userId = 'user_id';
}

/// Wrapper around [FlutterSecureStorage] for managing JWT tokens.
class SecureStorage {
  final FlutterSecureStorage _storage;

  const SecureStorage(this._storage);

  // ─── Access Token ─────────────────────────────────────────────────────────
  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _SecureKeys.accessToken, value: token);

  Future<String?> getAccessToken() =>
      _storage.read(key: _SecureKeys.accessToken);

  // ─── Refresh Token ────────────────────────────────────────────────────────
  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _SecureKeys.refreshToken, value: token);

  Future<String?> getRefreshToken() =>
      _storage.read(key: _SecureKeys.refreshToken);

  // ─── User ID ──────────────────────────────────────────────────────────────
  Future<void> saveUserId(String id) =>
      _storage.write(key: _SecureKeys.userId, value: id);

  Future<String?> getUserId() => _storage.read(key: _SecureKeys.userId);

  // ─── Save all at once (after login) ──────────────────────────────────────
  Future<void> saveAuthTokens({
    required String accessToken,
    required String refreshToken,
    required String userId,
  }) async {
    await Future.wait([
      saveAccessToken(accessToken),
      saveRefreshToken(refreshToken),
      saveUserId(userId),
    ]);
  }

  // ─── Clear (logout) ───────────────────────────────────────────────────────
  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: _SecureKeys.accessToken),
      _storage.delete(key: _SecureKeys.refreshToken),
      _storage.delete(key: _SecureKeys.userId),
    ]);
  }

  /// Returns true if user has a stored access token.
  Future<bool> get isLoggedIn async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}

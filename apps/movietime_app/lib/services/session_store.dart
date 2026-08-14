import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    this.expiresAt,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['accessToken']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString() ?? '',
      expiresAt: json['expiresAt'] is int ? json['expiresAt'] as int : null,
    );
  }

  final String accessToken;
  final String refreshToken;
  final int? expiresAt;

  bool get isValid => accessToken.isNotEmpty;
}

class SessionStore {
  const SessionStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _accessTokenKey = 'movietime_access_token';
  static const _refreshTokenKey = 'movietime_refresh_token';
  static const _expiresAtKey = 'movietime_expires_at';

  final FlutterSecureStorage _storage;

  Future<void> save(AuthSession session) async {
    await _storage.write(key: _accessTokenKey, value: session.accessToken);
    await _storage.write(key: _refreshTokenKey, value: session.refreshToken);
    if (session.expiresAt != null) {
      await _storage.write(
        key: _expiresAtKey,
        value: session.expiresAt.toString(),
      );
    } else {
      await _storage.delete(key: _expiresAtKey);
    }
  }

  Future<String?> accessToken() {
    return _storage.read(key: _accessTokenKey);
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _expiresAtKey);
  }
}

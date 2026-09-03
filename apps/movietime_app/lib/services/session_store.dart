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

  Future<String?> refreshToken() {
    return _storage.read(key: _refreshTokenKey);
  }

  Future<int?> expiresAt() async {
    final raw = await _storage.read(key: _expiresAtKey);
    if (raw == null) return null;
    return int.tryParse(raw);
  }

  Future<AuthSession?> getSession() async {
    final token = await _storage.read(key: _accessTokenKey);
    if (token == null || token.isEmpty) return null;
    final refresh = await _storage.read(key: _refreshTokenKey);
    final expRaw = await _storage.read(key: _expiresAtKey);
    return AuthSession(
      accessToken: token,
      refreshToken: refresh ?? '',
      expiresAt: expRaw == null ? null : int.tryParse(expRaw),
    );
  }

  Future<bool> hasSession() async {
    final token = await _storage.read(key: _accessTokenKey);
    return token != null && token.isNotEmpty;
  }

  bool isExpired(AuthSession session) {
    final exp = session.expiresAt;
    if (exp == null) return false;
    // expiresAt pode vir em segundos ou milissegundos – normaliza.
    final expMs = exp > 4102444800 ? exp : exp * 1000;
    return DateTime.now().millisecondsSinceEpoch >= expMs;
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _expiresAtKey);
  }
}

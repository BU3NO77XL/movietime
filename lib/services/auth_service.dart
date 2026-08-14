import 'api_client.dart';
import 'auth_models.dart';
import 'session_store.dart';

class AuthService {
  AuthService({ApiClient? apiClient, SessionStore? sessionStore})
    : _sessionStore = sessionStore ?? const SessionStore(),
      _apiClient =
          apiClient ??
          ApiClient(
            accessTokenProvider:
                (sessionStore ?? const SessionStore()).accessToken,
          );

  final ApiClient _apiClient;
  final SessionStore _sessionStore;

  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final data = await _apiClient.postJson(
      '/api/auth/login',
      body: {'email': email, 'password': password},
    );

    await _saveSession(data);
    return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<AuthUser> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    final data = await _apiClient.postJson(
      '/api/auth/signup',
      body: {'name': name, 'email': email, 'password': password},
    );

    await _saveSession(data);
    return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<AuthUser> profile(int userId) async {
    final data = await _apiClient.getJson(
      '/api/auth/profile',
      query: {'userId': '$userId'},
    );

    return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<AuthUser> updateProfile({
    required int userId,
    required String name,
  }) async {
    final data = await _apiClient.patchJson(
      '/api/auth/profile',
      body: {'userId': userId, 'name': name},
    );

    return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<void> savePreferences({
    required int userId,
    required int avatarIndex,
    required List<String> genres,
  }) async {
    await _apiClient.postJson(
      '/api/auth/preferences',
      body: {'userId': userId, 'avatarIndex': avatarIndex, 'genres': genres},
    );
  }

  Future<void> logout() async {
    try {
      await _apiClient.postJson('/api/auth/logout');
    } finally {
      await _sessionStore.clear();
    }
  }

  Future<void> _saveSession(Map<String, dynamic> data) async {
    final sessionJson = data['session'];
    if (sessionJson is! Map<String, dynamic>) return;

    final session = AuthSession.fromJson(sessionJson);
    if (session.isValid) await _sessionStore.save(session);
  }

  void close() => _apiClient.close();
}

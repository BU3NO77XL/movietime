import 'api_client.dart';
import 'auth_models.dart';

class AuthService {
  AuthService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final data = await _apiClient.postJson(
      '/api/auth/login',
      body: {'email': email, 'password': password},
    );

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

  void close() => _apiClient.close();
}

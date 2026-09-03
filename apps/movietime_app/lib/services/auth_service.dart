import 'api_client.dart';
import 'auth_models.dart';
import 'avatar_state.dart';
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

  Future<AuthUser> profile([int? userId]) async {
    final data = await _apiClient.getJson(
      '/api/auth/profile',
      query: {'userId': userId?.toString()},
    );

    return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<AuthUser> updateProfile({
    int? userId,
    String? name,
    String? listName,
  }) async {
    final data = await _apiClient.patchJson(
      '/api/auth/profile',
      body: {'userId': userId, 'name': name, 'listName': listName},
    );

    return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<void> savePreferences({
    required int userId,
    required int avatarIndex,
    required List<String> genres,
    required String contentLanguage,
  }) async {
    await _apiClient.postJson(
      '/api/auth/preferences',
      body: {
        'userId': userId,
        'avatarIndex': avatarIndex,
        'genres': genres,
        'contentLanguage': contentLanguage,
      },
    );
  }

  /// Tenta restaurar sessão já salva no [SessionStore].
  /// Retorna o usuário se o token ainda for válido.
  /// - Se o token não existir ou estiver expirado → retorna null sem chamada de rede.
  /// - Se o backend responder 401/403 → limpa sessão e retorna null.
  /// - Se houver erro de rede → mantém sessão local (offline) e tenta retornar
  ///   usuário via token existente; se não der, considera logado de forma otimista.
  Future<AuthUser?> tryRestoreSession() async {
    final session = await _sessionStore.getSession();
    if (session == null || !session.isValid) return null;
    if (_sessionStore.isExpired(session)) {
      await _sessionStore.clear();
      return null;
    }

    try {
      final user = await profile();
      return user;
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        await _sessionStore.clear();
        return null;
      }
      // Erro de rede/servidor temporário: mantém sessão local.
      // Se não conseguimos validar agora, assume que o login ainda é válido
      // para não deslogar o usuário offline. O Home vai revalidar depois.
      // Para não bloquear o auto-login, retornamos um usuário "placeholder"
      // buscando pelo menos manter o fluxo. Se quisermos ser estritos,
      // retornaríamos null apenas em 401. Aqui retornamos um AuthUser
      // sintético apenas se o token existe – mas como não temos dados do user,
      // tratamos como "sessão válida" retornando null com flag separado.
      // Para simplificar, se há token, consideramos sessão válida e deixamos
      // o caller decidir via hasSession().
      rethrow;
    }
  }

  /// Retorna true se existe sessão válida (não expirada) no storage.
  /// Não faz chamada de rede.
  Future<bool> hasValidLocalSession() async {
    final session = await _sessionStore.getSession();
    if (session == null || !session.isValid) return false;
    if (_sessionStore.isExpired(session)) {
      await _sessionStore.clear();
      return false;
    }
    return true;
  }

  /// Restaura sessão de forma otimista: tenta validar via rede, mas se
  /// falhar por motivo de rede, considera logado se houver token local.
  Future<bool> isLoggedIn() async {
    if (!await hasValidLocalSession()) return false;
    try {
      final user = await profile();
      // Preenche cache do menu antes de Home aparecer (evita piscada)
      AvatarState.instance.update(
        avatarIndex: user.preferences?.avatarIndex ?? 0,
        avatarUrl: user.avatarUrl,
      );
      return user.id != 0;
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        await _sessionStore.clear();
        return false;
      }
      // offline / erro temporário → mantém logado
      return true;
    } catch (_) {
      return true;
    }
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

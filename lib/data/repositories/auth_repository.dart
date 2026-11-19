import '../../core/api/api_client.dart';
import '../../models/user.dart';
import '../session/session_store.dart';

class AuthRepository {
  AuthRepository({required ApiClient apiClient, required SessionStore sessionStore})
      : _api = apiClient,
        _session = sessionStore;

  final ApiClient _api;
  final SessionStore _session;

  Future<AuthResult> register({
    required String username,
    required String password,
  }) async {
    final json = await _api.postObject(
      '/api/auth/register',
      body: {'username': username.trim(), 'password': password},
    );
    return _persist(AuthResult.fromJson(json));
  }

  Future<AuthResult> login({
    required String username,
    required String password,
  }) async {
    final json = await _api.postObject(
      '/api/auth/login',
      body: {'username': username.trim(), 'password': password},
    );
    return _persist(AuthResult.fromJson(json));
  }

  Future<User?> restoreSession() async {
    final token = await _session.readToken();
    if (token == null || token.isEmpty) return null;

    _api.setToken(token);
    try {
      final json = await _api.getObject('/api/auth/me');
      return User.fromJson(json);
    } catch (_) {
      // token expired or server unavailable
      await _session.clear();
      _api.setToken(null);
      return null;
    }
  }

  Future<void> logout() async {
    await _session.clear();
    _api.setToken(null);
  }

  Future<AuthResult> _persist(AuthResult result) async {
    _api.setToken(result.token);
    await _session.saveSession(
      token: result.token,
      userId: result.user.id,
      username: result.user.username,
    );
    return result;
  }
}

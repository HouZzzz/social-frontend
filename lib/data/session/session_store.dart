import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/logging/app_logger.dart';

class SessionStore {
  SessionStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  static const String _tokenKey = 'auth_token';
  static const String _usernameKey = 'auth_username';
  static const String _userIdKey = 'auth_user_id';

  final FlutterSecureStorage _storage;

  Future<String?> readToken() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (e) {
      AppLogger.warn('Не удалось прочитать токен: ${e.runtimeType}');
      return null;
    }
  }

  Future<void> saveSession({
    required String token,
    required int userId,
    required String username,
  }) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userIdKey, value: userId.toString());
    await _storage.write(key: _usernameKey, value: username);
    AppLogger.info('Сессия сохранена для пользователя $username');
  }

  Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _usernameKey);
    AppLogger.info('Сессия удалена');
  }

  Future<String?> readUsername() => _storage.read(key: _usernameKey);

  Future<int?> readUserId() async {
    final raw = await _storage.read(key: _userIdKey);
    return raw == null ? null : int.tryParse(raw);
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/api/api_exception.dart';
import '../../core/logging/app_logger.dart';
import '../../data/repositories/auth_repository.dart';
import '../../models/user.dart';

/// Состояния экрана входа/регистрации.
enum AuthStatus { idle, submitting, authenticated, error }

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._repository);

  final AuthRepository _repository;

  AuthStatus _status = AuthStatus.idle;
  String _error = '';
  User? _user;
  bool _isRegisterMode = false;

  bool _restoring = true;

  AuthStatus get status => _status;
  String get errorMessage => _error;
  User? get user => _user;
  bool get isRegisterMode => _isRegisterMode;
  bool get isSubmitting => _status == AuthStatus.submitting;
  bool get isAuthenticated => _user != null;
  bool get isRestoring => _restoring;

  void toggleMode() {
    _isRegisterMode = !_isRegisterMode;
    _error = '';
    notifyListeners();
  }

  Future<void> restoreSession() async {
    _restoring = true;
    notifyListeners();

    try {
      _user = await _repository.restoreSession();
      _status = _user == null ? AuthStatus.idle : AuthStatus.authenticated;
      if (_user != null) {
        AppLogger.info('Сессия восстановлена для ${_user!.username}');
      }
    } catch (e) {
      AppLogger.warn('Не удалось восстановить сессию: ${e.runtimeType}');
      _status = AuthStatus.idle;
    } finally {
      _restoring = false;
      notifyListeners();
    }
  }

  Future<bool> submit({required String username, required String password}) async {
    if (_status == AuthStatus.submitting) return false;

    _status = AuthStatus.submitting;
    _error = '';
    notifyListeners();

    try {
      final result = _isRegisterMode
          ? await _repository.register(username: username, password: password)
          : await _repository.login(username: username, password: password);

      _user = result.user;
      _status = AuthStatus.authenticated;

      // В лог попадает только логин: ни пароль, ни токен сюда не передаются.
      AppLogger.info('Успешная авторизация: ${result.user.username}');
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _status = AuthStatus.error;
      _error = e.message;
      AppLogger.warn('Ошибка авторизации (${e.statusCode ?? e.type.name})');
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _error = 'Не удалось выполнить вход';
      AppLogger.error('Неожиданная ошибка авторизации', e);
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    _user = null;
    _status = AuthStatus.idle;
    _error = '';
    notifyListeners();
  }

  void clearError() {
    if (_error.isEmpty) return;
    _error = '';
    if (_status == AuthStatus.error) _status = AuthStatus.idle;
    notifyListeners();
  }
}

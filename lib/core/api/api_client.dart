import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../logging/app_logger.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({http.Client? httpClient, String? baseUrl})
      : _http = httpClient ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.apiBase;

  final http.Client _http;
  final String _baseUrl;
  String? _token;

  void setToken(String? token) {
    _token = token;
    AppLogger.debug(_token == null ? 'Токен сброшен' : 'Токен установлен');
  }

  bool get hasToken => _token != null && _token!.isNotEmpty;

  Future<List<dynamic>> getList(String path, {Map<String, String>? query}) async {
    final json = await _send('GET', path, query: query);
    if (json is List) return json;
    throw ApiException.unknown('Ожидался список, пришло ${json.runtimeType}');
  }

  Future<Map<String, dynamic>> getObject(String path, {Map<String, String>? query}) async {
    final json = await _send('GET', path, query: query);
    return _asMap(json);
  }

  Future<Map<String, dynamic>> postObject(String path, {Object? body}) async {
    final json = await _send('POST', path, body: body);
    return _asMap(json);
  }

  Future<void> post(String path) async {
    await _send('POST', path);
  }

  Future<void> delete(String path) async {
    await _send('DELETE', path);
  }

  /// PUT direct t S3 via presigned url.
  Future<void> uploadBytes(
    String uploadUrl,
    List<int> bytes,
    String contentType,
  ) async {
    try {
      final response = await _http
          .put(
            Uri.parse(uploadUrl),
            headers: {'Content-Type': contentType},
            body: bytes,
          )
          .timeout(AppConfig.requestTimeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return;
      }
      throw ApiException(
        type: ApiErrorType.server,
        message: 'Не удалось загрузить изображение (${response.statusCode})',
        statusCode: response.statusCode,
      );
    } on SocketException {
      throw ApiException.network();
    } on TimeoutException {
      throw ApiException.network();
    }
  }

  Future<Object?> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
  }) async {
    final uri = Uri.parse('$_baseUrl$path').replace(
      queryParameters: (query == null || query.isEmpty) ? null : query,
    );

    final headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      if (hasToken) 'Authorization': 'Bearer $_token',
    };

    try {
      final http.Response response = switch (method) {
        'GET' => await _http.get(uri, headers: headers).timeout(AppConfig.requestTimeout),
        'POST' => await _http
            .post(uri, headers: headers, body: body == null ? null : jsonEncode(body))
            .timeout(AppConfig.requestTimeout),
        'DELETE' => await _http.delete(uri, headers: headers).timeout(AppConfig.requestTimeout),
        _ => throw ApiException.unknown('Неподдерживаемый метод $method'),
      };

      return _handleResponse(response, '$method $path');
    } on SocketException {
      AppLogger.warn('Сеть недоступна: $method $path');
      throw ApiException.network();
    } on TimeoutException {
      AppLogger.warn('Таймаут запроса: $method $path');
      throw ApiException.network();
    } on FormatException {
      throw ApiException.unknown('Сервер вернул некорректный ответ');
    }
  }

  Object? _handleResponse(http.Response response, String label) {
    final status = response.statusCode;
    final rawBody = response.body;

    if (status >= 200 && status < 300) {
      if (rawBody.isEmpty) return null;
      return jsonDecode(utf8.decode(response.bodyBytes));
    }

    String message = 'Ошибка сервера ($status)';
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map && decoded['message'] is String) {
        final serverMessage = decoded['message'] as String;
        if (serverMessage.isNotEmpty) message = serverMessage;
      }
    } on FormatException {
      // not json 
    }

    AppLogger.warn('$label -> $status: $message');

    final type = switch (status) {
      400 => ApiErrorType.validation,
      401 => ApiErrorType.unauthorized,
      403 => ApiErrorType.forbidden,
      404 => ApiErrorType.notFound,
      >= 500 => ApiErrorType.server,
      _ => ApiErrorType.unknown,
    };

    throw ApiException(type: type, message: message, statusCode: status);
  }

  Map<String, dynamic> _asMap(Object? json) {
    if (json is Map) return json.cast<String, dynamic>();
    throw ApiException.unknown('Ожидался объект, пришло ${json.runtimeType}');
  }

  void dispose() => _http.close();
}

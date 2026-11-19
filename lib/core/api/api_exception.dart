/// Тип ошибки определяет, что показать пользователю.
enum ApiErrorType {
  /// Нет соединения, таймаут, DNS — сеть недоступна.
  network,

  /// 401: токен истёк или неверный пароль.
  unauthorized,

  /// 400: сервер отклонил данные (валидация).
  validation,

  /// 403: действие запрещено (например, удаление чужого поста).
  forbidden,

  /// 404: объект не найден.
  notFound,

  /// 5xx и прочие ответы сервера.
  server,

  /// Не удалось разобрать ответ.
  unknown,
}

class ApiException implements Exception {
  const ApiException({
    required this.type,
    required this.message,
    this.statusCode,
  });

  final ApiErrorType type;
  final String message;
  final int? statusCode;

  factory ApiException.network() => const ApiException(
        type: ApiErrorType.network,
        message: 'Нет соединения с сервером. Проверьте интернет и попробуйте снова.',
      );

  factory ApiException.unknown([String? details]) => ApiException(
        type: ApiErrorType.unknown,
        message: details ?? 'Что-то пошло не так. Попробуйте позже.',
      );

  bool get isNetwork => type == ApiErrorType.network;
  bool get isUnauthorized => type == ApiErrorType.unauthorized;

  @override
  String toString() => message;
}

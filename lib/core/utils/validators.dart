class Validators {
  const Validators._();

  static const int maxPostLength = 280;
  static const int maxCommentLength = 500;
  static const int minPasswordLength = 8;
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 32;

  static String? postContent(String? value) {
    final text = value ?? '';

    if (text.trim().isEmpty) {
      return 'Текст поста не может быть пустым';
    }
    if (text.length > maxPostLength) {
      return 'Текст поста не может превышать $maxPostLength символов';
    }
    return null;
  }

  static String? commentText(String? value) {
    final text = value ?? '';

    if (text.trim().isEmpty) {
      return 'Комментарий не может быть пустым';
    }
    if (text.length > maxCommentLength) {
      return 'Комментарий не может превышать $maxCommentLength символов';
    }
    return null;
  }

  static String? username(String? value) {
    final text = (value ?? '').trim();

    if (text.isEmpty) {
      return 'Введите имя пользователя';
    }
    if (text.length < minUsernameLength || text.length > maxUsernameLength) {
      return 'Имя пользователя должно быть от $minUsernameLength до $maxUsernameLength символов';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(text)) {
      return 'Только латиница, цифры и подчёркивание';
    }
    return null;
  }

  static String? password(String? value) {
    final text = value ?? '';

    if (text.isEmpty) {
      return 'Введите пароль';
    }
    if (text.length < minPasswordLength) {
      return 'Пароль должен быть не короче $minPasswordLength символов';
    }
    if (!RegExp(r'[A-Za-z]').hasMatch(text)) {
      return 'Пароль должен содержать хотя бы одну букву';
    }
    if (!RegExp(r'\d').hasMatch(text)) {
      return 'Пароль должен содержать хотя бы одну цифру';
    }
    return null;
  }

  static String? loginPassword(String? value) {
    if ((value ?? '').isEmpty) {
      return 'Введите пароль';
    }
    return null;
  }

  static int remainingPostChars(String value) => maxPostLength - value.length;
}

class User {
  const User({required this.id, required this.username});

  final int id;
  final String username;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: _asInt(json['id']),
      username: (json['username'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'username': username};
}

class AuthResult {
  const AuthResult({required this.token, required this.user});

  final String token;
  final User user;

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      token: (json['token'] as String?) ?? '',
      user: User.fromJson((json['user'] as Map?)?.cast<String, dynamic>() ?? {}),
    );
  }
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

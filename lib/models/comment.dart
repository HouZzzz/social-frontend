class Comment {
  const Comment({
    required this.id,
    required this.text,
    required this.authorUsername,
    required this.createdAt,
  });

  final int id;
  final String text;
  final String authorUsername;
  final DateTime createdAt;

  factory Comment.fromJson(Map<String, dynamic> json) {
    final raw = json['createdAt'];
    final parsed = raw is String ? DateTime.tryParse(raw) : null;

    return Comment(
      id: _asInt(json['id']),
      text: (json['text'] as String?) ?? '',
      authorUsername: (json['authorUsername'] as String?) ?? '',
      createdAt: (parsed ?? DateTime.now()).toLocal(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'authorUsername': authorUsername,
        'createdAt': createdAt.toUtc().toIso8601String(),
      };
}

class PresignResult {
  const PresignResult({
    required this.uploadUrl,
    required this.objectKey,
    required this.publicUrl,
  });

  final String uploadUrl;
  final String objectKey;
  final String publicUrl;

  factory PresignResult.fromJson(Map<String, dynamic> json) {
    return PresignResult(
      uploadUrl: (json['uploadUrl'] as String?) ?? '',
      objectKey: (json['objectKey'] as String?) ?? '',
      publicUrl: (json['publicUrl'] as String?) ?? '',
    );
  }
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

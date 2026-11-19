import 'package:social_frontend/core/utils/validators.dart';

class Post {
  const Post({
    required this.id,
    required this.content,
    required this.authorUsername,
    required this.createdAt,
    required this.likesCount,
    required this.commentsCount,
    required this.isLikedByMe,
    this.imageUrl,
  });

  final int id;
  final String content;
  final String authorUsername;
  final DateTime createdAt;
  final int likesCount;
  final int commentsCount;
  final bool isLikedByMe;
  final String? imageUrl;

  factory Post.fromJson(Map<String, dynamic> json) {
    final raw = json['createdAt'];
    final parsed = raw is String ? DateTime.tryParse(raw) : null;

    return Post(
      id: _asInt(json['id']),
      content: (json['content'] as String?) ?? '',
      authorUsername: (json['authorUsername'] as String?) ?? '',
      createdAt: (parsed ?? DateTime.now()).toLocal(),
      likesCount: _asInt(json['likesCount']),
      commentsCount: _asInt(json['commentsCount']),
      isLikedByMe: (json['isLikedByMe'] as bool?) ?? false,
      imageUrl: _nullableString(json['imageUrl']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'authorUsername': authorUsername,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'likesCount': likesCount,
        'commentsCount': commentsCount,
        'isLikedByMe': isLikedByMe,
        'imageUrl': imageUrl,
      };

  // copy with update likes count 
  Post copyWith({
    String? content,
    int? likesCount,
    int? commentsCount,
    bool? isLikedByMe,
    String? imageUrl,
  }) {
    return Post(
      id: id,
      content: content ?? this.content,
      authorUsername: authorUsername,
      createdAt: createdAt,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  String? get validationError => Validators.postContent(content);

  Map<String, Object?> toDbRow({required int position}) => {
        'id': id,
        'content': content,
        'author_username': authorUsername,
        'created_at': createdAt.toUtc().toIso8601String(),
        'likes_count': likesCount,
        'comments_count': commentsCount,
        'is_liked': isLikedByMe ? 1 : 0,
        'image_url': imageUrl,
        'position': position,
      };

  factory Post.fromDbRow(Map<String, Object?> row) {
    final createdAt = DateTime.tryParse((row['created_at'] as String?) ?? '');

    return Post(
      id: (row['id'] as int?) ?? 0,
      content: (row['content'] as String?) ?? '',
      authorUsername: (row['author_username'] as String?) ?? '',
      createdAt: (createdAt ?? DateTime.now()).toLocal(),
      likesCount: (row['likes_count'] as int?) ?? 0,
      commentsCount: (row['comments_count'] as int?) ?? 0,
      isLikedByMe: ((row['is_liked'] as int?) ?? 0) == 1,
      imageUrl: row['image_url'] as String?,
    );
  }
}

class LikeResult {
  const LikeResult({
    required this.postId,
    required this.likesCount,
    required this.isLikedByMe,
  });

  final int postId;
  final int likesCount;
  final bool isLikedByMe;

  factory LikeResult.fromJson(Map<String, dynamic> json) {
    return LikeResult(
      postId: _asInt(json['postId']),
      likesCount: _asInt(json['likesCount']),
      isLikedByMe: (json['isLikedByMe'] as bool?) ?? false,
    );
  }
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

String? _nullableString(Object? value) {
  if (value is String && value.isNotEmpty) return value;
  return null;
}

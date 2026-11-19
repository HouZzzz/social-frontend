import '../../core/api/api_client.dart';
import '../../models/comment.dart';
import '../../models/post.dart';

enum PostFilter {
  all('all', 'Все посты'),
  my('my', 'Мои посты'),
  liked('liked', 'Понравившиеся');

  const PostFilter(this.param, this.label);

  final String param;
  final String label;
}

abstract class PostRepository {
  Future<List<Post>> fetchFeed({
    String search = '',
    PostFilter filter = PostFilter.all,
    int limit = 50,
    int offset = 0,
  });

  Future<Post> createPost({required String content, String? imageKey});

  Future<LikeResult> toggleLike(int postId);

  Future<void> deletePost(int postId);

  Future<PresignResult> presignImage(String contentType);

  Future<void> uploadImage(String uploadUrl, List<int> bytes, String contentType);
}

class HttpPostRepository implements PostRepository {
  HttpPostRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<Post>> fetchFeed({
    String search = '',
    PostFilter filter = PostFilter.all,
    int limit = 50,
    int offset = 0,
  }) async {
    final json = await _api.getList(
      '/api/posts',
      query: {
        if (search.trim().isNotEmpty) 'search': search.trim(),
        'filter': filter.param,
        'limit': '$limit',
        'offset': '$offset',
      },
    );
    return json
        .whereType<Map>()
        .map((item) => Post.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<Post> createPost({required String content, String? imageKey}) async {
    final json = await _api.postObject(
      '/api/posts',
      body: {
        'content': content.trim(),
        if (imageKey != null && imageKey.isNotEmpty) 'imageKey': imageKey,
      },
    );
    return Post.fromJson(json);
  }

  @override
  Future<LikeResult> toggleLike(int postId) async {
    final json = await _api.postObject('/api/posts/$postId/like');
    return LikeResult.fromJson(json);
  }

  @override
  Future<void> deletePost(int postId) => _api.delete('/api/posts/$postId');

  @override
  Future<PresignResult> presignImage(String contentType) async {
    final json = await _api.postObject(
      '/api/uploads/presign',
      body: {'contentType': contentType},
    );
    return PresignResult.fromJson(json);
  }

  @override
  Future<void> uploadImage(String uploadUrl, List<int> bytes, String contentType) {
    return _api.uploadBytes(uploadUrl, bytes, contentType);
  }
}

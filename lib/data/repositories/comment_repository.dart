import '../../core/api/api_client.dart';
import '../../models/comment.dart';

abstract class CommentRepository {
  Future<List<Comment>> fetchComments(int postId);

  Future<Comment> addComment(int postId, String text);
}

class HttpCommentRepository implements CommentRepository {
  HttpCommentRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<Comment>> fetchComments(int postId) async {
    final json = await _api.getList('/api/posts/$postId/comments');
    return json
        .whereType<Map>()
        .map((item) => Comment.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<Comment> addComment(int postId, String text) async {
    final json = await _api.postObject(
      '/api/posts/$postId/comments',
      body: {'text': text.trim()},
    );
    return Comment.fromJson(json);
  }
}

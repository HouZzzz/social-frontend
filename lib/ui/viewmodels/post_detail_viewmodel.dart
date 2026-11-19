import 'package:flutter/foundation.dart';

import '../../core/api/api_exception.dart';
import '../../core/logging/app_logger.dart';
import '../../core/utils/validators.dart';
import '../../data/repositories/comment_repository.dart';
import '../../data/repositories/post_repository.dart';
import '../../models/comment.dart';
import '../../models/post.dart';
import '../state/detail_state.dart';

class PostDetailViewModel extends ChangeNotifier {
  PostDetailViewModel({
    required Post post,
    required CommentRepository commentRepository,
    required PostRepository postRepository,
  })  : _post = post,
        _commentsRepo = commentRepository,
        _postsRepo = postRepository;

  final CommentRepository _commentsRepo;
  final PostRepository _postsRepo;  Post _post;
  DetailState _state = DetailState.initial;
  List<Comment> _comments = const [];
  String _error = '';
  bool _sending = false;
  bool _likePending = false;

  Post get post => _post;
  DetailState get state => _state;
  List<Comment> get comments => List.unmodifiable(_comments);
  String get errorMessage => _error;
  bool get isSending => _sending;
  bool get isLikePending => _likePending;

  String? validateComment(String text) => Validators.commentText(text);

  Future<void> load() async {
    _state = DetailState.loading;
    _error = '';
    notifyListeners();

    AppLogger.info('Загрузка комментариев поста ${_post.id}');

    try {
      _comments = await _commentsRepo.fetchComments(_post.id);
      _state = DetailState.loaded;
      AppLogger.info('Комментарии поста ${_post.id}: ${_comments.length}');
    } on ApiException catch (e) {
      _state = DetailState.error;
      _error = e.message;
      AppLogger.warn('Ошибка загрузки комментариев: ${e.message}');
    } catch (e) {
      _state = DetailState.error;
      _error = 'Не удалось загрузить комментарии';
      AppLogger.error('Неожиданная ошибка комментариев', e);
    }

    notifyListeners();
  }

  Future<String?> addComment(String text) async {
    if (_sending) return null;

    final validation = validateComment(text);
    if (validation != null) return validation;

    _sending = true;
    notifyListeners();

    try {
      final comment = await _commentsRepo.addComment(_post.id, text);
      _comments = [..._comments, comment];
      _post = _post.copyWith(commentsCount: _post.commentsCount + 1);
      _state = DetailState.loaded;
      AppLogger.info('Комментарий добавлен к посту ${_post.id}');
      return null;
    } on ApiException catch (e) {
      AppLogger.warn('Ошибка отправки комментария: ${e.message}');
      return e.message;
    } catch (e) {
      AppLogger.error('Неожиданная ошибка отправки комментария', e);
      return 'Не удалось отправить комментарий';
    } finally {
      _sending = false;
      notifyListeners();
    }
  }

  Future<void> toggleLike() async {
    if (_likePending) return;

    final before = _post;
    _post = before.copyWith(
      isLikedByMe: !before.isLikedByMe,
      likesCount: before.likesCount + (before.isLikedByMe ? -1 : 1),
    );
    _likePending = true;
    notifyListeners();

    try {
      final result = await _postsRepo.toggleLike(_post.id);
      _post = _post.copyWith(
        isLikedByMe: result.isLikedByMe,
        likesCount: result.likesCount,
      );
    } catch (e) {
      _post = before;
      AppLogger.warn('Не удалось изменить лайк: $e');
    } finally {
      _likePending = false;
      notifyListeners();
    }
  }
}

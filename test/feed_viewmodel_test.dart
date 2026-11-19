import 'package:flutter_test/flutter_test.dart';
import 'package:social_frontend/core/api/api_exception.dart';
import 'package:social_frontend/data/repositories/feed_cache_repository.dart';
import 'package:social_frontend/data/repositories/post_repository.dart';
import 'package:social_frontend/models/comment.dart';
import 'package:social_frontend/models/post.dart';
import 'package:social_frontend/ui/state/feed_state.dart';
import 'package:social_frontend/ui/viewmodels/feed_viewmodel.dart';

/// FakePostRepository — главная идея теста: ViewModel не знает,
/// что за репозиторий перед ним. Подставляем фейк и проверяем переходы состояний.
class FakePostRepository implements PostRepository {
  FakePostRepository({this.posts = const [], this.error});

  List<Post> posts;
  ApiException? error;
  int fetchCalls = 0;
  int toggleCalls = 0;
  LikeResult toggleResult = const LikeResult(
    postId: 1,
    likesCount: 1,
    isLikedByMe: true,
  );

  @override
  Future<List<Post>> fetchFeed({
    String search = '',
    PostFilter filter = PostFilter.all,
    int limit = 50,
    int offset = 0,
  }) async {
    fetchCalls++;
    final failure = error;
    if (failure != null) throw failure;
    return posts;
  }

  @override
  Future<LikeResult> toggleLike(int postId) async {
    toggleCalls++;
    return toggleResult;
  }

  @override
  Future<Post> createPost({required String content, String? imageKey}) async =>
      _buildPost(id: 99, content: content);

  @override
  Future<void> deletePost(int postId) async {}

  @override
  Future<PresignResult> presignImage(String contentType) async =>
      const PresignResult(uploadUrl: '', objectKey: '', publicUrl: '');

  @override
  Future<void> uploadImage(String uploadUrl, List<int> bytes, String contentType) async {}
}

class FakeCacheRepository implements FeedCacheRepository {
  FakeCacheRepository({this.cached = const []});

  List<Post> cached;
  int saveCalls = 0;
  int clearCalls = 0;

  @override
  Future<void> save(List<Post> posts) async {
    saveCalls++;
    cached = posts;
  }

  @override
  Future<List<Post>> load() async => cached;

  @override
  Future<void> clear() async {
    clearCalls++;
    cached = const [];
  }

  @override
  Future<DateTime?> lastUpdatedAt() async => null;
}

Post _buildPost({
  int id = 1,
  String content = 'текст поста',
  String author = 'alex_dev',
  bool liked = false,
  int likes = 0,
}) {
  return Post(
    id: id,
    content: content,
    authorUsername: author,
    createdAt: DateTime(2026, 11, 18, 12),
    likesCount: likes,
    commentsCount: 0,
    isLikedByMe: liked,
  );
}

void main() {
  group('FeedViewModel.load', () {
    test('переходит loading -> loaded и заполняет список', () async {
      final repository = FakePostRepository(
        posts: [_buildPost(id: 1), _buildPost(id: 2)],
      );
      final viewModel = FeedViewModel(
        postRepository: repository,
        cacheRepository: FakeCacheRepository(),
      );

      expect(viewModel.state, FeedState.initial);

      final future = viewModel.load();
      expect(viewModel.state, FeedState.loading);

      await future;

      expect(viewModel.state, FeedState.loaded);
      expect(viewModel.posts, hasLength(2));
      expect(viewModel.posts.first.id, 1);
    });

    test('успешная загрузка кладёт ленту в кэш', () async {
      final cache = FakeCacheRepository();
      final viewModel = FeedViewModel(
        postRepository: FakePostRepository(posts: [_buildPost()]),
        cacheRepository: cache,
      );

      await viewModel.load();

      expect(cache.saveCalls, 1);
      expect(cache.cached, hasLength(1));
    });

    test('ошибка сети переходит в loaded из кэша и помечает оффлайн', () async {
      final cache = FakeCacheRepository(cached: [_buildPost(id: 5)]);
      final viewModel = FeedViewModel(
        postRepository: FakePostRepository(error: ApiException.network()),
        cacheRepository: cache,
      );

      await viewModel.load();

      expect(viewModel.state, FeedState.loaded);
      expect(viewModel.isOffline, isTrue);
      expect(viewModel.posts.single.id, 5);
    });

    test('ошибка сети без кэша даёт state == error', () async {
      final viewModel = FeedViewModel(
        postRepository: FakePostRepository(error: ApiException.network()),
        cacheRepository: FakeCacheRepository(),
      );

      await viewModel.load();

      expect(viewModel.state, FeedState.error);
      expect(viewModel.errorMessage, isNotEmpty);
      expect(viewModel.isOffline, isFalse);
    });

    test('ошибка валидации с сервера не подменяется кэшем', () async {
      final viewModel = FeedViewModel(
        postRepository: FakePostRepository(
          error: const ApiException(
            type: ApiErrorType.server,
            message: 'Внутренняя ошибка сервера',
            statusCode: 500,
          ),
        ),
        cacheRepository: FakeCacheRepository(cached: [_buildPost()]),
      );

      await viewModel.load();

      expect(viewModel.state, FeedState.error);
      expect(viewModel.errorMessage, contains('Внутренняя'));
    });
  });

  group('FeedViewModel.toggleLike', () {
    test('меняет счётчик оптимистично и подтверждает ответом сервера', () async {
      final repository = FakePostRepository(posts: [_buildPost(id: 1, likes: 2)])
        ..toggleResult = const LikeResult(
          postId: 1,
          likesCount: 3,
          isLikedByMe: true,
        );

      final viewModel = FeedViewModel(
        postRepository: repository,
        cacheRepository: FakeCacheRepository(),
      );

      await viewModel.load();
      expect(viewModel.posts.single.likesCount, 2);

      await viewModel.toggleLike(1);

      expect(viewModel.posts.single.likesCount, 3);
      expect(viewModel.posts.single.isLikedByMe, isTrue);
      expect(repository.toggleCalls, 1);
    });

    test('повторный вызов во время запроса не отправляет второй', () async {
      final repository = FakePostRepository(posts: [_buildPost(id: 1)]);
      final viewModel = FeedViewModel(
        postRepository: repository,
        cacheRepository: FakeCacheRepository(),
      );

      await viewModel.load();

      final first = viewModel.toggleLike(1);
      final second = viewModel.toggleLike(1);
      await Future.wait([first, second]);

      expect(repository.toggleCalls, 1);
    });
  });

  group('FeedViewModel.deletePost', () {
    test('удаляет пост из списка', () async {
      final viewModel = FeedViewModel(
        postRepository: FakePostRepository(
          posts: [_buildPost(id: 1), _buildPost(id: 2)],
        ),
        cacheRepository: FakeCacheRepository(),
      );

      await viewModel.load();
      await viewModel.deletePost(1);

      expect(viewModel.posts, hasLength(1));
      expect(viewModel.posts.single.id, 2);
    });
  });

  group('FeedViewModel.prependPost', () {
    test('новый пост появляется первым', () async {
      final viewModel = FeedViewModel(
        postRepository: FakePostRepository(posts: [_buildPost(id: 1)]),
        cacheRepository: FakeCacheRepository(),
      );

      await viewModel.load();
      viewModel.prependPost(_buildPost(id: 2, content: 'новый'));

      expect(viewModel.posts.first.id, 2);
      expect(viewModel.posts, hasLength(2));
    });
  });
}

import '../../models/post.dart';
import '../local/feed_cache_dao.dart';

abstract class FeedCacheRepository {
  Future<void> save(List<Post> posts);

  Future<List<Post>> load();

  Future<void> clear();

  Future<DateTime?> lastUpdatedAt();
}

class SqfliteFeedCacheRepository implements FeedCacheRepository {
  SqfliteFeedCacheRepository(this._dao);

  final FeedCacheDao _dao;

  @override
  Future<void> save(List<Post> posts) => _dao.replaceAll(posts);

  @override
  Future<List<Post>> load() => _dao.queryAll();

  @override
  Future<void> clear() => _dao.clearAll();

  @override
  Future<DateTime?> lastUpdatedAt() => _dao.lastUpdatedAt();
}

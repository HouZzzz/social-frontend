import 'package:flutter/foundation.dart';

import '../../data/repositories/feed_cache_repository.dart';
import '../../data/repositories/post_repository.dart';

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel({
    required FeedCacheRepository cacheRepository,
    required PostRepository postRepository,
    required this.username,
  })  : _cache = cacheRepository,
        _posts = postRepository;

  final FeedCacheRepository _cache;
  final PostRepository _posts;

  final String username;

  String _statusMessage = '';
  int _myPostsCount = 0;
  bool _loadingCount = false;

  String get statusMessage => _statusMessage;
  int get myPostsCount => _myPostsCount;
  bool get isLoadingCount => _loadingCount;

  Future<void> loadMyPostsCount() async {
    _loadingCount = true;
    notifyListeners();

    try {
      final posts = await _posts.fetchFeed(filter: PostFilter.my, limit: 100);
      _myPostsCount = posts.length;
    } catch (_) {
      _myPostsCount = 0;
    } finally {
      _loadingCount = false;
      notifyListeners();
    }
  }

  Future<void> clearCache() async {
    await _cache.clear();
    _statusMessage = 'Кэш ленты очищен';
    notifyListeners();
  }

  void showMessage(String message) {
    _statusMessage = message;
    notifyListeners();
  }
}

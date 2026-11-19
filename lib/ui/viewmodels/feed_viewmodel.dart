import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/api/api_exception.dart';
import '../../core/logging/app_logger.dart';
import '../../data/repositories/feed_cache_repository.dart';
import '../../data/repositories/post_repository.dart';
import '../../models/post.dart';
import '../state/feed_state.dart';

class FeedViewModel extends ChangeNotifier {
  FeedViewModel({
    required PostRepository postRepository,
    required FeedCacheRepository cacheRepository,
  })  : _posts = postRepository,
        _cache = cacheRepository;

  final PostRepository _posts;
  final FeedCacheRepository _cache;

  FeedState _state = FeedState.initial;
  List<Post> _items = const [];
  String _error = '';
  String _search = '';
  PostFilter _filter = PostFilter.all;

  bool _isOffline = false;

  final Set<int> _pendingLikeIds = {};

  int _requestId = 0;
  Timer? _searchDebounce;

  FeedState get state => _state;
  List<Post> get posts => List.unmodifiable(_items);
  String get errorMessage => _error;
  String get searchQuery => _search;
  PostFilter get filter => _filter;
  bool get isOffline => _isOffline;
  bool get isEmpty => _state == FeedState.loaded && _items.isEmpty;
  bool isLikePending(int postId) => _pendingLikeIds.contains(postId);

  Future<void> load() => _load();

  Future<void> refresh() => _load();

  void onSearchChanged(String value) {
    _search = value;
    notifyListeners();

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _load();
    });
  }

  void setFilter(PostFilter filter) {
    if (_filter == filter) return;
    _filter = filter;
    notifyListeners();
    _load();
  }

  Future<void> _load() async {
    final requestId = ++_requestId;
    _state = FeedState.loading;
    _error = '';
    notifyListeners();

    AppLogger.info('Загрузка ленты: filter=${_filter.param} search="${_search.trim()}"');

    try {
      final loaded = await _posts.fetchFeed(search: _search, filter: _filter);

      if (requestId != _requestId) return; // устаревший ответ

      _items = loaded;
      _state = FeedState.loaded;
      _isOffline = false;
      AppLogger.info('Лента загружена: ${loaded.length} постов');

      if (_filter == PostFilter.all && _search.trim().isEmpty) {
        await _cache.save(loaded);
      }
    } on ApiException catch (e) {
      if (requestId != _requestId) return;

      AppLogger.warn('Ошибка загрузки ленты: ${e.message}');

      if (e.isNetwork) {
        await _fallbackToCache(e.message);
      } else {
        _state = FeedState.error;
        _error = e.message;
      }
    } catch (e) {
      if (requestId != _requestId) return;
      AppLogger.error('Неожиданная ошибка ленты', e);
      _state = FeedState.error;
      _error = 'Не удалось загрузить ленту';
    }

    notifyListeners();
  }

  Future<void> _fallbackToCache(String networkMessage) async {
    try {
      final cached = await _cache.load();

      if (cached.isEmpty) {
        _state = FeedState.error;
        _error = networkMessage;
        return;
      }

      _items = cached;
      _state = FeedState.loaded;
      _isOffline = true;
      AppLogger.info('Показана лента из кэша: ${cached.length} постов');
    } catch (e) {
      AppLogger.error('Не удалось прочитать кэш ленты', e);
      _state = FeedState.error;
      _error = networkMessage;
    }
  }

  Future<void> toggleLike(int postId) async {
    if (_pendingLikeIds.contains(postId)) return;

    final index = _items.indexWhere((post) => post.id == postId);
    if (index == -1) return;

    final before = _items[index];
    final optimistic = before.copyWith(
      isLikedByMe: !before.isLikedByMe,
      likesCount: before.likesCount + (before.isLikedByMe ? -1 : 1),
    );

    _items = [..._items]..[index] = optimistic;
    _pendingLikeIds.add(postId);
    notifyListeners();

    try {
      final result = await _posts.toggleLike(postId);
      final current = _items.indexWhere((post) => post.id == postId);
      if (current != -1) {
        _items = [..._items]
          ..[current] = _items[current].copyWith(
            isLikedByMe: result.isLikedByMe,
            likesCount: result.likesCount,
          );
      }
    } catch (e) {
      final current = _items.indexWhere((post) => post.id == postId);
      if (current != -1) {
        _items = [..._items]..[current] = before;
      }
      AppLogger.warn('Не удалось поставить лайк посту $postId: $e');
    } finally {
      _pendingLikeIds.remove(postId);
      notifyListeners();
    }
  }

  Future<void> deletePost(int postId) async {
    final previous = _items;
    _items = _items.where((post) => post.id != postId).toList();
    notifyListeners();

    try {
      await _posts.deletePost(postId);
      AppLogger.info('Пост $postId удалён');
    } catch (e) {
      _items = previous;
      notifyListeners();
      rethrow;
    }
  }

  void prependPost(Post post) {
    if (_items.any((item) => item.id == post.id)) return;
    _items = [post, ..._items];
    _state = FeedState.loaded;
    notifyListeners();
  }

  Future<void> logout() async {
    _items = const [];
    _state = FeedState.initial;
    _isOffline = false;
    _search = '';
    _filter = PostFilter.all;
    notifyListeners();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}

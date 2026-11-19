import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../data/repositories/comment_repository.dart';
import '../../data/repositories/feed_cache_repository.dart';
import '../../data/repositories/post_repository.dart';
import '../../models/post.dart';
import '../state/feed_state.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/compose_viewmodel.dart';
import '../viewmodels/feed_viewmodel.dart';
import '../viewmodels/post_detail_viewmodel.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../widgets/post_card.dart';
import '../widgets/state_views.dart';
import 'compose_screen.dart';
import 'post_detail_screen.dart';
import 'profile_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _searchController = TextEditingController();
  bool _initialised = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initialised) {
      _initialised = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<FeedViewModel>().load();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openCompose() async {
    final postRepository = context.read<PostRepository>();

    final created = await Navigator.of(context).push<Post>(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => ComposeViewModel(postRepository: postRepository),
          child: const ComposeScreen(),
        ),
      ),
    );

    if (created != null && mounted) {
      context.read<FeedViewModel>().prependPost(created);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Пост опубликован')));
    }
  }

  void _openDetail(Post post) {
    final commentRepository = context.read<CommentRepository>();
    final postRepository = context.read<PostRepository>();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => PostDetailViewModel(
            post: post,
            commentRepository: commentRepository,
            postRepository: postRepository,
          ),
          child: PostDetailScreen(post: post),
        ),
      ),
    );
  }

  void _openProfile() {
    final cacheRepository = context.read<FeedCacheRepository>();
    final postRepository = context.read<PostRepository>();
    final username = context.read<AuthViewModel>().user?.username ?? '';

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => ProfileViewModel(
            cacheRepository: cacheRepository,
            postRepository: postRepository,
            username: username,
          )..loadMyPostsCount(),
          child: const ProfileScreen(),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Post post) async {
    final viewModel = context.read<FeedViewModel>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удалить пост?'),
        content: const Text('Действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await viewModel.deletePost(post.id);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<FeedViewModel>();
    final currentUsername = context.select<AuthViewModel, String?>(
      (auth) => auth.user?.username,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Лента'),
        actions: [
          IconButton(
            tooltip: 'Профиль',
            icon: const Icon(Icons.person_outline),
            onPressed: _openProfile,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(112),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onChanged: viewModel.onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Поиск по тексту поста',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: viewModel.searchQuery.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            tooltip: 'Очистить',
                            onPressed: () {
                              _searchController.clear();
                              viewModel.onSearchChanged('');
                            },
                          ),
                  ),
                ),
              ),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: PostFilter.values.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final filter = PostFilter.values[index];
                    return ChoiceChip(
                      label: Text(filter.label),
                      selected: viewModel.filter == filter,
                      showCheckmark: false,
                      onSelected: (_) => viewModel.setFilter(filter),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCompose,
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Написать'),
      ),
      body: Column(
        children: [
          if (viewModel.isOffline)
            OfflineBanner(onRetry: viewModel.refresh),
          Expanded(child: _buildBody(viewModel, currentUsername)),
        ],
      ),
    );
  }

  Widget _buildBody(FeedViewModel viewModel, String? currentUsername) {
    switch (viewModel.state) {
      case FeedState.initial:
      case FeedState.loading:
        if (viewModel.posts.isEmpty) {
          return const LoadingView(message: 'Загружаем ленту…');
        }
        // Обновление поверх уже показанных постов — лента не мигает.
        return _buildList(viewModel, currentUsername);

      case FeedState.error:
        return ErrorView(
          message: viewModel.errorMessage,
          onRetry: viewModel.refresh,
        );

      case FeedState.loaded:
        if (viewModel.isEmpty) {
          return EmptyView(
            icon: viewModel.searchQuery.isEmpty
                ? Icons.article_outlined
                : Icons.search_off,
            message: viewModel.searchQuery.isEmpty
                ? 'Пока нет постов. Напишите первый!'
                : 'Ничего не найдено по запросу «${viewModel.searchQuery}»',
            actionLabel: viewModel.searchQuery.isEmpty ? 'Написать пост' : null,
            onAction: viewModel.searchQuery.isEmpty ? _openCompose : null,
          );
        }
        return RefreshIndicator(
          onRefresh: viewModel.refresh,
          child: _buildList(viewModel, currentUsername),
        );
    }
  }

  Widget _buildList(FeedViewModel viewModel, String? currentUsername) {
    final posts = viewModel.posts;

    // ListView.builder — в требованиях явно указан.
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];

        return PostCard(
          key: ValueKey(post.id),
          post: post,
          isLikedPending: viewModel.isLikePending(post.id),
          canDelete: currentUsername != null && post.authorUsername == currentUsername,
          onTap: () => _openDetail(post),
          onLike: () => viewModel.toggleLike(post.id),
          onDelete: () => _confirmDelete(post),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/date_formatter.dart';
import '../../models/comment.dart';
import '../../models/post.dart';
import '../state/detail_state.dart';
import '../viewmodels/post_detail_viewmodel.dart';
import '../widgets/state_views.dart';

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({super.key, required this.post});

  final Post post;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentController = TextEditingController();
  bool _initialised = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initialised) {
      _initialised = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<PostDetailViewModel>().load();
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final viewModel = context.read<PostDetailViewModel>();
    final text = _commentController.text;

    final error = await viewModel.addComment(text);
    if (!mounted) return;

    if (error == null) {
      _commentController.clear();
      FocusScope.of(context).unfocus();
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PostDetailViewModel>();
    final theme = Theme.of(context);
    final post = viewModel.post;

    return Scaffold(
      appBar: AppBar(title: const Text('Пост')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              children: [
                _PostHeader(post: post, viewModel: viewModel),
                const SizedBox(height: 16),
                Text(post.content, style: theme.textTheme.bodyLarge),
                if (post.imageUrl != null) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      post.imageUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) =>
                          progress == null ? child : const LoadingView(),
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 160,
                        alignment: Alignment.center,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      DateFormatter.full(post.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),
                Row(
                  children: [
                    Text(
                      'Комментарии',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${post.commentsCount}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._buildComments(viewModel),
              ],
            ),
          ),
          _CommentInput(
            controller: _commentController,
            viewModel: viewModel,
            onSend: _send,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildComments(PostDetailViewModel viewModel) {
    switch (viewModel.state) {
      case DetailState.initial:
      case DetailState.loading:
        return const [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: LoadingView(message: 'Загружаем комментарии…'),
          ),
        ];

      case DetailState.error:
        return [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: ErrorView(
              message: viewModel.errorMessage,
              onRetry: viewModel.load,
            ),
          ),
        ];

      case DetailState.loaded:
        if (viewModel.comments.isEmpty) {
          return const [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: EmptyView(
                icon: Icons.mode_comment_outlined,
                message: 'Комментариев пока нет. Будьте первым!',
              ),
            ),
          ];
        }
        return viewModel.comments.map((comment) => _CommentTile(comment: comment)).toList();
    }
  }
}

class _PostHeader extends StatelessWidget {
  const _PostHeader({required this.post, required this.viewModel});

  final Post post;
  final PostDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: scheme.primaryContainer,
          child: Text(
            post.authorUsername.isEmpty
                ? '?'
                : post.authorUsername.substring(0, 1).toUpperCase(),
            style: theme.textTheme.titleMedium?.copyWith(
              color: scheme.onPrimaryContainer,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            post.authorUsername,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        IconButton(
          onPressed: viewModel.isLikePending ? null : viewModel.toggleLike,
          tooltip: 'Лайк',
          icon: Icon(
            post.isLikedByMe ? Icons.favorite : Icons.favorite_border,
            color: post.isLikedByMe ? scheme.error : scheme.onSurfaceVariant,
          ),
        ),
        Text(
          '${post.likesCount}',
          style: theme.textTheme.labelLarge?.copyWith(
            color: post.isLikedByMe ? scheme.error : scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});

  final Comment comment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: theme.colorScheme.secondaryContainer,
            child: Text(
              comment.authorUsername.isEmpty
                  ? '?'
                  : comment.authorUsername.substring(0, 1).toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.authorUsername,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormatter.relative(comment.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(comment.text, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentInput extends StatelessWidget {
  const _CommentInput({
    required this.controller,
    required this.viewModel,
    required this.onSend,
  });

  final TextEditingController controller;
  final PostDetailViewModel viewModel;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: const InputDecoration(
                  hintText: 'Написать комментарий…',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: viewModel.isSending ? null : onSend,
              tooltip: 'Отправить',
              icon: viewModel.isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}

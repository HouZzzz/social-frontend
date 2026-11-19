import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/feed_viewmodel.dart';
import '../viewmodels/profile_viewmodel.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Выйти из аккаунта?'),
        content: const Text('Кэш ленты будет очищен с устройства.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final profileViewModel = context.read<ProfileViewModel>();
    final feedViewModel = context.read<FeedViewModel>();
    final authViewModel = context.read<AuthViewModel>();
    final navigator = Navigator.of(context);

    await profileViewModel.clearCache();
    await feedViewModel.logout();
    await authViewModel.logout();

    navigator.popUntil((route) => route.isFirst);
  }

  Future<void> _clearCache(BuildContext context) async {
    final viewModel = context.read<ProfileViewModel>();
    await viewModel.clearCache();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(viewModel.statusMessage)));
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ProfileViewModel>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                viewModel.username.isEmpty
                    ? '?'
                    : viewModel.username.substring(0, 1).toUpperCase(),
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              viewModel.username,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'Ваш аккаунт',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.article_outlined),
              title: const Text('Мои посты'),
              subtitle: Text(
                viewModel.isLoadingCount
                    ? 'Считаем…'
                    : '${viewModel.myPostsCount}',
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.cleaning_services_outlined),
              title: const Text('Очистить кэш ленты'),
              subtitle: const Text('Локальные копии постов на этом устройстве'),
              onTap: () => _clearCache(context),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
            label: const Text('Выйти'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              foregroundColor: theme.colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }
}

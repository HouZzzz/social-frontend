import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api/api_client.dart';
import 'data/local/app_database.dart';
import 'data/local/feed_cache_dao.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/comment_repository.dart';
import 'data/repositories/feed_cache_repository.dart';
import 'data/repositories/post_repository.dart';
import 'data/session/session_store.dart';
import 'ui/screens/auth_screen.dart';
import 'ui/screens/feed_screen.dart';
import 'ui/viewmodels/auth_viewmodel.dart';
import 'ui/viewmodels/feed_viewmodel.dart';

void main() {
  runApp(const SocialApp());
}

/// Точка сборки зависимостей.
///
/// Репозитории создаются один раз и живут столько же, сколько приложение.
/// ViewModel'и получают их через конструктор — поэтому в тестах достаточно
/// подставить FakePostRepository, не поднимая ни HTTP, ни SQLite.
class SocialApp extends StatefulWidget {
  const SocialApp({super.key});

  @override
  State<SocialApp> createState() => _SocialAppState();
}

class _SocialAppState extends State<SocialApp> {
  late final ApiClient _apiClient;
  late final AuthRepository _authRepository;
  late final PostRepository _postRepository;
  late final CommentRepository _commentRepository;
  late final FeedCacheRepository _feedCacheRepository;

  @override
  void initState() {
    super.initState();

    final sessionStore = SessionStore();
    _apiClient = ApiClient();

    _authRepository = AuthRepository(
      apiClient: _apiClient,
      sessionStore: sessionStore,
    );
    _postRepository = HttpPostRepository(_apiClient);
    _commentRepository = HttpCommentRepository(_apiClient);
    _feedCacheRepository = SqfliteFeedCacheRepository(FeedCacheDao(AppDatabase()));
  }

  @override
  void dispose() {
    _apiClient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Репозитории — обычные Provider'ы: экраны читают их и создают
        // собственные ViewModel'и на время жизни маршрута.
        Provider<AuthRepository>.value(value: _authRepository),
        Provider<PostRepository>.value(value: _postRepository),
        Provider<CommentRepository>.value(value: _commentRepository),
        Provider<FeedCacheRepository>.value(value: _feedCacheRepository),

        ChangeNotifierProvider(
          create: (_) => AuthViewModel(_authRepository)..restoreSession(),
        ),
        ChangeNotifierProvider(
          create: (_) => FeedViewModel(
            postRepository: _postRepository,
            cacheRepository: _feedCacheRepository,
          ),
        ),
      ],
      child: const _AppShell(),
    );
  }
}

/// Тема и роутинг по состоянию авторизации.
class _AppShell extends StatelessWidget {
  const _AppShell();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();

    return MaterialApp(
      title: 'houzz muiv Social',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4F46E5)),
      ),
      home: _homeFor(auth),
    );
  }

  Widget _homeFor(AuthViewModel auth) {
    // Пока идёт восстановление сессии, показываем сплэш:
    // иначе экран входа моргнёт у пользователя, который уже вошёл.
    if (auth.isRestoring) return const _SplashScreen();
    if (auth.isAuthenticated) return const FeedScreen();
    return const AuthScreen();
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

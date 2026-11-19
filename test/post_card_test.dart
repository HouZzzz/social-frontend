import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_frontend/models/post.dart';
import 'package:social_frontend/ui/widgets/post_card.dart';

/// Widget-тест карточки: показывает автора и текст, реагирует на лайк.
Post _post({bool liked = false, int likes = 4}) => Post(
      id: 1,
      content: 'Тестовый пост про Flutter и Provider',
      authorUsername: 'alex_dev',
      createdAt: DateTime(2026, 11, 18, 12),
      likesCount: likes,
      commentsCount: 2,
      isLikedByMe: liked,
    );

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('отображает имя автора и текст поста', (tester) async {
    await tester.pumpWidget(_wrap(PostCard(post: _post())));

    expect(find.text('alex_dev'), findsOneWidget);
    expect(find.text('Тестовый пост про Flutter и Provider'), findsOneWidget);
  });

  testWidgets('показывает количество лайков и комментариев', (tester) async {
    await tester.pumpWidget(_wrap(PostCard(post: _post(likes: 7))));

    expect(find.text('7'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('нажатие на лайк вызывает колбэк', (tester) async {
    var tapped = 0;

    await tester.pumpWidget(
      _wrap(PostCard(post: _post(), onLike: () => tapped++)),
    );

    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pump();

    expect(tapped, 1);
  });

  testWidgets('лайкнутый пост показывает закрашенное сердце', (tester) async {
    await tester.pumpWidget(_wrap(PostCard(post: _post(liked: true))));

    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border), findsNothing);
  });

  testWidgets('пока запрос лайка в полёте, кнопка не реагирует', (tester) async {
    var tapped = 0;

    await tester.pumpWidget(
      _wrap(
        PostCard(
          post: _post(),
          onLike: () => tapped++,
          isLikedPending: true,
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pump();

    expect(tapped, 0);
  });

  testWidgets('нажатие на карточку открывает детали через onTap', (tester) async {
    var opened = 0;

    await tester.pumpWidget(
      _wrap(PostCard(post: _post(), onTap: () => opened++)),
    );

    await tester.tap(find.text('Тестовый пост про Flutter и Provider'));
    await tester.pump();

    expect(opened, 1);
  });

  testWidgets('кнопка удаления есть только когда canDelete', (tester) async {
    await tester.pumpWidget(
      _wrap(PostCard(post: _post(), onDelete: () {})),
    );
    expect(find.byIcon(Icons.delete_outline), findsNothing);

    await tester.pumpWidget(
      _wrap(PostCard(post: _post(), canDelete: true, onDelete: () {})),
    );
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:social_frontend/core/utils/date_formatter.dart';

void main() {
  final now = DateTime.now();

  group('DateFormatter.relative', () {
    test('меньше минуты — «только что»', () {
      final result = DateFormatter.relative(
        now.subtract(const Duration(seconds: 20)),
        now: now,
      );
      expect(result, 'только что');
    });

    test('5 минут назад', () {
      final result = DateFormatter.relative(
        now.subtract(const Duration(minutes: 5)),
        now: now,
      );
      expect(result, '5 мин назад');
    });

    test('2 часа назад', () {
      final result = DateFormatter.relative(
        now.subtract(const Duration(hours: 2)),
        now: now,
      );
      expect(result, '2 ч назад');
    });

    test('вчера - с пометкой и временем', () {
      final yesterday = DateTime(2026, 11, 17, 9, 30);
      final result = DateFormatter.relative(yesterday, now: now);
      expect(result, 'вчера, 09:30');
    });

    test('раньше в этом году - день и месяц', () {
      final result = DateFormatter.relative(DateTime(2026, 3, 12, 10), now: now);
      expect(result, '12.03');
    });

    test('прошлый год - полная дата', () {
      final result = DateFormatter.relative(DateTime(2025, 3, 12, 10), now: now);
      expect(result, '12.03.2025 10:00');
    });

    test('дата из будущего не даёт отрицательных минут', () {
      final result = DateFormatter.relative(
        now.add(const Duration(minutes: 10)),
        now: now,
      );
      expect(result, isNot(contains('-')));
    });
  });
}

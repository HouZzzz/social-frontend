import 'package:intl/intl.dart';

class DateFormatter {
  const DateFormatter._();

  static final DateFormat _time = DateFormat('HH:mm');
  static final DateFormat _dayMonth = DateFormat('dd.MM');
  static final DateFormat _full = DateFormat('dd.MM.yyyy HH:mm');

  /// «только что», «5 мин назад», «3 ч назад», «вчера, 14:05», «12.03», «12.03.2025».
  static String relative(DateTime dateTime, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final local = dateTime.toLocal();
    final diff = current.difference(local);

    if (diff.inMinutes < 1) {
      return 'только что';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} мин назад';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} ч назад';
    }

    final yesterday = DateTime(current.year, current.month, current.day)
        .subtract(const Duration(days: 1));
    final dateOnly = DateTime(local.year, local.month, local.day);
    if (dateOnly == yesterday) {
      return 'вчера, ${_time.format(local)}';
    }
    if (local.year == current.year) {
      return _dayMonth.format(local);
    }
    return _full.format(local);
  }

  static String full(DateTime dateTime) => _full.format(dateTime.toLocal());
}

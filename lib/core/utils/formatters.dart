import '../app_strings.dart';

/// Russian formatting helpers.
///
/// Hand-written instead of `package:intl` because the app needs only a few
/// fixed patterns, and this keeps output identical in tests and on devices.
abstract final class Formatters {
  static const _nbsp = '\u00A0';
  static const _hoursUnit =
      '$_nbsp'
      'ч';
  static const _minutesUnit =
      '$_nbsp'
      'мин';

  /// `5000` -> `5 000 ₸`.
  static String price(int amountKzt) {
    final digits = amountKzt.abs().toString();
    final buffer = StringBuffer(amountKzt < 0 ? '-' : '');
    for (var i = 0; i < digits.length; i++) {
      final remaining = digits.length - i;
      buffer.write(digits[i]);
      if (remaining > 1 && remaining % 3 == 1) buffer.write(_nbsp);
    }
    return '$buffer$_nbsp${AppStrings.currencySymbol}';
  }

  /// `Duration(minutes: 90)` -> `1 ч 30 мин`.
  static String duration(Duration value) {
    final hours = value.inHours;
    final minutes = value.inMinutes % 60;
    if (hours == 0) return '$minutes$_minutesUnit';
    if (minutes == 0) return '$hours$_hoursUnit';
    return '$hours$_hoursUnit $minutes$_minutesUnit';
  }

  /// `14:05`.
  static String time(DateTime value) =>
      '${_twoDigits(value.hour)}:${_twoDigits(value.minute)}';

  /// `пн, 6 октября`.
  static String dayWithWeekday(DateTime value) =>
      '${AppStrings.weekdaysShort[value.weekday - 1]}, '
      '${value.day}$_nbsp${AppStrings.monthsGenitive[value.month - 1]}';

  /// `пн, 6 октября, 14:05`.
  static String dateTime(DateTime value) =>
      '${dayWithWeekday(value)}, ${time(value)}';

  /// `14:05:09`, used by diagnostic journals.
  static String timeWithSeconds(DateTime value) =>
      '${time(value)}:${_twoDigits(value.second)}';

  /// `14:00–14:45`.
  static String timeRange(DateTime start, DateTime end) =>
      '${time(start)}–${time(end)}';

  /// `Арман С.` -> `АС`.
  static String initials(String name) => name
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');
}

import '../app_strings.dart';

abstract final class Formatters {
  static const _nbsp = '\u00A0';
  static const _hoursUnit =
      '$_nbsp'
      'ч';
  static const _minutesUnit =
      '$_nbsp'
      'мин';

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

  static String duration(Duration value) {
    final hours = value.inHours;
    final minutes = value.inMinutes % 60;
    if (hours == 0) return '$minutes$_minutesUnit';
    if (minutes == 0) return '$hours$_hoursUnit';
    return '$hours$_hoursUnit $minutes$_minutesUnit';
  }

  static String time(DateTime value) =>
      '${_twoDigits(value.hour)}:${_twoDigits(value.minute)}';

  static String dayWithWeekday(DateTime value) =>
      '${AppStrings.weekdaysShort[value.weekday - 1]}, '
      '${value.day}$_nbsp${AppStrings.monthsGenitive[value.month - 1]}';

  static String dateTime(DateTime value) =>
      '${dayWithWeekday(value)}, ${time(value)}';

  static String timeWithSeconds(DateTime value) =>
      '${time(value)}:${_twoDigits(value.second)}';

  static String timeRange(DateTime start, DateTime end) =>
      '${time(start)}–${time(end)}';

  static String initials(String name) => name
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');
}

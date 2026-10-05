/// Source of the current time.
///
/// Screens and repositories receive a [Clock] instead of calling
/// [DateTime.now] directly, so tests can freeze time and stay deterministic.
typedef Clock = DateTime Function();

DateTime systemClock() => DateTime.now();

extension DateOnly on DateTime {
  DateTime get dateOnly => DateTime(year, month, day);

  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;
}

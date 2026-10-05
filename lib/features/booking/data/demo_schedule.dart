import '../../catalog/domain/service.dart';

/// Working hours of the demo businesses.
///
/// Without a backend there are no other customers, so [isTakenByOthers]
/// marks about every fourth slot as busy with a fixed formula. The result is
/// deterministic: the same specialist, day and hour are always busy, which
/// keeps tests and demonstrations repeatable.
class DemoSchedule {
  const DemoSchedule({
    this.openingHour = 10,
    this.closingHour = 19,
    this.minimumLeadTime = const Duration(minutes: 30),
  });

  final int openingHour;
  final int closingHour;

  /// A slot that starts sooner than this from now cannot be booked.
  final Duration minimumLeadTime;

  /// Hourly start times on [day] for a visit of [duration] that ends by
  /// closing time.
  List<DateTime> startTimes(DateTime day, Duration duration) {
    final closing = DateTime(day.year, day.month, day.day, closingHour);
    final result = <DateTime>[];
    for (var hour = openingHour; hour < closingHour; hour++) {
      final start = DateTime(day.year, day.month, day.day, hour);
      if (!start.add(duration).isAfter(closing)) result.add(start);
    }
    return result;
  }

  bool isTakenByOthers(Specialist specialist, DateTime startAt) {
    final seed = specialist.id.codeUnits.fold(0, (sum, unit) => sum + unit);
    return (seed + startAt.day + startAt.hour) % 4 == 0;
  }
}

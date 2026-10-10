import '../../catalog/domain/service.dart';

/// Working hours of the demo businesses: hourly start times between
/// [openingHour] and [closingHour] on the specialist's working days.
///
/// A time is busy when an active booking of the same specialist overlaps
/// it; there are no artificial "taken by others" slots any more because the
/// demo data contains bookings of other customers.
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
  /// closing time. Empty on the specialist's days off.
  List<DateTime> startTimes(
    DateTime day,
    Duration duration, {
    Specialist? specialist,
  }) {
    if (specialist != null && !specialist.worksOn(day)) return const [];
    final closing = DateTime(day.year, day.month, day.day, closingHour);
    final result = <DateTime>[];
    for (var hour = openingHour; hour < closingHour; hour++) {
      final start = DateTime(day.year, day.month, day.day, hour);
      if (!start.add(duration).isAfter(closing)) result.add(start);
    }
    return result;
  }
}

import '../../catalog/domain/service.dart';

class DemoSchedule {
  const DemoSchedule({
    this.openingHour = 10,
    this.closingHour = 19,
    this.minimumLeadTime = const Duration(minutes: 30),
  });

  final int openingHour;
  final int closingHour;

  final Duration minimumLeadTime;

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

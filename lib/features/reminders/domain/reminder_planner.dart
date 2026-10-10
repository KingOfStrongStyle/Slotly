import '../../booking/domain/booking.dart';

enum ReminderKind { dayBefore, morning, hourBefore }

class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.bookingId,
    required this.kind,
    required this.fireAt,
    required this.title,
    required this.body,
  });

  final int id;
  final String bookingId;
  final ReminderKind kind;

  final DateTime fireAt;
  final String title;
  final String body;

  @override
  String toString() => 'PlannedReminder($bookingId, ${kind.name}, $fireAt)';
}

typedef ReminderTexts = ({
  String Function(Booking booking) dayBefore,
  String Function(Booking booking) morning,
  String Function(Booking booking) hourBefore,
  String Function(Booking booking) title,
});

class ReminderPlanner {
  const ReminderPlanner({
    required this.texts,
    this.eveningHour = 18,
    this.morningHour = 8,
  });

  final ReminderTexts texts;
  final int eveningHour;
  final int morningHour;

  // Кирилл: три напоминания: вечером накануне, утром и за час. Утреннее не ставим,
  // если оно позже чем "за час", прошедшие отбрасываем
  List<PlannedReminder> plan(Booking booking, DateTime now) {
    if (!booking.isActive || booking.isCheckedIn) return const [];
    final start = booking.startAt;
    final day = DateTime(start.year, start.month, start.day);
    final hourBefore = start.subtract(const Duration(hours: 1));
    final morning = day.add(Duration(hours: morningHour));
    final candidates = [
      (
        ReminderKind.dayBefore,
        day.subtract(const Duration(days: 1)).add(Duration(hours: eveningHour)),
        texts.dayBefore,
      ),
      if (morning.isBefore(hourBefore))
        (ReminderKind.morning, morning, texts.morning),
      (ReminderKind.hourBefore, hourBefore, texts.hourBefore),
    ];
    return [
      for (final (kind, fireAt, text) in candidates)
        if (fireAt.isAfter(now))
          PlannedReminder(
            id: reminderId(booking.id, kind),
            bookingId: booking.id,
            kind: kind,
            fireAt: fireAt,
            title: texts.title(booking),
            body: text(booking),
          ),
    ];
  }

  List<PlannedReminder> planAll(Iterable<Booking> bookings, DateTime now) =>
      [for (final booking in bookings) ...plan(booking, now)]
        ..sort((a, b) => a.fireAt.compareTo(b.fireAt));

  // Кирилл: id должен быть стабильным между запусками, поэтому FNV-1a от id записи,
  // а не hashCode (он в Dart не гарантирован)
  static int reminderId(String bookingId, ReminderKind kind) {
    var hash = 0x811c9dc5;
    for (final unit in bookingId.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return (hash & 0x0FFFFFFF) * 4 + kind.index;
  }
}

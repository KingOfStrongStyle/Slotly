import '../../booking/domain/booking.dart';

enum ReminderKind { dayBefore, morning, hourBefore }

/// One local reminder to schedule on the device.
class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.bookingId,
    required this.kind,
    required this.fireAt,
    required this.title,
    required this.body,
  });

  /// Deterministic: the same booking and kind always give the same id, so
  /// scheduling again replaces the reminder instead of duplicating it.
  final int id;
  final String bookingId;
  final ReminderKind kind;

  /// Local time.
  final DateTime fireAt;
  final String title;
  final String body;

  @override
  String toString() => 'PlannedReminder($bookingId, ${kind.name}, $fireAt)';
}

/// Texts are passed in, so the planner stays independent of `AppStrings`
/// and can be tested with plain values.
typedef ReminderTexts = ({
  String Function(Booking booking) dayBefore,
  String Function(Booking booking) morning,
  String Function(Booking booking) hourBefore,
  String Function(Booking booking) title,
});

/// Decides when to remind about a booking.
///
/// * the day before at [eveningHour]:00;
/// * on the day at [morningHour]:00 — only if that is earlier than the
///   one-hour reminder (for a 09:00 visit it would duplicate it);
/// * one hour before the start.
///
/// Moments that are already in the past are skipped; cancelled, completed
/// and checked-in bookings get no reminders.
class ReminderPlanner {
  const ReminderPlanner({
    required this.texts,
    this.eveningHour = 18,
    this.morningHour = 8,
  });

  final ReminderTexts texts;
  final int eveningHour;
  final int morningHour;

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

  /// Plans all [bookings], earliest first.
  List<PlannedReminder> planAll(Iterable<Booking> bookings, DateTime now) =>
      [for (final booking in bookings) ...plan(booking, now)]
        ..sort((a, b) => a.fireAt.compareTo(b.fireAt));

  /// Stable 31-bit id: FNV-1a hash of the booking id, times 4, plus the
  /// kind. Android notification ids are 32-bit signed integers.
  static int reminderId(String bookingId, ReminderKind kind) {
    var hash = 0x811c9dc5;
    for (final unit in bookingId.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return (hash & 0x0FFFFFFF) * 4 + kind.index;
  }
}

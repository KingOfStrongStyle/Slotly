import 'package:flutter_test/flutter_test.dart';
import 'package:slotly/features/booking/domain/booking.dart';
import 'package:slotly/features/reminders/domain/reminder_planner.dart';

import '../../helpers/booking_fixtures.dart';

void main() {
  final planner = ReminderPlanner(
    texts: (
      title: (b) => 'T ${b.id}',
      dayBefore: (b) => 'day before',
      morning: (b) => 'morning',
      hourBefore: (b) => 'hour before',
    ),
  );
  final now = DateTime(2026, 10, 5, 9);

  List<(ReminderKind, DateTime)> plan(Booking booking, [DateTime? at]) => [
    for (final r in planner.plan(booking, at ?? now)) (r.kind, r.fireAt),
  ];

  test('three reminders for an afternoon visit', () {
    final booking = fixtureBooking(id: 'b', startAt: DateTime(2026, 10, 7, 15));
    expect(plan(booking), [
      (ReminderKind.dayBefore, DateTime(2026, 10, 6, 18)),
      (ReminderKind.morning, DateTime(2026, 10, 7, 8)),
      (ReminderKind.hourBefore, DateTime(2026, 10, 7, 14)),
    ]);
  });

  test('no morning reminder when it would coincide with the hour before', () {
    final booking = fixtureBooking(id: 'b', startAt: DateTime(2026, 10, 7, 9));
    expect(plan(booking).map((r) => r.$1), [
      ReminderKind.dayBefore,
      ReminderKind.hourBefore,
    ]);
  });

  test('moments in the past are skipped', () {
    final tomorrow = fixtureBooking(
      id: 'b',
      startAt: DateTime(2026, 10, 6, 12),
    );
    expect(plan(tomorrow, DateTime(2026, 10, 6, 9)).map((r) => r.$1), [
      ReminderKind.hourBefore,
    ]);
    expect(plan(tomorrow, DateTime(2026, 10, 6, 11, 30)), isEmpty);
  });

  test('cancelled, completed and checked-in bookings get nothing', () {
    final start = DateTime(2026, 10, 7, 15);
    expect(
      plan(
        fixtureBooking(
          id: 'c',
          startAt: start,
          status: BookingStatus.cancelled,
        ),
      ),
      isEmpty,
    );
    expect(
      plan(
        fixtureBooking(
          id: 'd',
          startAt: start,
          status: BookingStatus.completed,
        ),
      ),
      isEmpty,
    );
    expect(
      plan(fixtureBooking(id: 'e', startAt: start, checkedInAt: now)),
      isEmpty,
    );
  });

  test('ids are deterministic, distinct and fit Android int', () {
    final ids = {
      for (final id in ['booking-1', 'booking-2', 'booking-143'])
        for (final kind in ReminderKind.values)
          ReminderPlanner.reminderId(id, kind),
    };
    expect(ids, hasLength(9));
    expect(ids.every((id) => id >= 0 && id < 0x7FFFFFFF), isTrue);
    expect(
      ReminderPlanner.reminderId('booking-1', ReminderKind.morning),
      ReminderPlanner.reminderId('booking-1', ReminderKind.morning),
    );
  });

  test('planAll sorts by time and carries texts and payload', () {
    final reminders = planner.planAll([
      fixtureBooking(id: 'late', startAt: DateTime(2026, 10, 9, 12)),
      fixtureBooking(id: 'soon', startAt: DateTime(2026, 10, 6, 12)),
    ], now);
    expect(reminders.first.bookingId, 'soon');
    expect(reminders.first.title, 'T soon');
    expect(
      reminders.map((r) => r.fireAt).toList(),
      orderedEquals([...reminders.map((r) => r.fireAt)]..sort()),
    );
  });
}

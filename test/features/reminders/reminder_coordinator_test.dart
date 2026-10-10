import 'package:flutter_test/flutter_test.dart';
import 'package:slotly/app/app_scope.dart';
import 'package:slotly/data/seed/demo_accounts.dart';
import 'package:slotly/features/booking/domain/booking.dart';
import 'package:slotly/features/booking/domain/booking_repository.dart';
import 'package:slotly/features/reminders/data/reminder_service.dart';
import 'package:slotly/features/reminders/domain/reminder_planner.dart';

import '../../helpers/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late InMemoryReminderService service;
  late AppDependencies deps;

  setUp(() async {
    service = InMemoryReminderService();
    deps = await createTestDependencies(reminders: service);
  });

  tearDown(() => deps.dispose());

  Future<void> settle() => deps.reminders.sync();

  Iterable<PlannedReminder> forBooking(String id) =>
      service.scheduled.values.where((r) => r.bookingId == id);

  Booking upcomingOf(String clientId) => deps.database.tables.bookings.values
      .where(
        (b) =>
            b.clientId == clientId && b.isActive && b.startAt.isAfter(testNow),
      )
      .reduce((a, b) => a.startAt.isBefore(b.startAt) ? a : b);

  test('nothing is scheduled without a signed-in customer', () async {
    await settle();
    expect(service.scheduled, isEmpty);
  });

  test('sign-in schedules reminders of upcoming bookings only', () async {
    await signIn(deps, 'damir');
    await settle();

    final booking = upcomingOf(clientDamirId);
    expect(forBooking(booking.id), isNotEmpty);
    expect(
      service.scheduled.values.every((r) => r.fireAt.isAfter(testNow)),
      isTrue,
    );
    final ownIds = deps.database.tables.bookings.values
        .where((b) => b.clientId == clientDamirId)
        .map((b) => b.id)
        .toSet();
    expect(
      service.scheduled.values.every((r) => ownIds.contains(r.bookingId)),
      isTrue,
    );
    expect(deps.reminders.planned, hasLength(service.scheduled.length));
  });

  test('a new booking adds reminders, cancellation removes them', () async {
    await signIn(deps, 'aliya');
    final haircut = deps.database.tables.services['svc-beard']!;
    final booking = await deps.bookings.createBooking(
      BookingRequest(
        service: haircut,
        specialist: haircut.availableSpecialists.first,
        startAt: (await deps.bookings.fetchTimeSlots(
          service: haircut,
          specialist: haircut.availableSpecialists.first,
          day: DateTime(2026, 10, 8),
        )).firstWhere((s) => s.isAvailable).startAt,
      ),
    );
    await settle();
    expect(forBooking(booking.id), hasLength(3));

    await deps.bookings.cancelBooking(booking.id);
    await settle();
    expect(forBooking(booking.id), isEmpty);
  });

  test('rescheduling replaces the old times', () async {
    await signIn(deps, 'damir');
    final booking = upcomingOf(clientDamirId);
    await settle();
    final before = forBooking(booking.id).map((r) => r.fireAt).toSet();

    final service2 = deps.database.tables.services[booking.serviceId]!;
    final free = (await deps.bookings.fetchTimeSlots(
      service: service2,
      specialist: booking.specialist,
      day: DateTime(2026, 10, 9),
      ignoreBookingId: booking.id,
    )).firstWhere((s) => s.isAvailable);
    await deps.bookings.rescheduleBooking(
      booking.id,
      startAt: free.startAt,
      specialist: booking.specialist,
    );
    await settle();

    final after = forBooking(booking.id).toList();
    expect(after, isNotEmpty);
    expect(after.map((r) => r.fireAt).toSet().intersection(before), isEmpty);
    expect(
      after.firstWhere((r) => r.kind == ReminderKind.hourBefore).fireAt,
      free.startAt.subtract(const Duration(hours: 1)),
    );
    expect(after.map((r) => r.id).toSet().length, after.length);
  });

  test('sign-out and the setting switch clear the reminders', () async {
    await signIn(deps, 'damir');
    await settle();
    expect(service.scheduled, isNotEmpty);

    await deps.reminders.setEnabled(false);
    expect(service.scheduled, isEmpty);
    await deps.reminders.setEnabled(true);
    expect(service.scheduled, isNotEmpty);

    await deps.session.signOut();
    await settle();
    expect(service.scheduled, isEmpty);
  });

  test('owners get no customer reminders', () async {
    await signIn(deps, 'north');
    await settle();
    expect(service.scheduled, isEmpty);
  });

  test('permission request result is exposed', () async {
    final denied = InMemoryReminderService(
      currentPermission: ReminderPermission.unknown,
      grantOnRequest: false,
    );
    final other = await createTestDependencies(reminders: denied);
    addTearDown(other.dispose);
    expect(other.reminders.permission, ReminderPermission.unknown);
    expect(
      await other.reminders.requestPermission(),
      ReminderPermission.denied,
    );
    expect(denied.requestCount, 1);
  });
}

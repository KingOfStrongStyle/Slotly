import 'package:flutter_test/flutter_test.dart';
import 'package:slotly/data/seed/demo_accounts.dart';
import 'package:slotly/data/seed/demo_catalog.dart';
import 'package:slotly/features/booking/data/demo_schedule.dart';
import 'package:slotly/features/booking/data/local_booking_repository.dart';
import 'package:slotly/features/booking/domain/booking.dart';
import 'package:slotly/features/booking/domain/booking_repository.dart';
import 'package:slotly/features/catalog/domain/service.dart';

import '../../helpers/test_app.dart';

final _tomorrow = DateTime(2026, 10, 6);
const _schedule = DemoSchedule();

void main() {
  late TestData data;
  late LocalBookingRepository repository;
  late Service haircut;
  late Specialist barber;

  setUp(() async {
    data = await TestData.create();
    data.signInAs('aliya');
    repository = LocalBookingRepository(data.context);
    haircut = data.database.tables.services['svc-men-haircut']!;
    barber = haircut.availableSpecialists.first;
  });

  BookingRequest request(DateTime startAt, {Specialist? specialist}) =>
      BookingRequest(
        service: haircut,
        specialist: specialist ?? barber,
        startAt: startAt,
        priceOption: haircut.priceOptions.first,
      );

  test('starts empty without demo activity', () async {
    expect(await repository.fetchBookings(), isEmpty);
  });

  test('schedule lists hourly slots that end before closing', () {
    final coloring = demoServices.firstWhere((s) => s.id == 'svc-coloring');
    final starts = _schedule.startTimes(_tomorrow, coloring.duration);
    expect(starts.first, DateTime(2026, 10, 6, 10));
    expect(starts.last, DateTime(2026, 10, 6, 17), reason: '17:00 + 2 h');
  });

  test('no slots on a day off of the specialist', () async {
    final sunday = DateTime(2026, 10, 11);
    final slots = await repository.fetchTimeSlots(
      service: haircut,
      specialist: barber,
      day: sunday,
    );
    expect(slots, isEmpty);
  });

  test('slots earlier than now plus lead time are unavailable', () async {
    data.clock = DateTime(2026, 10, 5, 15, 40);
    final slots = await repository.fetchTimeSlots(
      service: haircut,
      specialist: barber,
      day: DateTime(2026, 10, 5),
    );
    for (final slot in slots) {
      expect(
        slot.isAvailable,
        slot.startAt.hour > 16,
        reason: '${slot.startAt}',
      );
    }
  });

  test(
    'creates a confirmed booking with client, place, price and ticket',
    () async {
      final start = DateTime(2026, 10, 6, 12);
      final booking = await repository.createBooking(request(start));

      expect(booking.status, BookingStatus.confirmed);
      expect(booking.clientId, clientAliyaId);
      expect(booking.clientName, 'Алия Н.');
      expect(booking.organizationId, orgNorth);
      expect(booking.organizationName, 'Барбершоп «Северный»');
      expect(booking.priceKzt, haircut.priceOptions.first.priceKzt);
      expect(booking.priceLabel, haircut.priceOptions.first.label);
      expect(booking.ticketNumber, '101');
      expect(booking.createdAt, testNow);
      expect(await repository.fetchBookings(), hasLength(1));

      final slots = await repository.fetchTimeSlots(
        service: haircut,
        specialist: barber,
        day: _tomorrow,
      );
      expect(slots.firstWhere((s) => s.startAt == start).isAvailable, isFalse);
    },
  );

  test('a price option is required when the service has a price list', () {
    expect(
      () => repository.createBooking(
        BookingRequest(
          service: haircut,
          specialist: barber,
          startAt: DateTime(2026, 10, 6, 12),
        ),
      ),
      throwsArgumentError,
    );
  });

  test('rejects past and double-booked times', () async {
    expect(
      () => repository.createBooking(request(DateTime(2026, 10, 4, 12))),
      throwsA(isA<SlotUnavailableException>()),
    );
    final start = DateTime(2026, 10, 6, 12);
    await repository.createBooking(request(start));
    data.signInAs('damir');
    expect(
      () => repository.createBooking(request(start)),
      throwsA(isA<SlotUnavailableException>()),
    );
  });

  test('hidden services cannot be booked', () async {
    await data.database.update(
      (t) => t.services[haircut.id] = haircut.copyWith(isHidden: true),
    );
    expect(
      () => repository.createBooking(request(DateTime(2026, 10, 6, 12))),
      throwsA(anything),
    );
  });

  test('a long visit blocks the next hour of the same specialist', () async {
    final coloring = data.database.tables.services['svc-coloring']!;
    final colorist = coloring.availableSpecialists.single;
    final start = DateTime(2026, 10, 6, 12);
    await repository.createBooking(
      BookingRequest(
        service: coloring,
        specialist: colorist,
        startAt: start,
        priceOption: coloring.priceOptions.first,
      ),
    );
    final slots = await repository.fetchTimeSlots(
      service: coloring,
      specialist: colorist,
      day: _tomorrow,
    );
    expect(slots.firstWhere((s) => s.startAt.hour == 13).isAvailable, isFalse);
  });

  test('cancel keeps the record and frees the slot', () async {
    final start = DateTime(2026, 10, 6, 12);
    final booking = await repository.createBooking(request(start));

    final cancelled = await repository.cancelBooking(booking.id);

    expect(cancelled.status, BookingStatus.cancelled);
    expect((await repository.fetchBookings()).single.isCancelled, isTrue);
    final slots = await repository.fetchTimeSlots(
      service: haircut,
      specialist: barber,
      day: _tomorrow,
    );
    expect(slots.firstWhere((s) => s.startAt == start).isAvailable, isTrue);
  });

  test('cancel of an unknown booking throws', () {
    expect(
      () => repository.cancelBooking('missing'),
      throwsA(isA<BookingNotFoundException>()),
    );
  });

  test('reschedule keeps id and ticket and frees the old time', () async {
    final booking = await repository.createBooking(
      request(DateTime(2026, 10, 6, 12)),
    );
    final other = haircut.availableSpecialists.last;

    final moved = await repository.rescheduleBooking(
      booking.id,
      startAt: DateTime(2026, 10, 7, 15),
      specialist: other,
    );

    expect(moved.id, booking.id);
    expect(moved.ticketNumber, booking.ticketNumber);
    expect(moved.startAt, DateTime(2026, 10, 7, 15));
    expect(moved.specialist, other);
    final slots = await repository.fetchTimeSlots(
      service: haircut,
      specialist: barber,
      day: _tomorrow,
    );
    expect(slots.firstWhere((s) => s.startAt.hour == 12).isAvailable, isTrue);
  });

  test('the own time is free when rescheduling to a nearby slot', () async {
    final booking = await repository.createBooking(
      request(DateTime(2026, 10, 6, 12)),
    );
    final slots = await repository.fetchTimeSlots(
      service: haircut,
      specialist: barber,
      day: _tomorrow,
      ignoreBookingId: booking.id,
    );
    expect(slots.firstWhere((s) => s.startAt.hour == 12).isAvailable, isTrue);
  });

  test('a started or checked-in visit cannot be changed', () async {
    final booking = await repository.createBooking(
      request(DateTime(2026, 10, 5, 12)),
    );
    data.clock = DateTime(2026, 10, 5, 11, 30);
    await repository.checkIn(booking.ticketNumber);

    expect(
      () => repository.cancelBooking(booking.id),
      throwsA(isA<BookingLockedException>()),
    );
    expect(
      () => repository.rescheduleBooking(
        booking.id,
        startAt: DateTime(2026, 10, 6, 15),
        specialist: barber,
      ),
      throwsA(isA<BookingLockedException>()),
    );
  });

  group('checkIn', () {
    late Booking booking;

    setUp(() async {
      booking = await repository.createBooking(
        request(DateTime(2026, 10, 6, 12)),
      );
    });

    test('marks the booking as arrived inside the window', () async {
      data.clock = booking.startAt.subtract(const Duration(minutes: 10));
      final checkedIn = await repository.checkIn(booking.ticketNumber);
      expect(checkedIn.checkedInAt, data.clock);
      expect((await repository.fetchBookings()).single.isCheckedIn, isTrue);
    });

    test('rejects early and repeated check-ins', () async {
      await expectLater(
        repository.checkIn(booking.ticketNumber),
        throwsA(
          isA<CheckInUnavailableException>().having(
            (e) => e.reason,
            'reason',
            CheckInAvailability.tooEarly,
          ),
        ),
      );
      data.clock = booking.startAt;
      await repository.checkIn(booking.ticketNumber);
      await expectLater(
        repository.checkIn(booking.ticketNumber),
        throwsA(
          isA<CheckInUnavailableException>().having(
            (e) => e.reason,
            'reason',
            CheckInAvailability.alreadyCheckedIn,
          ),
        ),
      );
    });

    test('the owner checks in visitors of the organization', () async {
      data
        ..clock = booking.startAt
        ..signInAs('north');
      final checkedIn = await repository.checkIn(booking.ticketNumber);
      expect(checkedIn.isCheckedIn, isTrue);
    });

    test('throws for an unknown ticket', () {
      expect(
        () => repository.checkIn('999'),
        throwsA(isA<TicketNotFoundException>()),
      );
    });
  });

  group('completeBooking', () {
    test('the owner completes a visit that has started', () async {
      final booking = await repository.createBooking(
        request(DateTime(2026, 10, 6, 12)),
      );
      data.signInAs('north');
      expect(
        () => repository.completeBooking(booking.id),
        throwsA(isA<BookingLockedException>()),
        reason: 'the visit has not started yet',
      );

      data.clock = DateTime(2026, 10, 6, 12, 50);
      final completed = await repository.completeBooking(booking.id);
      expect(completed.status, BookingStatus.completed);
    });
  });

  test('tickets are numbered sequentially', () async {
    final first = await repository.createBooking(
      request(DateTime(2026, 10, 6, 12)),
    );
    final second = await repository.createBooking(
      request(DateTime(2026, 10, 6, 14)),
    );
    expect(first.ticketNumber, '101');
    expect(second.ticketNumber, '102');
    expect(first.id, isNot(second.id));
  });

  test('changes notify listeners', () async {
    var notified = 0;
    repository.changes.addListener(() => notified++);
    await repository.createBooking(request(DateTime(2026, 10, 6, 12)));
    expect(notified, 1);
  });
}

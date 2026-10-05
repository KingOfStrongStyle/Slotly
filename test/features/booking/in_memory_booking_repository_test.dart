import 'package:flutter_test/flutter_test.dart';
import 'package:slotly/features/booking/data/demo_schedule.dart';
import 'package:slotly/features/booking/data/in_memory_booking_repository.dart';
import 'package:slotly/features/booking/domain/booking.dart';
import 'package:slotly/features/booking/domain/booking_repository.dart';
import 'package:slotly/features/catalog/data/demo_services.dart';
import 'package:slotly/features/catalog/domain/service.dart';

final _now = DateTime(2026, 10, 5, 9);
final _tomorrow = DateTime(2026, 10, 6);
const _schedule = DemoSchedule();

Service _service(String id) => demoServices.firstWhere((s) => s.id == id);

/// First start time on [day] that is not blocked by the demo pattern.
DateTime _freeStart(Specialist specialist, DateTime day, Duration duration) =>
    _schedule
        .startTimes(day, duration)
        .firstWhere((t) => !_schedule.isTakenByOthers(specialist, t));

void main() {
  late InMemoryBookingRepository repository;
  final haircut = _service('svc-men-haircut');
  final barber = haircut.availableSpecialists.first;

  setUp(() => repository = InMemoryBookingRepository(clock: () => _now));

  test('starts empty', () async {
    expect(await repository.fetchBookings(), isEmpty);
  });

  test('schedule lists hourly slots that end before closing', () {
    final coloring = _service('svc-coloring');
    final starts = _schedule.startTimes(_tomorrow, coloring.duration);

    expect(starts.first, DateTime(2026, 10, 6, 10));
    expect(
      starts.last,
      DateTime(2026, 10, 6, 17),
      reason: '17:00 + 2 h = 19:00',
    );
  });

  test('demo pattern marks some slots as taken by other customers', () async {
    final slots = await repository.fetchTimeSlots(
      service: haircut,
      specialist: barber,
      day: _tomorrow,
    );

    expect(slots, isNotEmpty);
    for (final slot in slots) {
      expect(
        slot.isAvailable,
        !_schedule.isTakenByOthers(barber, slot.startAt),
      );
    }
    expect(slots.where((s) => !s.isAvailable), isNotEmpty);
  });

  test('slots earlier than now plus lead time are unavailable', () async {
    final lateRepository = InMemoryBookingRepository(
      clock: () => DateTime(2026, 10, 5, 15, 40),
    );
    final slots = await lateRepository.fetchTimeSlots(
      service: haircut,
      specialist: barber,
      day: DateTime(2026, 10, 5),
    );

    for (final slot in slots.where((s) => s.startAt.hour <= 16)) {
      expect(slot.isAvailable, isFalse, reason: '${slot.startAt}');
    }
  });

  test('creates a confirmed booking and blocks the slot', () async {
    final start = _freeStart(barber, _tomorrow, haircut.duration);

    final booking = await repository.createBooking(
      BookingRequest(
        service: haircut,
        specialist: barber,
        startAt: start,
        comment: 'Первый визит',
      ),
    );

    expect(booking.status, BookingStatus.confirmed);
    expect(booking.serviceTitle, haircut.title);
    expect(booking.duration, haircut.duration);
    expect(booking.createdAt, _now);
    expect(await repository.fetchBookings(), [booking]);

    final slots = await repository.fetchTimeSlots(
      service: haircut,
      specialist: barber,
      day: _tomorrow,
    );
    expect(slots.firstWhere((s) => s.startAt == start).isAvailable, isFalse);
  });

  test('rejects busy, past and overlapping times', () async {
    final busy = _schedule
        .startTimes(_tomorrow, haircut.duration)
        .firstWhere((t) => _schedule.isTakenByOthers(barber, t));
    expect(
      () => repository.createBooking(
        BookingRequest(service: haircut, specialist: barber, startAt: busy),
      ),
      throwsA(isA<SlotUnavailableException>()),
    );

    expect(
      () => repository.createBooking(
        BookingRequest(
          service: haircut,
          specialist: barber,
          startAt: DateTime(2026, 10, 4, 12),
        ),
      ),
      throwsA(isA<SlotUnavailableException>()),
    );

    final start = _freeStart(barber, _tomorrow, haircut.duration);
    final request = BookingRequest(
      service: haircut,
      specialist: barber,
      startAt: start,
    );
    await repository.createBooking(request);
    expect(
      () => repository.createBooking(request),
      throwsA(isA<SlotUnavailableException>()),
    );
  });

  test('a long visit blocks the next hour of the same specialist', () async {
    final coloring = _service('svc-coloring');
    final colorist = coloring.availableSpecialists.single;
    final starts = _schedule.startTimes(_tomorrow, coloring.duration);
    final start = starts.firstWhere(
      (t) =>
          !_schedule.isTakenByOthers(colorist, t) &&
          !_schedule.isTakenByOthers(colorist, t.add(const Duration(hours: 1))),
    );

    await repository.createBooking(
      BookingRequest(service: coloring, specialist: colorist, startAt: start),
    );
    final slots = await repository.fetchTimeSlots(
      service: coloring,
      specialist: colorist,
      day: _tomorrow,
    );

    final nextHour = start.add(const Duration(hours: 1));
    expect(slots.firstWhere((s) => s.startAt == nextHour).isAvailable, isFalse);
  });

  test(
    'cancel keeps the record, marks it cancelled and frees the slot',
    () async {
      final start = _freeStart(barber, _tomorrow, haircut.duration);
      final booking = await repository.createBooking(
        BookingRequest(service: haircut, specialist: barber, startAt: start),
      );

      final cancelled = await repository.cancelBooking(booking.id);

      expect(cancelled.status, BookingStatus.cancelled);
      expect(
        (await repository.fetchBookings()).single.status,
        BookingStatus.cancelled,
      );
      final slots = await repository.fetchTimeSlots(
        service: haircut,
        specialist: barber,
        day: _tomorrow,
      );
      expect(slots.firstWhere((s) => s.startAt == start).isAvailable, isTrue);
    },
  );

  test('cancel of an unknown booking throws', () {
    expect(
      () => repository.cancelBooking('missing'),
      throwsA(isA<BookingNotFoundException>()),
    );
  });

  test('generated ids do not clash with initial bookings', () async {
    final existing = Booking(
      id: 'booking-1',
      serviceId: haircut.id,
      serviceTitle: haircut.title,
      specialist: barber,
      startAt: DateTime(2026, 10, 10, 10),
      duration: haircut.duration,
      comment: '',
      status: BookingStatus.confirmed,
      createdAt: _now,
    );
    repository = InMemoryBookingRepository(
      clock: () => _now,
      initialBookings: [existing],
    );

    final created = await repository.createBooking(
      BookingRequest(
        service: haircut,
        specialist: barber,
        startAt: _freeStart(barber, _tomorrow, haircut.duration),
      ),
    );

    expect(created.id, isNot(existing.id));
    expect(await repository.fetchBookings(), hasLength(2));
  });
}

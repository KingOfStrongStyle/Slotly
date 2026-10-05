import 'package:flutter_test/flutter_test.dart';
import 'package:slotly/features/booking/data/demo_schedule.dart';
import 'package:slotly/features/booking/data/in_memory_booking_repository.dart';
import 'package:slotly/features/booking/domain/booking_repository.dart';
import 'package:slotly/features/booking/presentation/bookings_controller.dart';
import 'package:slotly/features/catalog/data/demo_services.dart';

void main() {
  final service = demoServices.first;
  final specialist = service.availableSpecialists.first;
  const schedule = DemoSchedule();
  late BookingsController controller;

  List<DateTime> freeStarts(DateTime day) => schedule
      .startTimes(day, service.duration)
      .where((t) => !schedule.isTakenByOthers(specialist, t))
      .toList();

  setUp(() {
    controller = BookingsController(
      InMemoryBookingRepository(clock: () => DateTime(2026, 10, 5, 9)),
    );
  });

  tearDown(() => controller.dispose());

  test('load finishes with an empty list for a new user', () async {
    final loadingStates = <bool>[];
    controller.addListener(() => loadingStates.add(controller.isLoading));

    await controller.load();

    expect(loadingStates, [true, false]);
    expect(controller.active, isEmpty);
    expect(controller.cancelled, isEmpty);
    expect(controller.hasLoadError, isFalse);
  });

  test('active bookings are sorted by start time', () async {
    final later = freeStarts(DateTime(2026, 10, 8)).first;
    final earlier = freeStarts(DateTime(2026, 10, 6)).last;

    await controller.book(
      BookingRequest(service: service, specialist: specialist, startAt: later),
    );
    await controller.book(
      BookingRequest(
        service: service,
        specialist: specialist,
        startAt: earlier,
      ),
    );

    expect(controller.active.map((b) => b.startAt), [earlier, later]);
  });

  test('cancel moves a booking to the cancelled list', () async {
    final booking = await controller.book(
      BookingRequest(
        service: service,
        specialist: specialist,
        startAt: freeStarts(DateTime(2026, 10, 6)).first,
      ),
    );
    var notifications = 0;
    controller.addListener(() => notifications++);

    await controller.cancel(booking.id);

    expect(controller.active, isEmpty);
    expect(controller.cancelled.single.id, booking.id);
    expect(notifications, 1);
  });
}

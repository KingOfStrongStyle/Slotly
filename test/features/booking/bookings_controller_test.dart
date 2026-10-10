import 'package:flutter_test/flutter_test.dart';
import 'package:slotly/features/booking/data/local_booking_repository.dart';
import 'package:slotly/features/booking/domain/booking.dart';
import 'package:slotly/features/booking/presentation/bookings_controller.dart';

import '../../helpers/booking_fixtures.dart';
import '../../helpers/test_app.dart';

void main() {
  late TestData data;
  late BookingsController controller;

  setUp(() async {
    data = await TestData.create();
    data.signInAs('aliya');
    await data.database.update((t) {
      for (final booking in [
        fixtureBooking(id: 'later', startAt: DateTime(2026, 10, 9, 12)),
        fixtureBooking(id: 'sooner', startAt: DateTime(2026, 10, 6, 12)),
        fixtureBooking(
          id: 'old',
          startAt: DateTime(2026, 9, 1, 12),
          status: BookingStatus.completed,
        ),
        fixtureBooking(
          id: 'older',
          startAt: DateTime(2026, 8, 1, 12),
          status: BookingStatus.completed,
        ),
        fixtureBooking(
          id: 'gone',
          startAt: DateTime(2026, 9, 2, 12),
          status: BookingStatus.cancelled,
        ),
      ]) {
        t.bookings[booking.id] = booking;
      }
    });
    controller = BookingsController(LocalBookingRepository(data.context));
  });

  tearDown(() => controller.dispose());

  test('load reports progress and splits bookings by status', () async {
    final loading = <bool>[];
    controller.addListener(() => loading.add(controller.isLoading));

    await controller.load();

    expect(loading, [true, false]);
    expect(controller.active.map((b) => b.id), ['sooner', 'later']);
    expect(controller.past.map((b) => b.id), ['old', 'older']);
    expect(controller.cancelled.map((b) => b.id), ['gone']);
    expect(controller.byId('old')?.isCompleted, isTrue);
  });

  test('reloads by itself after a change in the repository', () async {
    await controller.load();
    await controller.cancel('sooner');
    await pumpEventQueue();

    expect(controller.active.map((b) => b.id), ['later']);
    expect(
      controller.cancelled.map((b) => b.id),
      containsAll(['sooner', 'gone']),
    );
  });

  test('a load error is reported instead of thrown', () async {
    data.signInAs('north');
    await controller.load();
    expect(controller.hasLoadError, isTrue);
  });
}

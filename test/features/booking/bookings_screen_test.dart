import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slotly/core/app_strings.dart';
import 'package:slotly/core/utils/formatters.dart';
import 'package:slotly/features/booking/data/in_memory_booking_repository.dart';
import 'package:slotly/features/booking/domain/booking.dart';
import 'package:slotly/features/booking/presentation/bookings_controller.dart';
import 'package:slotly/features/booking/presentation/bookings_screen.dart';
import 'package:slotly/features/booking/presentation/widgets/booking_tile.dart';

import '../../helpers/booking_fixtures.dart';
import '../../helpers/test_app.dart';

void main() {
  late BookingsController controller;
  late int browseTaps;
  late int checkInTaps;

  Future<void> pumpBookings(
    WidgetTester tester, {
    List<Booking> initial = const [],
  }) async {
    controller = BookingsController(
      InMemoryBookingRepository(clock: () => testNow, initialBookings: initial),
    );
    addTearDown(controller.dispose);
    await controller.load();
    browseTaps = 0;
    checkInTaps = 0;
    await pumpScreen(
      tester,
      Scaffold(
        body: BookingsScreen(
          bookings: controller,
          clock: () => testNow,
          onBrowseServices: () => browseTaps++,
          onOpenCheckIn: () => checkInTaps++,
        ),
      ),
    );
  }

  Future<void> swipeLeft(WidgetTester tester, String title) async {
    await tester.drag(find.text(title), const Offset(-500, 0));
    await tester.pumpAndSettle();
  }

  testWidgets('empty state offers to browse services', (tester) async {
    await pumpBookings(tester);

    expect(find.text(AppStrings.bookingsEmptyTitle), findsOneWidget);
    await tester.tap(find.text(AppStrings.bookingsBrowseServices));
    expect(browseTaps, 1);
  });

  testWidgets('active bookings are listed by date', (tester) async {
    await pumpBookings(
      tester,
      initial: [
        fixtureBooking(id: 'late', startAt: DateTime(2026, 10, 9, 12)),
        fixtureBooking(
          id: 'early',
          startAt: DateTime(2026, 10, 6, 10),
          serviceId: 'svc-tires',
        ),
      ],
    );

    final tiles = tester.widgetList<BookingTile>(find.byType(BookingTile));
    expect(tiles.map((t) => t.booking.id), ['early', 'late']);
    expect(find.text(AppStrings.bookingsActiveTab(2)), findsOneWidget);
  });

  testWidgets('swipe asks for confirmation and can be declined', (
    tester,
  ) async {
    await pumpBookings(
      tester,
      initial: [fixtureBooking(id: 'b1', startAt: DateTime(2026, 10, 6, 12))],
    );

    await swipeLeft(tester, 'Мужская стрижка');

    expect(find.text(AppStrings.cancelDialogTitle), findsOneWidget);
    await tester.tap(find.text(AppStrings.cancelDialogKeep));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.cancelDialogTitle), findsNothing);
    expect(find.byType(BookingTile), findsOneWidget);
    expect(controller.active.single.id, 'b1');
  });

  testWidgets('confirmed swipe cancels and moves the booking', (tester) async {
    await pumpBookings(
      tester,
      initial: [fixtureBooking(id: 'b1', startAt: DateTime(2026, 10, 6, 12))],
    );

    await swipeLeft(tester, 'Мужская стрижка');
    await tester.tap(
      find.widgetWithText(FilledButton, AppStrings.cancelDialogConfirm),
    );
    await tester.pumpAndSettle();

    expect(controller.active, isEmpty);
    expect(controller.cancelled.single.status, BookingStatus.cancelled);
    expect(find.text(AppStrings.bookingCancelled), findsOneWidget);
    expect(find.text(AppStrings.bookingsEmptyTitle), findsOneWidget);

    await tester.tap(find.text(AppStrings.bookingsCancelledTab(1)));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.bookingStatusCancelled), findsOneWidget);
  });

  testWidgets('tap opens details, long press opens the action menu', (
    tester,
  ) async {
    await pumpBookings(
      tester,
      initial: [fixtureBooking(id: 'b1', startAt: DateTime(2026, 10, 6, 12))],
    );

    await tester.tap(find.text('Мужская стрижка'));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.bookingDetailsTitle), findsOneWidget);
    expect(find.text(AppStrings.bookingStatusConfirmed), findsOneWidget);

    await tester.tapAt(const Offset(200, 100));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.bookingDetailsTitle), findsNothing);

    await tester.longPress(find.text('Мужская стрижка'));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.bookingActionsTitle), findsOneWidget);

    await tester.tap(find.text(AppStrings.bookingActionCancel));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.cancelDialogTitle), findsOneWidget);
    expect(controller.active, hasLength(1), reason: 'not cancelled yet');
  });

  testWidgets('"Я на месте" checks in a booking that starts soon', (
    tester,
  ) async {
    await pumpBookings(
      tester,
      initial: [
        fixtureBooking(
          id: 'soon',
          ticketNumber: '117',
          startAt: testNow.add(const Duration(minutes: 30)),
        ),
      ],
    );
    expect(find.textContaining(AppStrings.bookingTicketShort('117')), findsOne);

    await tester.tap(find.byType(BookingTile));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.bookingCheckInAction));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.checkInSuccess('117')), findsOneWidget);
    expect(controller.active.single.isCheckedIn, isTrue);
    expect(find.text(AppStrings.bookingStatusCheckedIn), findsOneWidget);
  });

  testWidgets('check-in is not offered before the window opens', (
    tester,
  ) async {
    final startAt = DateTime(2026, 10, 6, 12);
    await pumpBookings(
      tester,
      initial: [fixtureBooking(id: 'b1', startAt: startAt)],
    );

    await tester.tap(find.byType(BookingTile));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.bookingCheckInAction), findsNothing);
    expect(
      find.text(
        AppStrings.bookingCheckInOpensAt(
          Formatters.dateTime(DateTime(2026, 10, 6, 11)),
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('app bar action opens handwritten check-in', (tester) async {
    await pumpBookings(tester);

    await tester.tap(find.byTooltip(AppStrings.bookingsOpenCheckIn));
    expect(checkInTaps, 1);
  });
}

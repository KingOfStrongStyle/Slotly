import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slotly/core/app_strings.dart';
import 'package:slotly/core/utils/formatters.dart';
import 'package:slotly/features/booking/data/local_booking_repository.dart';
import 'package:slotly/features/booking/domain/booking.dart';
import 'package:slotly/features/booking/presentation/bookings_controller.dart';
import 'package:slotly/features/booking/presentation/bookings_screen.dart';
import 'package:slotly/features/booking/presentation/widgets/booking_tile.dart';

import '../../helpers/booking_fixtures.dart';
import '../../helpers/test_app.dart';

void main() {
  late BookingsController controller;
  late int browseTaps;
  late List<Booking> rescheduled;
  late List<Booking> reviewed;

  Future<void> pumpBookings(
    WidgetTester tester, {
    List<Booking> initial = const [],
    Set<String> reviewedIds = const {},
  }) async {
    final data = await TestData.create();
    data.signInAs('aliya');
    await data.database.update((t) {
      for (final booking in initial) {
        t.bookings[booking.id] = booking;
      }
    });
    controller = BookingsController(LocalBookingRepository(data.context));
    addTearDown(controller.dispose);
    await controller.load();
    browseTaps = 0;
    rescheduled = [];
    reviewed = [];
    await pumpScreen(
      tester,
      Scaffold(
        body: BookingsScreen(
          bookings: controller,
          clock: () => testNow,
          reviewedBookingIds: reviewedIds,
          onBrowseServices: () => browseTaps++,
          onReschedule: rescheduled.add,
          onWriteReview: reviewed.add,
        ),
      ),
    );
  }

  Future<void> swipe(WidgetTester tester, String title, double dx) async {
    await tester.drag(find.text(title), Offset(dx, 0));
    await tester.pumpAndSettle();
  }

  testWidgets('empty state offers to browse services', (tester) async {
    await pumpBookings(tester);
    expect(find.text(AppStrings.bookingsEmptyTitle), findsOneWidget);
    await tester.tap(find.text(AppStrings.bookingsBrowseServices));
    expect(browseTaps, 1);
  });

  testWidgets('active bookings are listed by date with ticket and place', (
    tester,
  ) async {
    await pumpBookings(
      tester,
      initial: [
        fixtureBooking(id: 'late', startAt: DateTime(2026, 10, 9, 12)),
        fixtureBooking(
          id: 'early',
          ticketNumber: '117',
          startAt: DateTime(2026, 10, 6, 10),
          serviceId: 'svc-tires',
        ),
      ],
    );

    final tiles = tester.widgetList<BookingTile>(find.byType(BookingTile));
    expect(tiles.map((t) => t.booking.id), ['early', 'late']);
    expect(find.text(AppStrings.bookingsActiveTab(2)), findsOneWidget);
    expect(find.text('Автосервис «Гараж 24»'), findsOneWidget);
    expect(find.textContaining(AppStrings.bookingTicketShort('117')), findsOne);
  });

  testWidgets('swipe left asks for confirmation and can be declined', (
    tester,
  ) async {
    await pumpBookings(
      tester,
      initial: [fixtureBooking(id: 'b1', startAt: DateTime(2026, 10, 6, 12))],
    );

    await swipe(tester, 'Мужская стрижка', -500);
    expect(find.text(AppStrings.cancelDialogTitle), findsOneWidget);
    await tester.tap(find.text(AppStrings.cancelDialogKeep));
    await tester.pumpAndSettle();

    expect(find.byType(BookingTile), findsOneWidget);
    expect(controller.active.single.id, 'b1');
  });

  testWidgets('confirmed swipe cancels and moves the booking', (tester) async {
    await pumpBookings(
      tester,
      initial: [fixtureBooking(id: 'b1', startAt: DateTime(2026, 10, 6, 12))],
    );

    await swipe(tester, 'Мужская стрижка', -500);
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

  testWidgets('swipe right starts rescheduling without changing anything', (
    tester,
  ) async {
    await pumpBookings(
      tester,
      initial: [fixtureBooking(id: 'b1', startAt: DateTime(2026, 10, 6, 12))],
    );

    await swipe(tester, 'Мужская стрижка', 500);

    expect(rescheduled.single.id, 'b1');
    expect(controller.active.single.startAt, DateTime(2026, 10, 6, 12));
    expect(find.byType(BookingTile), findsOneWidget, reason: 'slides back');
  });

  testWidgets('every gesture has a button in the details sheet', (
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
    expect(find.text(AppStrings.bookingActionReschedule), findsOneWidget);
    expect(find.text(AppStrings.bookingActionCancel), findsOneWidget);

    await tester.tap(find.text(AppStrings.bookingActionReschedule));
    await tester.pumpAndSettle();
    expect(rescheduled.single.id, 'b1');
  });

  testWidgets('long press opens the action menu', (tester) async {
    await pumpBookings(
      tester,
      initial: [fixtureBooking(id: 'b1', startAt: DateTime(2026, 10, 6, 12))],
    );

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
    await pumpBookings(
      tester,
      initial: [fixtureBooking(id: 'b1', startAt: DateTime(2026, 10, 6, 12))],
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

  testWidgets('past visits offer a review until one is written', (
    tester,
  ) async {
    await pumpBookings(
      tester,
      initial: [
        fixtureBooking(
          id: 'done',
          startAt: DateTime(2026, 9, 30, 12),
          status: BookingStatus.completed,
        ),
        fixtureBooking(
          id: 'reviewed',
          startAt: DateTime(2026, 9, 20, 12),
          status: BookingStatus.completed,
          serviceId: 'svc-beard',
        ),
      ],
      reviewedIds: {'reviewed'},
    );

    await tester.tap(find.text(AppStrings.bookingsPastTab(2)));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.reviewWrite), findsOneWidget);
    expect(find.text(AppStrings.bookingReviewed), findsOneWidget);

    await tester.tap(find.text(AppStrings.reviewWrite));
    expect(reviewed.single.id, 'done');
  });
}

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slotly/core/app_strings.dart';
import 'package:slotly/core/utils/formatters.dart';
import 'package:slotly/core/widgets/time_slot_chip.dart';
import 'package:slotly/features/booking/presentation/widgets/booking_tile.dart';
import 'package:slotly/features/catalog/domain/service.dart';
import 'package:slotly/features/reviews/domain/rating_summary.dart';

import '../helpers/test_app.dart';

void main() {
  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('place -> service -> form -> confirm -> my bookings', (
    tester,
  ) async {
    final deps = await pumpApp(tester, login: 'aliya');
    final Service service = deps.database.tables.services['svc-beard']!;

    await tester.tap(find.text('Барбершоп «Северный»'));
    await tester.pump(kDoubleTapTimeout);
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text(service.title).first);
    await tapVisible(tester, find.text(AppStrings.detailsBook));

    await tapVisible(
      tester,
      find.text(service.availableSpecialists.first.name),
    );
    await tapVisible(tester, find.text(AppStrings.bookingTomorrow));
    final freeSlot = find
        .byWidgetPredicate((w) => w is TimeSlotChip && w.isAvailable)
        .first;
    final slotLabel = tester.widget<TimeSlotChip>(freeSlot).label;
    await tapVisible(tester, freeSlot);
    await tapVisible(tester, find.text(AppStrings.bookingContinue));
    await tester.tap(find.text(AppStrings.confirmSubmit));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      find.textContaining(AppStrings.bookingCreated(service.title, '')),
      findsOneWidget,
    );
    expect(find.textContaining('Талон'), findsWidgets);
    final tile = tester
        .widgetList<BookingTile>(find.byType(BookingTile))
        .firstWhere(
          (t) =>
              t.booking.serviceId == service.id &&
              Formatters.time(t.booking.startAt) == slotLabel,
        );
    expect(tile.booking.clientId, userOf('aliya').id);
  });

  testWidgets('a completed visit is reviewed and the rating changes', (
    tester,
  ) async {
    final deps = await pumpApp(tester, login: 'aliya');
    await openTab(tester, AppStrings.tabBookings);

    final pastTab = find.textContaining('Прошедшие');
    await tester.tap(pastTab);
    await tester.pumpAndSettle();
    final write = find.text(AppStrings.reviewWrite).first;
    final tile = tester.widget<BookingTile>(
      find.ancestor(of: write, matching: find.byType(BookingTile)),
    );
    final organizationId = tile.booking.organizationId;
    final before = RatingSummary.of(
      await deps.reviews.fetchOrganizationReviews(organizationId),
    );

    await tester.tap(write);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.reviewFormTitle), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('star-1')));
    await tester.enterText(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(TextField),
      ),
      'Пришлось ждать',
    );
    await tester.tap(find.text(AppStrings.reviewFormSubmit));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.reviewPublished), findsOneWidget);
    final after = RatingSummary.of(
      await deps.reviews.fetchOrganizationReviews(organizationId),
    );
    expect(after.count, before.count + 1);
    expect(after.average, lessThan(before.average ?? 5));
    final written = (await deps.reviews.fetchMyReviews()).first;
    expect(written.text, 'Пришлось ждать');
    expect(written.rating, 1);
    // The booking now says the review is written.
    expect(
      find.descendant(
        of: find.byWidgetPredicate(
          (w) => w is BookingTile && w.booking.id == tile.booking.id,
        ),
        matching: find.text(AppStrings.bookingReviewed),
      ),
      findsOneWidget,
    );
  });
}

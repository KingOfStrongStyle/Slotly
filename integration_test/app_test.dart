import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:slotly/app/app.dart';
import 'package:slotly/app/app_scope.dart';
import 'package:slotly/core/access/access_policy.dart';
import 'package:slotly/core/app_strings.dart';
import 'package:slotly/core/widgets/time_slot_chip.dart';
import 'package:slotly/data/local/database_storage.dart';
import 'package:slotly/data/seed/demo_accounts.dart';
import 'package:slotly/data/seed/demo_catalog.dart';
import 'package:slotly/features/analytics/domain/owner_analytics.dart';
import 'package:slotly/features/auth/presentation/login_screen.dart';
import 'package:slotly/features/booking/presentation/widgets/booking_tile.dart';
import 'package:slotly/features/business/data/photo_storage.dart';
import 'package:slotly/features/catalog/presentation/widgets/organization_card.dart';
import 'package:slotly/features/reminders/data/reminder_service.dart';
import 'package:slotly/features/reviews/domain/rating_summary.dart';
import 'package:slotly/features/welcome/welcome_screen.dart';

import '../test/helpers/test_app.dart' show FakePhotoPicker;

/// End-to-end scenarios on a real device or emulator with the real clock.
/// Every test starts from a fresh in-memory database with the demo data;
/// reminders go to an in-memory service so they can be inspected.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late MemoryDatabaseStorage storage;
  late InMemoryReminderService reminders;

  Future<AppDependencies> launch(WidgetTester tester) async {
    final deps = await AppDependencies.create(
      storage: storage,
      photoStorage: MemoryPhotoStorage(),
      reminderService: reminders,
      photoPicker: FakePhotoPicker(),
    );
    addTearDown(deps.dispose);
    await tester.pumpWidget(SlotlyApp(dependencies: deps));
    await tester.pumpAndSettle();
    return deps;
  }

  setUp(() {
    storage = MemoryDatabaseStorage();
    reminders = InMemoryReminderService();
  });

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> signIn(WidgetTester tester, String login) async {
    final account = demoAccounts.firstWhere((a) => a.user.login == login);
    await tester.tap(find.text(AppStrings.welcomeShowServices));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('login-field')), login);
    await tester.enterText(
      find.byKey(const ValueKey('password-field')),
      account.password,
    );
    await tester.tap(
      find.widgetWithText(FilledButton, AppStrings.signInSubmit),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openTab(WidgetTester tester, String label) async {
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(label),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openPlace(WidgetTester tester, String name) async {
    await tester.tap(find.text(name));
    await tester.pump(kDoubleTapTimeout);
    await tester.pumpAndSettle();
  }

  testWidgets('1. customer signs in, books and manages the booking', (
    tester,
  ) async {
    final deps = await launch(tester);
    await signIn(tester, 'aliya');

    await openPlace(tester, 'Барбершоп «Северный»');
    await tapVisible(tester, find.text('Оформление бороды').first);
    await tapVisible(tester, find.text(AppStrings.detailsBook));
    await tapVisible(tester, find.text('Арман С.'));
    await tapVisible(tester, find.text(AppStrings.bookingTomorrow));
    var free = find.byWidgetPredicate(
      (w) => w is TimeSlotChip && w.isAvailable,
    );
    if (free.evaluate().isEmpty) {
      // Tomorrow may be Sunday (day off): pick the next day in the strip.
      await tapVisible(tester, find.byKey(const ValueKey('day-2')));
      free = find.byWidgetPredicate((w) => w is TimeSlotChip && w.isAvailable);
    }
    await tapVisible(tester, free.first);
    await tapVisible(tester, find.text(AppStrings.bookingContinue));
    await tester.tap(find.text(AppStrings.confirmSubmit));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    final created = (await deps.bookings.fetchBookings()).firstWhere(
      (b) => b.serviceTitle == 'Оформление бороды' && b.isActive,
    );
    final tile = find.byWidgetPredicate(
      (w) => w is BookingTile && w.booking.id == created.id,
    );
    await tapVisible(tester, tile);
    expect(find.text(AppStrings.bookingDetailsTitle), findsOneWidget);
    await tapVisible(tester, find.text(AppStrings.bookingActionCancel));
    await tester.tap(
      find.widgetWithText(FilledButton, AppStrings.cancelDialogConfirm),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.bookingCancelled), findsOneWidget);
    final after = (await deps.bookings.fetchBookings()).firstWhere(
      (b) => b.id == created.id,
    );
    expect(after.isCancelled, isTrue);
  });

  testWidgets('2. a completed visit gets a review and the rating changes', (
    tester,
  ) async {
    final deps = await launch(tester);
    await signIn(tester, 'aliya');
    await openTab(tester, AppStrings.tabBookings);
    await tester.tap(find.textContaining('Прошедшие'));
    await tester.pumpAndSettle();

    final write = find.text(AppStrings.reviewWrite).first;
    final booking = tester
        .widget<BookingTile>(
          find.ancestor(of: write, matching: find.byType(BookingTile)),
        )
        .booking;
    final before = RatingSummary.of(
      await deps.reviews.fetchOrganizationReviews(booking.organizationId),
    );

    await tapVisible(tester, write);
    await tester.tap(find.byKey(const ValueKey('star-5')));
    await tester.enterText(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(TextField),
      ),
      'Всё понравилось',
    );
    await tester.tap(find.text(AppStrings.reviewFormSubmit));
    await tester.pumpAndSettle();

    final after = RatingSummary.of(
      await deps.reviews.fetchOrganizationReviews(booking.organizationId),
    );
    expect(after.count, before.count + 1);
    expect(find.text(AppStrings.reviewPublished), findsOneWidget);
  });

  testWidgets('3. double tap adds a place to favorites', (tester) async {
    await launch(tester);
    await signIn(tester, 'damir');

    final card = find.widgetWithText(OrganizationCard, 'Автосервис «Гараж 24»');
    await tester.tap(card);
    await tester.pump(kDoubleTapMinTime);
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.favoriteAdded), findsOneWidget);

    await openTab(tester, AppStrings.tabFavorites);
    expect(find.text('Автосервис «Гараж 24»'), findsOneWidget);
  });

  testWidgets('4. owner sees the dashboard and switches the period', (
    tester,
  ) async {
    final deps = await launch(tester);
    await signIn(tester, 'north');

    expect(find.text(AppStrings.dashboardTitle), findsWidgets);
    final week = await deps.analytics.fetch(orgNorth, AnalyticsPeriod.days7);
    final quarter = await deps.analytics.fetch(
      orgNorth,
      AnalyticsPeriod.days90,
    );
    expect(quarter.bookings, greaterThan(week.bookings));

    await tester.tap(find.text(AppStrings.periodDays(90)));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.chartBookingsWeekly), findsOneWidget);
    expect(find.text('${quarter.bookings}'), findsWidgets);

    await tester.tap(find.text(AppStrings.periodDays(7)));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.chartBookingsDaily), findsOneWidget);
    expect(find.text('${week.bookings}'), findsWidgets);
  });

  testWidgets('5. owner edits the organization and adds a priced service', (
    tester,
  ) async {
    final deps = await launch(tester);
    await signIn(tester, 'north');

    await openTab(tester, AppStrings.ownerTabOrganization);
    await tester.enterText(
      find.widgetWithText(TextField, AppStrings.businessFieldDescription),
      'Стрижки, борода и горячие полотенца.',
    );
    await tapVisible(tester, find.text(AppStrings.businessSave));
    expect(find.text(AppStrings.businessSaved), findsOneWidget);
    expect(
      (await deps.catalog.fetchOrganization(orgNorth)).description,
      'Стрижки, борода и горячие полотенца.',
    );

    await openTab(tester, AppStrings.ownerTabServices);
    await tester.tap(find.text(AppStrings.ownerServiceAdd));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, AppStrings.serviceFieldTitle),
      'Камуфляж седины',
    );
    await tester.enterText(
      find.widgetWithText(TextField, AppStrings.serviceFieldPrice),
      '5000',
    );
    await tapVisible(tester, find.text(AppStrings.serviceOptionAdd));
    await tester.enterText(
      find.byKey(const ValueKey('option-label-0')),
      'Короткие',
    );
    await tester.enterText(
      find.byKey(const ValueKey('option-price-0')),
      '5000',
    );
    await tapVisible(tester, find.text(AppStrings.serviceOptionAdd));
    await tester.enterText(
      find.byKey(const ValueKey('option-label-1')),
      'Длинные',
    );
    await tester.enterText(
      find.byKey(const ValueKey('option-price-1')),
      '7000',
    );
    await tapVisible(tester, find.text('Арман С.'));
    await tester.tap(find.text(AppStrings.serviceSave));
    await tester.pumpAndSettle();

    expect(find.text('Камуфляж седины'), findsOneWidget);
    final services = await deps.catalog.fetchServices(organizationId: orgNorth);
    final created = services.firstWhere((s) => s.title == 'Камуфляж седины');
    expect(created.priceOptions.map((o) => o.priceKzt), [5000, 7000]);
  });

  testWidgets('6. an owner cannot reach another organization', (tester) async {
    final deps = await launch(tester);
    await signIn(tester, 'north');

    expect(
      () => deps.analytics.fetch(orgWhiteLine, AnalyticsPeriod.days30),
      throwsA(isA<AccessDeniedException>()),
    );
    expect(
      () => deps.bookings.fetchOrganizationBookings(orgWhiteLine),
      throwsA(isA<AccessDeniedException>()),
    );
    final other = await deps.catalog.fetchOrganization(orgWhiteLine);
    expect(
      () => deps.business.updateOrganization(other.copyWith(name: 'Захват')),
      throwsA(isA<AccessDeniedException>()),
    );
    // The owner shell has no customer catalog and no "Записаться".
    expect(find.text(AppStrings.tabCatalog), findsNothing);
    expect(find.text(AppStrings.detailsBook), findsNothing);
  });

  testWidgets('7. moving and cancelling a booking updates reminders', (
    tester,
  ) async {
    final deps = await launch(tester);
    await signIn(tester, 'damir');
    await deps.reminders.sync();

    final booking = (await deps.bookings.fetchBookings())
        .where((b) => b.isActive && b.canBeChangedAt(DateTime.now()))
        .reduce((a, b) => a.startAt.isAfter(b.startAt) ? a : b);
    final before = reminders.scheduled.values
        .where((r) => r.bookingId == booking.id)
        .map((r) => r.fireAt)
        .toSet();
    expect(before, isNotEmpty);

    final service = deps.database.tables.services[booking.serviceId]!;
    final day = booking.startAt.add(const Duration(days: 1));
    final slots = await deps.bookings.fetchTimeSlots(
      service: service,
      specialist: booking.specialist,
      day: DateTime(day.year, day.month, day.day),
      ignoreBookingId: booking.id,
    );
    final free = slots.where((s) => s.isAvailable);
    if (free.isNotEmpty) {
      await deps.bookings.rescheduleBooking(
        booking.id,
        startAt: free.first.startAt,
        specialist: booking.specialist,
      );
      await deps.reminders.sync();
      final moved = reminders.scheduled.values
          .where((r) => r.bookingId == booking.id)
          .map((r) => r.fireAt)
          .toSet();
      expect(moved.intersection(before), isEmpty);
    }

    await deps.bookings.cancelBooking(booking.id);
    await deps.reminders.sync();
    expect(
      reminders.scheduled.values.where((r) => r.bookingId == booking.id),
      isEmpty,
    );
  });

  testWidgets('8. sign-out shows the welcome screen also after a restart', (
    tester,
  ) async {
    await launch(tester);
    await signIn(tester, 'aliya');
    await openTab(tester, AppStrings.tabProfile);
    await tester.scrollUntilVisible(find.text(AppStrings.signOut), 200);
    await tester.tap(find.text(AppStrings.signOut));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, AppStrings.signOut));
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(reminders.scheduled, isEmpty);

    // "Restart": a new app on the same stored data.
    await tester.pumpWidget(const SizedBox());
    await launch(tester);
    expect(find.byType(WelcomeScreen), findsOneWidget);
    await tester.tap(find.text(AppStrings.welcomeShowServices));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:slotly/core/app_strings.dart';
import 'package:slotly/features/booking/presentation/booking_form_screen.dart';
import 'package:slotly/features/booking/presentation/bookings_controller.dart';
import 'package:slotly/features/catalog/presentation/service_details_screen.dart';

import '../helpers/test_app.dart';

void main() {
  const largeText = 2.0;

  testWidgets('welcome and sign-in fit with large text', (tester) async {
    await pumpApp(tester, textScale: largeText);
    expect(find.text(AppStrings.appTagline), findsOneWidget);
    await tester.ensureVisible(find.text(AppStrings.welcomeShowServices));
    await tester.tap(find.text(AppStrings.welcomeShowServices));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.signInSubtitle), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('customer tabs fit with large text', (tester) async {
    await pumpApp(tester, login: 'aliya', textScale: largeText);
    for (final tab in [
      AppStrings.tabFavorites,
      AppStrings.tabBookings,
      AppStrings.tabProfile,
    ]) {
      await openTab(tester, tab);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('owner tabs fit with large text', (tester) async {
    await pumpApp(tester, login: 'north', textScale: largeText);
    for (final tab in [
      AppStrings.ownerTabBookings,
      AppStrings.ownerTabServices,
      AppStrings.ownerTabReviews,
      AppStrings.ownerTabOrganization,
    ]) {
      await openTab(tester, tab);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('details and booking form fit with large text', (tester) async {
    usePhoneSurface(tester, textScale: largeText);
    final deps = await createTestDependencies();
    addTearDown(deps.dispose);
    await signIn(deps, 'aliya');
    final service = deps.database.tables.services['svc-english']!;
    final bookings = BookingsController(deps.bookings);
    addTearDown(bookings.dispose);

    await pumpScreen(
      tester,
      ServiceDetailsScreen(service: service, onBook: () {}),
    );
    usePhoneSurface(tester, textScale: largeText);
    expect(find.text(service.title), findsOneWidget);

    await pumpScreen(
      tester,
      BookingFormScreen(
        service: service,
        bookings: bookings,
        clock: () => testNow,
        onBooked: (_) {},
      ),
    );
    usePhoneSurface(tester, textScale: largeText);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.bookingContinue), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

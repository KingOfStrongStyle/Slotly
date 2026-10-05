import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slotly/app/app.dart';
import 'package:slotly/app/app_scope.dart';
import 'package:slotly/app/theme.dart';
import 'package:slotly/core/app_strings.dart';
import 'package:slotly/features/booking/presentation/booking_form_screen.dart';
import 'package:slotly/features/catalog/data/demo_services.dart';
import 'package:slotly/features/catalog/presentation/service_details_screen.dart';

import '../helpers/test_app.dart';

/// Layout overflow is reported as a test failure by the framework, so these
/// tests fail if a main screen breaks at a large accessibility font size.
void main() {
  const largeText = 2.0;
  final service = demoServices.firstWhere((s) => s.id == 'svc-english');

  testWidgets('welcome and home tabs fit with large text', (tester) async {
    usePhoneSurface(tester, textScale: largeText);
    await tester.pumpWidget(
      const SlotlyApp(createDependencies: createTestDependencies),
    );
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.appTagline), findsOneWidget);

    await tester.ensureVisible(find.text(AppStrings.welcomeShowServices));
    await tester.tap(find.text(AppStrings.welcomeShowServices));
    await tester.pumpAndSettle();

    for (final tab in [AppStrings.tabBookings, AppStrings.tabProfile]) {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(tab),
        ),
      );
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('details and booking form fit with large text', (tester) async {
    usePhoneSurface(tester, textScale: largeText);
    final dependencies = createTestDependencies();
    addTearDown(dependencies.dispose);

    await tester.pumpWidget(
      AppScope(
        dependencies: dependencies,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: ServiceDetailsScreen(service: service, onBook: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(service.title), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: BookingFormScreen(
          service: service,
          bookings: dependencies.bookings,
          clock: () => testNow,
          onBooked: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.bookingContinue), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

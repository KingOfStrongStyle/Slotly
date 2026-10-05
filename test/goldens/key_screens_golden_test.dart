import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slotly/app/theme.dart';
import 'package:slotly/features/booking/data/in_memory_booking_repository.dart';
import 'package:slotly/features/booking/presentation/bookings_controller.dart';
import 'package:slotly/features/booking/presentation/bookings_screen.dart';
import 'package:slotly/features/catalog/data/demo_services.dart';
import 'package:slotly/features/catalog/presentation/catalog_screen.dart';
import 'package:slotly/features/catalog/presentation/widgets/service_card.dart';
import 'package:slotly/features/welcome/welcome_screen.dart';

import '../helpers/test_app.dart';

/// Golden tests use a fixed 360 × 780 surface, a pixel ratio of 1, the
/// built-in deterministic test font and demo data only, so the images do
/// not depend on the current date or the developer's machine.
void main() {
  Future<void> pumpGolden(
    WidgetTester tester,
    Widget child, {
    ThemeData? theme,
    Size size = const Size(360, 780),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme ?? AppTheme.light(),
        locale: const Locale('ru'),
        supportedLocales: const [Locale('ru')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: child,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('welcome screen', (tester) async {
    await pumpGolden(tester, WelcomeScreen(onShowServices: (_) {}));

    await expectLater(
      find.byType(WelcomeScreen),
      matchesGoldenFile('goldens/welcome_light.png'),
    );
  });

  testWidgets('service card', (tester) async {
    await pumpGolden(
      tester,
      Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: ServiceCard(service: demoServices.first, onTap: () {}),
          ),
        ),
      ),
      size: const Size(360, 220),
    );

    await expectLater(
      find.byType(ServiceCard),
      matchesGoldenFile('goldens/service_card.png'),
    );
  });

  testWidgets('catalog empty state', (tester) async {
    await pumpGolden(
      tester,
      Scaffold(
        body: CatalogScreen(services: const [], onServiceSelected: (_) {}),
      ),
    );

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/catalog_empty.png'),
    );
  });

  testWidgets('bookings empty state in dark theme', (tester) async {
    final controller = BookingsController(
      InMemoryBookingRepository(clock: () => testNow),
    );
    addTearDown(controller.dispose);
    await controller.load();

    await pumpGolden(
      tester,
      Scaffold(
        body: BookingsScreen(bookings: controller, onBrowseServices: () {}),
      ),
      theme: AppTheme.dark(),
    );

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/bookings_empty_dark.png'),
    );
  });
}

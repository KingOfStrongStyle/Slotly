import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slotly/app/app_scope.dart';
import 'package:slotly/app/theme.dart';

/// Fixed "now" for all widget tests: Monday, 5 October 2026, 09:00.
final testNow = DateTime(2026, 10, 5, 9);

/// Emulates a typical Android phone (Pixel 7: 1080 x 2400 px, 411 x 914 dp).
void usePhoneSurface(WidgetTester tester, {double textScale = 1}) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.625;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

AppDependencies createTestDependencies() =>
    AppDependencies.demo(clock: () => testNow);

/// Wraps a single screen with the same theme and localization as the app.
Future<void> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  ThemeData? theme,
  AppDependencies? dependencies,
}) async {
  usePhoneSurface(tester);
  final app = MaterialApp(
    theme: theme ?? AppTheme.light(),
    locale: const Locale('ru'),
    supportedLocales: const [Locale('ru')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: screen,
  );
  await tester.pumpWidget(
    dependencies == null
        ? app
        : AppScope(dependencies: dependencies, child: app),
  );
  await tester.pumpAndSettle();
}

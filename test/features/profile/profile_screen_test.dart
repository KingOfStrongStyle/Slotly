import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slotly/app/app.dart';
import 'package:slotly/core/app_strings.dart';
import 'package:slotly/features/diagnostics/presentation/diagnostics_screen.dart';
import 'package:slotly/features/gesture_checkin/presentation/ticket_check_in_screen.dart';
import 'package:slotly/features/gesture_lab/presentation/gesture_lab_screen.dart';

import '../../helpers/test_app.dart';

Future<void> _openProfile(WidgetTester tester) async {
  usePhoneSurface(tester);
  await tester.pumpWidget(
    const SlotlyApp(createDependencies: createTestDependencies),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(AppStrings.welcomeShowServices));
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(AppStrings.tabProfile),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('dark theme switch changes the app theme', (tester) async {
    await _openProfile(tester);

    expect(find.text(AppStrings.profileDemoUserName), findsOneWidget);
    expect(find.text(AppStrings.appVersionLabel), findsOneWidget);
    expect(
      Theme.of(tester.element(find.byType(NavigationBar))).brightness,
      Brightness.light,
    );

    await tester.tap(find.text(AppStrings.profileDarkTheme));
    await tester.pumpAndSettle();

    expect(
      Theme.of(tester.element(find.byType(NavigationBar))).brightness,
      Brightness.dark,
    );
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
  });

  testWidgets('demo notifications switch toggles', (tester) async {
    await _openProfile(tester);
    final tile = find.widgetWithText(
      SwitchListTile,
      AppStrings.profileNotifications,
    );

    expect(tester.widget<SwitchListTile>(tile).value, isTrue);
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(tile).value, isFalse);
  });

  testWidgets('opens diagnostics and returns with Back', (tester) async {
    await _openProfile(tester);

    await tester.tap(find.text(AppStrings.diagnosticsTitle));
    await tester.pumpAndSettle();
    expect(find.byType(DiagnosticsScreen), findsOneWidget);

    // System Back button, as on an Android device.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(DiagnosticsScreen), findsNothing);
    expect(find.text(AppStrings.profileTitle), findsWidgets);
    expect(find.byTooltip('Назад'), findsNothing);
  });

  testWidgets('opens Gesture Lab and ticket check-in', (tester) async {
    await _openProfile(tester);

    await tester.tap(find.text(AppStrings.gestureLabTitle));
    await tester.pumpAndSettle();
    expect(find.byType(GestureLabScreen), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text(AppStrings.checkInTitle));
    await tester.tap(find.text(AppStrings.checkInTitle));
    await tester.pumpAndSettle();
    expect(find.byType(TicketCheckInScreen), findsOneWidget);
  });
}

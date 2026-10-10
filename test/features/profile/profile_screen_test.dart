import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slotly/core/app_strings.dart';
import 'package:slotly/features/diagnostics/presentation/diagnostics_screen.dart';
import 'package:slotly/features/gesture_lab/presentation/gesture_lab_screen.dart';
import 'package:slotly/features/reminders/presentation/reminders_screen.dart';
import 'package:slotly/features/welcome/welcome_screen.dart';

import '../../helpers/test_app.dart';

Future<void> _openProfile(WidgetTester tester) async {
  await pumpApp(tester, login: 'aliya');
  await openTab(tester, AppStrings.tabProfile);
}

void main() {
  testWidgets('shows the signed-in customer', (tester) async {
    await _openProfile(tester);
    expect(find.text('Алия Н.'), findsOneWidget);
    expect(find.textContaining('aliya'), findsOneWidget);
    expect(find.text(AppStrings.appVersionLabel), findsOneWidget);
  });

  testWidgets('dark theme switch changes the app theme', (tester) async {
    await _openProfile(tester);
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

  testWidgets('opens reminders, diagnostics and Gesture Lab', (tester) async {
    await _openProfile(tester);

    await tester.tap(find.text(AppStrings.profileReminders));
    await tester.pumpAndSettle();
    expect(find.byType(RemindersScreen), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.diagnosticsTitle));
    await tester.pumpAndSettle();
    expect(find.byType(DiagnosticsScreen), findsOneWidget);
    // System Back button, as on an Android device.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(DiagnosticsScreen), findsNothing);

    await tester.scrollUntilVisible(find.text(AppStrings.gestureLabTitle), 200);
    await tester.tap(find.text(AppStrings.gestureLabTitle));
    await tester.pumpAndSettle();
    expect(find.byType(GestureLabScreen), findsOneWidget);
  });

  testWidgets('sign-out asks first and returns to the welcome screen', (
    tester,
  ) async {
    await _openProfile(tester);
    final signOut = find.text(AppStrings.signOut);
    // The list is built lazily: scroll until the last tile exists.
    await tester.scrollUntilVisible(signOut, 200);
    await tester.tap(signOut);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.signOutConfirmTitle), findsOneWidget);

    await tester.tap(find.text(AppStrings.signOutCancel));
    await tester.pumpAndSettle();
    expect(find.text('Алия Н.'), findsOneWidget);

    await tester.tap(signOut);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, AppStrings.signOut));
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeScreen), findsOneWidget);
    // Back cannot return into the closed session.
    expect(await tester.binding.handlePopRoute(), isFalse);
  });
}

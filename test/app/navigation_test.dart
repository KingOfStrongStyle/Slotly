import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slotly/app/client_shell.dart';
import 'package:slotly/core/app_strings.dart';
import 'package:slotly/features/auth/presentation/login_screen.dart';
import 'package:slotly/features/catalog/presentation/catalog_screen.dart';
import 'package:slotly/features/welcome/welcome_screen.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets('welcome keeps the category through sign-in into the catalog', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text(AppStrings.appTagline), findsOneWidget);
    expect(find.text(AppStrings.welcomeNoCategory), findsOneWidget);

    await tester.tap(find.text(AppStrings.categoryDentistry));
    await tester.pump();
    expect(
      find.text(
        AppStrings.welcomeSelectedCategory(AppStrings.categoryDentistry),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text(AppStrings.welcomeShowServices));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('login-field')), 'damir');
    await tester.enterText(
      find.byKey(const ValueKey('password-field')),
      'damir-demo',
    );
    await tester.tap(
      find.widgetWithText(FilledButton, AppStrings.signInSubmit),
    );
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeScreen), findsNothing);
    expect(find.byType(CatalogScreen), findsOneWidget);
    expect(find.text('Стоматология «Белая линия»'), findsOneWidget);
    expect(find.text('Барбершоп «Северный»'), findsNothing);
  });

  testWidgets('NavigationBar switches tabs and Back returns to the catalog', (
    tester,
  ) async {
    await pumpApp(tester, login: 'aliya');
    expect(find.byType(ClientShell), findsOneWidget);

    final navigationBar = find.byType(NavigationBar);
    await openTab(tester, AppStrings.tabProfile);
    expect(tester.widget<NavigationBar>(navigationBar).selectedIndex, 3);

    final popped = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(popped, isTrue, reason: 'Back is consumed by the shell');
    expect(tester.widget<NavigationBar>(navigationBar).selectedIndex, 0);
  });

  testWidgets('a restored session opens the shell without the welcome', (
    tester,
  ) async {
    final deps = await createTestDependencies();
    await signIn(deps, 'aliya');
    await pumpApp(tester, dependencies: deps);
    expect(find.byType(WelcomeScreen), findsNothing);
    expect(find.byType(ClientShell), findsOneWidget);
  });
}

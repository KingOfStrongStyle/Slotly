import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slotly/app/app.dart';
import 'package:slotly/core/app_strings.dart';
import 'package:slotly/features/catalog/presentation/catalog_screen.dart';
import 'package:slotly/features/welcome/welcome_screen.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets('welcome keeps the selected category and opens the catalog', (
    tester,
  ) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(
      const SlotlyApp(createDependencies: createTestDependencies),
    );
    await tester.pumpAndSettle();

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

    expect(find.byType(WelcomeScreen), findsNothing);
    expect(find.byType(CatalogScreen), findsOneWidget);
    expect(find.text('Профессиональная чистка зубов'), findsOneWidget);
    expect(find.text('Мужская стрижка'), findsNothing);
  });

  testWidgets('NavigationBar switches tabs and Back returns to services', (
    tester,
  ) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(
      const SlotlyApp(createDependencies: createTestDependencies),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.welcomeShowServices));
    await tester.pumpAndSettle();

    final navigationBar = find.byType(NavigationBar);
    await tester.tap(
      find.descendant(
        of: navigationBar,
        matching: find.text(AppStrings.tabProfile),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<NavigationBar>(navigationBar).selectedIndex, 2);

    final popped = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(popped, isTrue, reason: 'Back is consumed by the shell');
    expect(tester.widget<NavigationBar>(navigationBar).selectedIndex, 0);
  });
}

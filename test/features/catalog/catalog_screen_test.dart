import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slotly/core/app_strings.dart';
import 'package:slotly/features/catalog/data/demo_services.dart';
import 'package:slotly/features/catalog/domain/service.dart';
import 'package:slotly/features/catalog/presentation/catalog_screen.dart';
import 'package:slotly/features/catalog/presentation/widgets/service_card.dart';

import '../../helpers/test_app.dart';

void main() {
  Future<List<Service>> pumpCatalog(
    WidgetTester tester, {
    ServiceCategory? initialCategory,
  }) async {
    final selected = <Service>[];
    await pumpScreen(
      tester,
      Scaffold(
        body: CatalogScreen(
          services: demoServices,
          initialCategory: initialCategory,
          onServiceSelected: selected.add,
        ),
      ),
    );
    return selected;
  }

  testWidgets('shows services and the result counter', (tester) async {
    await pumpCatalog(tester);

    expect(find.text('Мужская стрижка'), findsOneWidget);
    expect(
      find.text(AppStrings.catalogFoundCount(demoServices.length)),
      findsOneWidget,
    );
  });

  testWidgets('search filters by title and can be cleared', (tester) async {
    await pumpCatalog(tester);

    await tester.enterText(find.byType(TextField), 'маникюр');
    await tester.pump();

    expect(find.byType(ServiceCard), findsOneWidget);
    expect(find.text('Маникюр с покрытием'), findsOneWidget);

    await tester.tap(find.byTooltip(AppStrings.catalogClearSearch));
    await tester.pump();

    expect(
      find.text(AppStrings.catalogFoundCount(demoServices.length)),
      findsOneWidget,
    );
  });

  testWidgets('shows empty state and resets filters', (tester) async {
    await pumpCatalog(tester);

    await tester.enterText(find.byType(TextField), 'полёт на луну');
    await tester.pump();

    expect(find.text(AppStrings.catalogEmptyTitle), findsOneWidget);
    expect(find.byType(ServiceCard), findsNothing);

    await tester.tap(find.text(AppStrings.catalogResetFilters));
    await tester.pump();

    expect(find.text(AppStrings.catalogEmptyTitle), findsNothing);
    expect(find.byType(ServiceCard), findsWidgets);
  });

  testWidgets('category chips filter the list', (tester) async {
    await pumpCatalog(tester, initialCategory: ServiceCategory.autoService);

    expect(find.text('Сезонный шиномонтаж'), findsOneWidget);
    expect(find.text('Мужская стрижка'), findsNothing);

    await tester.tap(find.text(AppStrings.categoryAll));
    await tester.pump();

    expect(find.text('Мужская стрижка'), findsOneWidget);
  });

  testWidgets('tapping a card reports the selected service', (tester) async {
    final selected = await pumpCatalog(tester);

    await tester.tap(find.text('Мужская стрижка'));

    expect(selected.single.id, 'svc-men-haircut');
  });
}

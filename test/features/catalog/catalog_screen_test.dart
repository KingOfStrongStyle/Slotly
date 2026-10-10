import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slotly/core/app_strings.dart';
import 'package:slotly/data/seed/demo_catalog.dart';
import 'package:slotly/features/catalog/data/catalog_repository.dart';
import 'package:slotly/features/catalog/domain/organization.dart';
import 'package:slotly/features/catalog/domain/service.dart';
import 'package:slotly/features/catalog/presentation/catalog_controller.dart';
import 'package:slotly/features/catalog/presentation/catalog_screen.dart';
import 'package:slotly/features/catalog/presentation/widgets/organization_card.dart';
import 'package:slotly/features/favorites/data/favorites_repository.dart';
import 'package:slotly/features/reviews/data/review_repository.dart';

import '../../helpers/test_app.dart';

void main() {
  late TestData data;
  late CatalogController controller;
  late List<Organization> openedOrganizations;
  late List<Service> openedServices;

  Future<void> pumpCatalog(
    WidgetTester tester, {
    ServiceCategory? initialCategory,
  }) async {
    data = await TestData.create(withActivity: true);
    data.signInAs('damir');
    controller = CatalogController(
      catalog: LocalCatalogRepository(data.context),
      reviews: LocalReviewRepository(data.context),
      favorites: LocalFavoritesRepository(data.context),
    );
    addTearDown(controller.dispose);
    await controller.load();
    openedOrganizations = [];
    openedServices = [];
    await pumpScreen(
      tester,
      Scaffold(
        body: CatalogScreen(
          controller: controller,
          initialCategory: initialCategory,
          onOrganizationSelected: openedOrganizations.add,
          onServiceSelected: openedServices.add,
        ),
      ),
    );
  }

  Future<void> search(WidgetTester tester, String query) async {
    await tester.enterText(find.byType(TextField), query);
    await tester.pumpAndSettle();
  }

  testWidgets('shows all places with their rating', (tester) async {
    await pumpCatalog(tester);

    expect(
      find.text(AppStrings.catalogFoundCount(demoOrganizations.length)),
      findsOneWidget,
    );
    final card = tester.widget<OrganizationCard>(
      find.widgetWithText(OrganizationCard, 'Барбершоп «Северный»'),
    );
    expect(card.rating.count, greaterThan(0));
    expect(find.textContaining('отзыв'), findsWidgets);
  });

  testWidgets('a place without reviews says so', (tester) async {
    await pumpCatalog(tester, initialCategory: ServiceCategory.tutoring);
    expect(find.text('Учебный центр «Формула»'), findsOneWidget);
    expect(find.text(AppStrings.ratingNoReviews), findsOneWidget);
  });

  testWidgets('search finds places by name and by their services', (
    tester,
  ) async {
    await pumpCatalog(tester);

    await search(tester, 'шиномонтаж');
    expect(find.text('Автосервис «Гараж 24»'), findsOneWidget);
    expect(find.text(AppStrings.catalogFoundCount(1)), findsOneWidget);

    await search(tester, 'ЛАВАНДА');
    expect(find.text('Салон красоты «Лаванда»'), findsOneWidget);
  });

  testWidgets('services mode keeps the lab search over services', (
    tester,
  ) async {
    await pumpCatalog(tester);
    await tester.tap(find.text(AppStrings.catalogServices));
    await tester.pumpAndSettle();

    await search(tester, 'СТРИЖ');
    expect(find.text('Мужская стрижка'), findsOneWidget);
    expect(find.text('Детская стрижка'), findsOneWidget);
    expect(find.textContaining('Барбершоп «Северный»'), findsWidgets);

    await tester.tap(find.text('Мужская стрижка'));
    expect(openedServices.single.id, 'svc-men-haircut');
  });

  testWidgets('category filter and empty state with reset', (tester) async {
    await pumpCatalog(tester, initialCategory: ServiceCategory.dentistry);
    expect(find.text('Стоматология «Белая линия»'), findsOneWidget);
    expect(find.text('Барбершоп «Северный»'), findsNothing);

    await search(tester, 'луна');
    expect(find.text(AppStrings.catalogEmptyTitle), findsOneWidget);
    await tester.tap(find.text(AppStrings.catalogResetFilters));
    await tester.pumpAndSettle();
    expect(
      find.text(AppStrings.catalogFoundCount(demoOrganizations.length)),
      findsOneWidget,
    );
  });

  testWidgets('tap opens the place', (tester) async {
    await pumpCatalog(tester);
    await tester.tap(find.text('Автосервис «Гараж 24»'));
    // A single tap is confirmed after the double-tap timeout.
    await tester.pump(kDoubleTapTimeout);
    await tester.pumpAndSettle();
    expect(openedOrganizations.single.id, orgGarage);
  });

  testWidgets('double tap adds to favorites, the heart button removes', (
    tester,
  ) async {
    await pumpCatalog(tester);
    final card = find.widgetWithText(OrganizationCard, 'Автосервис «Гараж 24»');

    await tester.tap(card);
    await tester.pump(kDoubleTapMinTime);
    await tester.tap(card);
    await tester.pumpAndSettle();

    expect(controller.data!.isFavorite(orgGarage), isTrue);
    expect(openedOrganizations, isEmpty, reason: 'double tap is not a tap');
    final button = find.descendant(
      of: card,
      matching: find.byTooltip(AppStrings.favoriteRemove),
    );
    expect(button, findsOneWidget);

    // Double tap again never removes by accident.
    await tester.tap(card);
    await tester.pump(kDoubleTapMinTime);
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(controller.data!.isFavorite(orgGarage), isTrue);

    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(controller.data!.isFavorite(orgGarage), isFalse);
  });
}

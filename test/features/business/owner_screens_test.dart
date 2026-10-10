import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slotly/app/client_shell.dart';
import 'package:slotly/app/owner_shell.dart';
import 'package:slotly/core/app_strings.dart';
import 'package:slotly/data/seed/demo_catalog.dart';
import 'package:slotly/features/business/presentation/business_profile_screen.dart';
import 'package:slotly/features/business/presentation/owner_reviews_screen.dart';
import 'package:slotly/features/catalog/domain/organization.dart';
import 'package:slotly/features/catalog/presentation/organization_screen.dart';
import 'package:slotly/features/gesture_checkin/presentation/ticket_check_in_screen.dart';

import '../../helpers/test_app.dart';

void main() {
  testWidgets('owner sees the owner shell, not the customer one', (
    tester,
  ) async {
    await pumpApp(tester, login: 'north');

    expect(find.byType(OwnerShell), findsOneWidget);
    expect(find.byType(ClientShell), findsNothing);
    for (final tab in [
      AppStrings.ownerTabDashboard,
      AppStrings.ownerTabBookings,
      AppStrings.ownerTabServices,
      AppStrings.ownerTabReviews,
      AppStrings.ownerTabOrganization,
    ]) {
      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(tab),
        ),
        findsOneWidget,
      );
    }
    expect(find.text(AppStrings.tabFavorites), findsNothing);
    expect(find.text('Барбершоп «Северный»'), findsWidgets);
  });

  testWidgets('customer has no owner tabs', (tester) async {
    await pumpApp(tester, login: 'aliya');
    expect(find.text(AppStrings.ownerTabDashboard), findsNothing);
    expect(find.text(AppStrings.ownerTabOrganization), findsNothing);
  });

  testWidgets('dashboard period filter changes every number', (tester) async {
    await pumpApp(tester, login: 'north');
    expect(find.text(AppStrings.chartBookingsDaily), findsOneWidget);

    await tester.tap(find.text(AppStrings.periodDays(90)));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.chartBookingsWeekly), findsOneWidget);

    await tester.tap(find.byTooltip(AppStrings.chartShowTable).first);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.chartColumnPeriod), findsOneWidget);
  });

  testWidgets('organization preview has no booking or favorite actions', (
    tester,
  ) async {
    await pumpApp(tester, login: 'north');
    await openTab(tester, AppStrings.ownerTabOrganization);
    await scrollToIn(
      tester,
      find.text(AppStrings.businessPreview),
      screen: BusinessProfileScreen,
    );
    await tester.tap(find.text(AppStrings.businessPreview));
    await tester.pumpAndSettle();

    expect(find.byType(OrganizationScreen), findsOneWidget);
    expect(find.byTooltip(AppStrings.favoriteAdd), findsNothing);
    await tester.tap(find.text('Оформление бороды').first);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.detailsBook), findsNothing);
  });

  testWidgets('owner adds a service with a price list', (tester) async {
    final deps = await pumpApp(tester, login: 'north');
    await openTab(tester, AppStrings.ownerTabServices);
    await tester.tap(find.text(AppStrings.ownerServiceAdd));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.serviceSave));
    await tester.pumpAndSettle();
    expect(
      find.text(AppStrings.serviceTitleLength(3, 60)),
      findsOneWidget,
      reason: 'empty form shows errors',
    );
    expect(find.text(AppStrings.serviceNoSpecialists), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, AppStrings.serviceFieldTitle),
      'Камуфляж седины',
    );
    await tester.enterText(
      find.widgetWithText(TextField, AppStrings.serviceFieldPrice),
      '5000',
    );
    await tester.ensureVisible(find.text(AppStrings.serviceOptionAdd));
    await tester.tap(find.text(AppStrings.serviceOptionAdd));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('option-label-0')),
      'Короткие',
    );
    await tester.enterText(
      find.byKey(const ValueKey('option-price-0')),
      '5000',
    );
    await tester.ensureVisible(find.text('Арман С.'));
    await tester.tap(find.text('Арман С.'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.serviceSave));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.serviceSaved), findsOneWidget);
    expect(find.text('Камуфляж седины'), findsOneWidget);
    final saved = deps.database.tables.services.values.firstWhere(
      (s) => s.title == 'Камуфляж седины',
    );
    expect(saved.priceOptions.single.label, 'Короткие');
  });

  testWidgets('long press hides a service; the menu button does the same', (
    tester,
  ) async {
    final deps = await pumpApp(tester, login: 'north');
    await openTab(tester, AppStrings.ownerTabServices);

    await tester.longPress(find.text('Оформление бороды'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.ownerServiceHide));
    await tester.pumpAndSettle();
    expect(deps.database.tables.services['svc-beard']!.isHidden, isTrue);
    expect(find.text(AppStrings.ownerServiceHidden), findsOneWidget);

    final menu = find.descendant(
      of: find.ancestor(
        of: find.text('Оформление бороды'),
        matching: find.byType(Card),
      ),
      matching: find.byTooltip(AppStrings.ownerServiceActions),
    );
    await tester.tap(menu);
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.ownerServiceShow));
    await tester.pumpAndSettle();
    expect(deps.database.tables.services['svc-beard']!.isHidden, isFalse);
  });

  testWidgets('owner edits the profile with validation', (tester) async {
    final deps = await pumpApp(tester, login: 'north');
    await openTab(tester, AppStrings.ownerTabOrganization);

    final name = find.widgetWithText(TextField, AppStrings.businessFieldName);
    await tester.enterText(name, 'A');
    await tester.tap(find.text(AppStrings.businessSave));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.businessNameLength), findsOneWidget);

    await tester.enterText(name, 'Северный Барбер');
    await tester.tap(find.text(AppStrings.businessSave));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.businessSaved), findsOneWidget);
    expect(
      deps.database.tables.organizations[orgNorth]!.name,
      'Северный Барбер',
    );
  });

  testWidgets('a sixth photo is refused with a message', (tester) async {
    final picker = FakePhotoPicker();
    final deps = await createTestDependencies(photoPicker: picker);
    await pumpApp(tester, login: 'north', dependencies: deps);
    await openTab(tester, AppStrings.ownerTabOrganization);

    final add = find.text(AppStrings.businessPhotoAdd);
    await scrollToIn(tester, add, screen: BusinessProfileScreen);
    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.businessPhotoAdded), findsOneWidget);
    expect(
      deps.database.tables.photos.values.where(
        (p) => p.organizationId == orgNorth,
      ),
      hasLength(Organization.maxPhotos),
    );

    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.businessPhotoLimit), findsOneWidget);
    expect(picker.calls, 1, reason: 'the picker is not opened at the limit');
  });

  testWidgets('owner replies to a review', (tester) async {
    final deps = await pumpApp(tester, login: 'north');
    await openTab(tester, AppStrings.ownerTabReviews);
    final reply = find.text(AppStrings.ownerReviewReply);
    await scrollToIn(tester, reply.first, screen: OwnerReviewsScreen);
    await tester.tap(reply.first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'Спасибо, ждём снова!',
    );
    await tester.pump();
    await tester.tap(find.text(AppStrings.ownerReplySend));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.ownerReplySent), findsOneWidget);
    expect(
      deps.database.tables.reviews.values.where(
        (r) => r.reply?.text == 'Спасибо, ждём снова!',
      ),
      hasLength(1),
    );
  });

  testWidgets('reception check-in opens from the owner bookings', (
    tester,
  ) async {
    await pumpApp(tester, login: 'north');
    await openTab(tester, AppStrings.ownerTabBookings);
    await tester.tap(find.byTooltip(AppStrings.ownerCheckIn));
    await tester.pumpAndSettle();
    expect(find.byType(TicketCheckInScreen), findsOneWidget);
  });
}

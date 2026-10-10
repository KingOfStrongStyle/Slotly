import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slotly/core/app_strings.dart';
import 'package:slotly/data/seed/demo_catalog.dart';
import 'package:slotly/features/catalog/data/catalog_repository.dart';
import 'package:slotly/features/catalog/presentation/organization_screen.dart';
import 'package:slotly/features/catalog/presentation/photo_gallery_screen.dart';
import 'package:slotly/features/favorites/data/favorites_repository.dart';
import 'package:slotly/features/reviews/data/review_repository.dart';

import '../../helpers/test_app.dart';

void main() {
  late TestData data;
  late LocalFavoritesRepository favorites;
  late List<String> openedServices;
  late int reviewsOpened;

  Future<void> pumpOrganization(
    WidgetTester tester, {
    String id = orgNorth,
  }) async {
    data = await TestData.create(withActivity: true);
    data.signInAs('damir');
    favorites = LocalFavoritesRepository(data.context);
    openedServices = [];
    reviewsOpened = 0;
    await pumpScreen(
      tester,
      OrganizationScreen(
        organizationId: id,
        catalog: LocalCatalogRepository(data.context),
        reviews: LocalReviewRepository(data.context),
        favorites: favorites,
        onServiceSelected: (s) => openedServices.add(s.id),
        onOpenReviews: (_) => reviewsOpened++,
      ),
    );
  }

  Finder gallery() => find.byType(PageView).first;

  testWidgets('shows description, price list with options and reviews', (
    tester,
  ) async {
    await pumpOrganization(tester);
    expect(find.text('Барбершоп «Северный»'), findsWidgets);
    expect(find.text(AppStrings.galleryPosition(1, 4)), findsOneWidget);
    expect(find.text('Удлинённая'), findsOneWidget);

    // The gallery is a scrollable too: scroll the page itself.
    await scrollToIn(
      tester,
      find.textContaining(AppStrings.organizationAllReviews),
      screen: OrganizationScreen,
    );
    await tester.tap(find.textContaining(AppStrings.organizationAllReviews));
    expect(reviewsOpened, 1);
  });

  testWidgets('double tap on the photo adds to favorites', (tester) async {
    await pumpOrganization(tester);
    expect(find.byTooltip(AppStrings.favoriteAdd), findsOneWidget);

    await tester.tap(gallery());
    await tester.pump(kDoubleTapMinTime);
    await tester.tap(gallery());
    await tester.pumpAndSettle();

    expect(await favorites.fetchFavoriteIds(), contains(orgNorth));
    expect(find.byTooltip(AppStrings.favoriteRemove), findsOneWidget);
    expect(find.byType(PhotoGalleryScreen), findsNothing);

    // The heart button removes it again.
    await tester.tap(find.byTooltip(AppStrings.favoriteRemove));
    await tester.pumpAndSettle();
    expect(await favorites.fetchFavoriteIds(), isNot(contains(orgNorth)));
  });

  testWidgets('tap opens the gallery; pinch zooms; reset and swipe down', (
    tester,
  ) async {
    await pumpOrganization(tester);
    await tester.tap(gallery());
    await tester.pump(kDoubleTapTimeout);
    await tester.pumpAndSettle();
    expect(find.byType(PhotoGalleryScreen), findsOneWidget);
    expect(find.text(AppStrings.galleryPosition(1, 4)), findsOneWidget);

    // Horizontal swipe: next photo.
    await tester.fling(find.byType(PageView).last, const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.galleryPosition(2, 4)), findsOneWidget);

    // Pinch with two fingers.
    final center = tester.getCenter(find.byType(InteractiveViewer).last);
    final first = await tester.startGesture(center - const Offset(20, 0));
    final second = await tester.startGesture(center + const Offset(20, 0));
    await first.moveBy(const Offset(-80, 0));
    await second.moveBy(const Offset(80, 0));
    await tester.pump();
    await first.up();
    await second.up();
    await tester.pumpAndSettle();
    expect(find.byTooltip(AppStrings.galleryResetZoom), findsOneWidget);

    await tester.tap(find.byTooltip(AppStrings.galleryResetZoom));
    await tester.pumpAndSettle();
    expect(find.byTooltip(AppStrings.galleryResetZoom), findsNothing);

    // Swipe down closes the viewer.
    await tester.fling(find.byType(PageView).last, const Offset(0, 400), 1500);
    await tester.pumpAndSettle();
    expect(find.byType(PhotoGalleryScreen), findsNothing);
  });

  testWidgets('tapping a service opens it', (tester) async {
    await pumpOrganization(tester);
    await scrollToIn(
      tester,
      find.text('Детская стрижка'),
      screen: OrganizationScreen,
    );
    await tester.tap(find.text('Детская стрижка'));
    expect(openedServices, ['svc-kids-haircut']);
  });
}

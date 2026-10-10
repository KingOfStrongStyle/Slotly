import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slotly/app/theme.dart';
import 'package:slotly/data/local/app_database.dart';
import 'package:slotly/data/seed/demo_catalog.dart';
import 'package:slotly/features/analytics/data/analytics_repository.dart';
import 'package:slotly/features/analytics/presentation/owner_dashboard_screen.dart';
import 'package:slotly/features/auth/data/auth_repository.dart';
import 'package:slotly/features/auth/presentation/login_screen.dart';
import 'package:slotly/features/auth/presentation/session_controller.dart';
import 'package:slotly/features/booking/data/local_booking_repository.dart';
import 'package:slotly/features/booking/presentation/bookings_controller.dart';
import 'package:slotly/features/booking/presentation/bookings_screen.dart';
import 'package:slotly/features/business/data/business_repository.dart';
import 'package:slotly/features/business/data/photo_storage.dart';
import 'package:slotly/features/business/presentation/service_editor_screen.dart';
import 'package:slotly/features/catalog/data/catalog_repository.dart';
import 'package:slotly/features/catalog/presentation/catalog_controller.dart';
import 'package:slotly/features/catalog/presentation/catalog_screen.dart';
import 'package:slotly/features/catalog/presentation/widgets/organization_card.dart';
import 'package:slotly/features/catalog/presentation/widgets/service_card.dart';
import 'package:slotly/features/favorites/data/favorites_repository.dart';
import 'package:slotly/features/reviews/data/review_repository.dart';
import 'package:slotly/features/reviews/domain/rating_summary.dart';
import 'package:slotly/features/reviews/presentation/reviews_screen.dart';
import 'package:slotly/features/welcome/welcome_screen.dart';

import '../helpers/test_app.dart';

// Ян: эталоны обновлять только после просмотра картинок глазами:
// flutter test --update-goldens test/goldens
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

  Future<TestData> demo(String login) async {
    final data = await TestData.create(withActivity: true);
    data.signInAs(login);
    return data;
  }

  Future<CatalogController> catalogOf(TestData data) async {
    final controller = CatalogController(
      catalog: LocalCatalogRepository(data.context),
      reviews: LocalReviewRepository(data.context),
      favorites: LocalFavoritesRepository(data.context),
    );
    addTearDown(controller.dispose);
    await controller.load();
    return controller;
  }

  testWidgets('welcome screen', (tester) async {
    await pumpGolden(tester, WelcomeScreen(onShowServices: (_) {}));
    await expectLater(
      find.byType(WelcomeScreen),
      matchesGoldenFile('goldens/welcome_light.png'),
    );
  });

  testWidgets('sign-in screen', (tester) async {
    final database = await AppDatabase.inMemory();
    final session = SessionController(LocalAuthRepository(database));
    addTearDown(session.dispose);
    await pumpGolden(tester, LoginScreen(session: session));
    await expectLater(
      find.byType(LoginScreen),
      matchesGoldenFile('goldens/login_light.png'),
    );
  });

  testWidgets('service card with a price list', (tester) async {
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

  testWidgets('organization card in light and dark theme', (tester) async {
    final data = await demo('aliya');
    final reviews = await LocalReviewRepository(data.context)
        .fetchOrganizationReviews(orgNorth);
    final photos = await LocalCatalogRepository(data.context)
        .fetchPhotos(orgNorth);
    for (final (name, theme) in [
      ('light', AppTheme.light()),
      ('dark', AppTheme.dark()),
    ]) {
      await pumpGolden(
        tester,
        Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: OrganizationCard(
                organization: demoOrganizations.first,
                rating: RatingSummary.of(reviews),
                cover: photos.first,
                isFavorite: name == 'dark',
                onTap: () {},
                onToggleFavorite: () {},
              ),
            ),
          ),
        ),
        theme: theme,
        size: const Size(360, 330),
      );
      await expectLater(
        find.byType(OrganizationCard),
        matchesGoldenFile('goldens/organization_card_$name.png'),
      );
    }
  });

  testWidgets('customer catalog', (tester) async {
    final controller = await catalogOf(await demo('aliya'));
    await pumpGolden(
      tester,
      Scaffold(
        body: CatalogScreen(
          controller: controller,
          onOrganizationSelected: (_) {},
          onServiceSelected: (_) {},
        ),
      ),
    );
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/catalog_light.png'),
    );
  });

  testWidgets('catalog empty state', (tester) async {
    final controller = await catalogOf(await demo('aliya'));
    await pumpGolden(
      tester,
      Scaffold(
        body: CatalogScreen(
          controller: controller,
          onOrganizationSelected: (_) {},
          onServiceSelected: (_) {},
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'луна');
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/catalog_empty.png'),
    );
  });

  testWidgets('reviews with distribution', (tester) async {
    final data = await demo('aliya');
    await pumpGolden(
      tester,
      ReviewsScreen(
        organizationId: orgNorth,
        organizationName: 'Барбершоп «Северный»',
        reviews: LocalReviewRepository(data.context),
        currentUserId: data.user!.id,
      ),
    );
    await expectLater(
      find.byType(ReviewsScreen),
      matchesGoldenFile('goldens/reviews_light.png'),
    );
  });

  testWidgets('bookings empty state in dark theme', (tester) async {
    final data = await TestData.create();
    data.signInAs('aliya');
    final controller = BookingsController(LocalBookingRepository(data.context));
    addTearDown(controller.dispose);
    await controller.load();
    await pumpGolden(
      tester,
      Scaffold(
        body: BookingsScreen(
          bookings: controller,
          clock: () => testNow,
          reviewedBookingIds: const {},
          onBrowseServices: () {},
          onReschedule: (_) {},
          onWriteReview: (_) {},
        ),
      ),
      theme: AppTheme.dark(),
    );
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/bookings_empty_dark.png'),
    );
  });

  for (final (name, theme) in [
    ('light', AppTheme.light()),
    ('dark', AppTheme.dark()),
  ]) {
    testWidgets('owner dashboard ($name)', (tester) async {
      final data = await demo('north');
      await pumpGolden(
        tester,
        Scaffold(
          body: OwnerDashboardScreen(
            organizationId: orgNorth,
            organizationName: 'Барбершоп «Северный»',
            analytics: LocalAnalyticsRepository(data.context),
          ),
        ),
        theme: theme,
        size: const Size(360, 1400),
      );
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/owner_dashboard_$name.png'),
      );
    });
  }

  testWidgets('owner dashboard empty state', (tester) async {
    final data = await TestData.create();
    data.signInAs('north');
    await pumpGolden(
      tester,
      Scaffold(
        body: OwnerDashboardScreen(
          organizationId: orgNorth,
          organizationName: 'Барбершоп «Северный»',
          analytics: LocalAnalyticsRepository(data.context),
        ),
      ),
    );
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/owner_dashboard_empty.png'),
    );
  });

  testWidgets('service editor with a price list', (tester) async {
    final data = await demo('north');
    final service = data.database.tables.services['svc-men-haircut']!;
    await pumpGolden(
      tester,
      ServiceEditorScreen(
        organizationId: orgNorth,
        category: service.category,
        specialists: [
          for (final s in data.database.tables.specialists.values)
            if (s.organizationId == orgNorth) s,
        ],
        business: LocalBusinessRepository(data.context, MemoryPhotoStorage()),
        service: service,
      ),
      size: const Size(360, 1100),
    );
    await expectLater(
      find.byType(ServiceEditorScreen),
      matchesGoldenFile('goldens/service_editor_light.png'),
    );
  });
}

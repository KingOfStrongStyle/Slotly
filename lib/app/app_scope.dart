import 'package:flutter/widgets.dart';

import '../core/access/access_policy.dart';
import '../core/lifecycle/lifecycle_logger.dart';
import '../core/utils/clock.dart';
import '../data/local/app_database.dart';
import '../data/local/database_storage.dart';
import '../data/local/local_context.dart';
import '../data/seed/demo_seed.dart';
import '../features/analytics/data/analytics_repository.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/presentation/session_controller.dart';
import '../features/booking/data/local_booking_repository.dart';
import '../features/booking/domain/booking_repository.dart';
import '../features/business/data/business_repository.dart';
import '../features/business/data/photo_picker.dart';
import '../features/business/data/photo_storage.dart';
import '../features/catalog/data/catalog_repository.dart';
import '../features/favorites/data/favorites_repository.dart';
import '../features/gesture_checkin/data/symbol_templates.dart';
import '../features/gesture_checkin/domain/gesture_classifier.dart';
import '../features/reminders/data/reminder_service.dart';
import '../features/reminders/presentation/reminder_coordinator.dart';
import '../features/reviews/data/review_repository.dart';
import 'app_controller.dart';

/// Everything the screens need, created once at startup.
///
/// This is the only place that decides which implementations are used
/// (local database today, HTTP repositories later), so screens never
/// construct their own data sources.
class AppDependencies {
  AppDependencies._({
    required this.clock,
    required this.database,
    required this.policy,
    required this.session,
    required this.appController,
    required this.lifecycleLogger,
    required this.catalog,
    required this.bookings,
    required this.reviews,
    required this.favorites,
    required this.business,
    required this.analytics,
    required this.reminders,
    required this.photoPicker,
    required this.gestureClassifier,
  });

  /// Opens the database from [storage], fills it with demo data on the
  /// first launch, restores the previous session and syncs reminders.
  static Future<AppDependencies> create({
    required DatabaseStorage storage,
    required PhotoStorage photoStorage,
    required ReminderService reminderService,
    required PhotoPicker photoPicker,
    Clock clock = systemClock,
  }) async {
    final database = await AppDatabase.open(storage);
    await DemoSeed(clock: clock).apply(database);

    final session = SessionController(LocalAuthRepository(database));
    const policy = AccessPolicy();
    final context = LocalContext(
      database: database,
      currentUser: () => session.currentUser,
      clock: clock,
    );
    final bookings = LocalBookingRepository(context);
    final reminders = ReminderCoordinator(
      service: reminderService,
      bookings: bookings,
      session: session,
      database: database,
      clock: clock,
    );
    final dependencies = AppDependencies._(
      clock: clock,
      database: database,
      policy: policy,
      session: session,
      appController: AppController(database),
      lifecycleLogger: LifecycleLogger(clock: clock),
      catalog: LocalCatalogRepository(context),
      bookings: bookings,
      reviews: LocalReviewRepository(context),
      favorites: LocalFavoritesRepository(context),
      business: LocalBusinessRepository(context, photoStorage),
      analytics: LocalAnalyticsRepository(context),
      reminders: reminders,
      photoPicker: photoPicker,
      gestureClassifier: GestureClassifier(templates: symbolTemplates),
    );
    await session.restore();
    await reminders.start();
    return dependencies;
  }

  final Clock clock;
  final AppDatabase database;
  final AccessPolicy policy;
  final SessionController session;
  final AppController appController;
  final LifecycleLogger lifecycleLogger;
  final CatalogRepository catalog;
  final BookingRepository bookings;
  final ReviewRepository reviews;
  final FavoritesRepository favorites;
  final BusinessRepository business;
  final AnalyticsRepository analytics;
  final ReminderCoordinator reminders;
  final PhotoPicker photoPicker;
  final GestureClassifier gestureClassifier;

  void dispose() {
    reminders.dispose();
    session.dispose();
    appController.dispose();
    lifecycleLogger.dispose();
    database.dispose();
  }
}

/// Makes [AppDependencies] reachable from any route via [AppScope.of].
class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.dependencies, required super.child});

  final AppDependencies dependencies;

  static AppDependencies of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope is missing above this context.');
    return scope!.dependencies;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      dependencies != oldWidget.dependencies;
}

import 'package:flutter/widgets.dart';

import '../core/lifecycle/lifecycle_logger.dart';
import '../core/utils/clock.dart';
import '../features/catalog/data/demo_services.dart';
import '../features/catalog/domain/service.dart';
import 'app_controller.dart';

/// Everything the screens need, created once at startup.
///
/// This is the only place that decides which implementations are used
/// (demo data today, HTTP repositories later), so screens never construct
/// their own data sources.
class AppDependencies {
  AppDependencies({
    required this.clock,
    required this.appController,
    required this.services,
    required this.lifecycleLogger,
  });

  factory AppDependencies.demo({Clock clock = systemClock}) {
    return AppDependencies(
      clock: clock,
      appController: AppController(),
      services: demoServices,
      lifecycleLogger: LifecycleLogger(clock: clock),
    );
  }

  final Clock clock;
  final AppController appController;
  final List<Service> services;
  final LifecycleLogger lifecycleLogger;

  void dispose() {
    appController.dispose();
    lifecycleLogger.dispose();
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

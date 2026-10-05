import 'package:flutter/material.dart';

import '../features/catalog/domain/service.dart';
import '../features/diagnostics/presentation/diagnostics_screen.dart';
import 'app_scope.dart';
import 'home_shell.dart';

/// Route configuration of the app.
///
/// Screens without parameters are registered as named routes. Screens that
/// need data get a typed factory method, so the [Service] object is passed
/// straight into the screen constructor instead of an untyped argument.
abstract final class AppRoutes {
  static const homeName = '/home';
  static const diagnostics = '/diagnostics';

  static Map<String, WidgetBuilder> get named => {
    diagnostics: (context) =>
        DiagnosticsScreen(logger: AppScope.of(context).lifecycleLogger),
  };

  static Route<void> home({ServiceCategory? initialCategory}) {
    return MaterialPageRoute(
      settings: const RouteSettings(name: homeName),
      builder: (_) => HomeShell(initialCategory: initialCategory),
    );
  }
}

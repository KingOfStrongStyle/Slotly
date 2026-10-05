import 'package:flutter/material.dart';

import '../features/catalog/domain/service.dart';
import 'home_shell.dart';

/// Route configuration of the app.
///
/// Screens without parameters are registered as named routes. Screens that
/// need data get a typed factory method, so the [Service] object is passed
/// straight into the screen constructor instead of an untyped argument.
abstract final class AppRoutes {
  static const homeName = '/home';

  static Map<String, WidgetBuilder> get named => {};

  static Route<void> home({ServiceCategory? initialCategory}) {
    return MaterialPageRoute(
      settings: const RouteSettings(name: homeName),
      builder: (_) => HomeShell(initialCategory: initialCategory),
    );
  }
}

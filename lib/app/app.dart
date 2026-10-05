import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/app_strings.dart';
import '../features/welcome/welcome_screen.dart';
import 'app_scope.dart';
import 'routes.dart';
import 'theme.dart';

/// Root widget. Owns [AppDependencies]: creates them once and disposes them
/// together with the app.
class SlotlyApp extends StatefulWidget {
  const SlotlyApp({super.key, this.createDependencies = AppDependencies.demo});

  /// Tests pass their own factory to freeze the clock or seed data.
  final AppDependencies Function() createDependencies;

  @override
  State<SlotlyApp> createState() => _SlotlyAppState();
}

class _SlotlyAppState extends State<SlotlyApp> {
  late final AppDependencies _dependencies = widget.createDependencies();

  @override
  void dispose() {
    _dependencies.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appController = _dependencies.appController;
    return AppScope(
      dependencies: _dependencies,
      child: ListenableBuilder(
        listenable: appController,
        builder: (context, _) => MaterialApp(
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: appController.themeMode,
          locale: const Locale('ru'),
          supportedLocales: const [Locale('ru')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          routes: AppRoutes.named,
          home: Builder(
            builder: (context) => WelcomeScreen(
              onShowServices: (category) => Navigator.of(context)
                  .pushReplacement(AppRoutes.home(initialCategory: category)),
            ),
          ),
        ),
      ),
    );
  }
}

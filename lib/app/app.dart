import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/app_strings.dart';
import 'app_controller.dart';
import 'theme.dart';

class SlotlyApp extends StatefulWidget {
  const SlotlyApp({super.key});

  @override
  State<SlotlyApp> createState() => _SlotlyAppState();
}

class _SlotlyAppState extends State<SlotlyApp> {
  final _appController = AppController();

  @override
  void dispose() {
    _appController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _appController,
      builder: (context, _) => MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: _appController.themeMode,
        locale: const Locale('ru'),
        supportedLocales: const [Locale('ru')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const Scaffold(body: Center(child: Text(AppStrings.appName))),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/app_strings.dart';
import '../features/auth/domain/app_user.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/welcome/welcome_screen.dart';
import 'app_scope.dart';
import 'client_shell.dart';
import 'owner_shell.dart';
import 'routes.dart';
import 'theme.dart';

/// Root widget. Shows the welcome and sign-in screens to a guest, the
/// customer shell to a client and the owner shell to a business owner.
///
/// Every sign-in and sign-out creates a new [Navigator] (new key), so no
/// screen of the previous session stays in the back stack: after sign-out
/// the Back button cannot return to the owner dashboard.
class SlotlyApp extends StatefulWidget {
  const SlotlyApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<SlotlyApp> createState() => _SlotlyAppState();
}

class _SlotlyAppState extends State<SlotlyApp> {
  AppDependencies get _dependencies => widget.dependencies;
  String? _sessionUserId;
  var _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _sessionUserId = _dependencies.session.currentUser?.id;
    _dependencies.session.addListener(_onSessionChanged);
  }

  @override
  void dispose() {
    _dependencies.session.removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    final userId = _dependencies.session.currentUser?.id;
    if (userId == _sessionUserId) return;
    setState(() {
      _sessionUserId = userId;
      _navigatorKey = GlobalKey<NavigatorState>();
      _dependencies.appController.resetTabs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appController = _dependencies.appController;
    return AppScope(
      dependencies: _dependencies,
      child: ListenableBuilder(
        listenable: appController,
        builder: (context, _) => MaterialApp(
          key: ValueKey(_sessionUserId),
          navigatorKey: _navigatorKey,
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: appController.themeMode,
          locale: const Locale('ru'),
          supportedLocales: const [Locale('ru')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          routes: AppRoutes.named,
          home: _home(_dependencies.session.currentUser),
        ),
      ),
    );
  }

  Widget _home(AppUser? user) {
    if (user == null) {
      return Builder(
        builder: (context) => WelcomeScreen(
          onShowServices: (category) {
            _dependencies.appController.setInitialCategory(category);
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                settings: const RouteSettings(name: AppRoutes.signIn),
                builder: (_) => LoginScreen(session: _dependencies.session),
              ),
            );
          },
        ),
      );
    }
    return user.isOwner
        ? OwnerShell(user: user)
        : ClientShell(
            user: user,
            initialCategory: _dependencies.appController.initialCategory,
          );
  }
}

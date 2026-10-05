import 'package:flutter/material.dart';

enum HomeTab { services, bookings, profile }

/// App-wide UI settings and the selected bottom navigation tab.
///
/// Settings live only in memory: persistence is out of the MVP scope.
class AppController extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  bool _demoNotificationsEnabled = true;
  HomeTab _currentTab = HomeTab.services;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get demoNotificationsEnabled => _demoNotificationsEnabled;
  HomeTab get currentTab => _currentTab;

  void setDarkMode(bool enabled) {
    final mode = enabled ? ThemeMode.dark : ThemeMode.light;
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
  }

  void setDemoNotifications(bool enabled) {
    if (enabled == _demoNotificationsEnabled) return;
    _demoNotificationsEnabled = enabled;
    notifyListeners();
  }

  void selectTab(HomeTab tab) {
    if (tab == _currentTab) return;
    _currentTab = tab;
    notifyListeners();
  }
}

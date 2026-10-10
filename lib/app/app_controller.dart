import 'package:flutter/material.dart';

import '../data/local/app_database.dart';
import '../features/catalog/domain/service.dart';

enum ClientTab { catalog, favorites, bookings, profile }

enum OwnerTab { dashboard, bookings, services, reviews, organization }

/// Device settings (theme) and the selected tab of each shell.
///
/// The theme is saved in the local database, so it survives a restart;
/// tabs are UI state and start from the first tab after sign-in.
class AppController extends ChangeNotifier {
  AppController(this._database);

  final AppDatabase _database;
  ClientTab _clientTab = ClientTab.catalog;
  OwnerTab _ownerTab = OwnerTab.dashboard;
  ServiceCategory? _initialCategory;

  ThemeMode get themeMode => isDarkMode ? ThemeMode.dark : ThemeMode.light;
  bool get isDarkMode => _database.tables.settings.darkTheme;
  ClientTab get clientTab => _clientTab;
  OwnerTab get ownerTab => _ownerTab;

  /// Category chosen on the welcome screen, applied once to the catalog.
  ServiceCategory? get initialCategory => _initialCategory;

  Future<void> setDarkMode(bool enabled) async {
    if (enabled == isDarkMode) return;
    await _database.update((t) => t.settings.darkTheme = enabled);
    notifyListeners();
  }

  void selectClientTab(ClientTab tab) {
    if (tab == _clientTab) return;
    _clientTab = tab;
    notifyListeners();
  }

  void selectOwnerTab(OwnerTab tab) {
    if (tab == _ownerTab) return;
    _ownerTab = tab;
    notifyListeners();
  }

  void setInitialCategory(ServiceCategory? category) {
    _initialCategory = category;
  }

  /// Called on sign-in and sign-out: every session starts from the first
  /// tab.
  void resetTabs() {
    _clientTab = ClientTab.catalog;
    _ownerTab = OwnerTab.dashboard;
  }
}

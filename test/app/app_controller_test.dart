import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slotly/app/app_controller.dart';
import 'package:slotly/data/local/app_database.dart';
import 'package:slotly/data/local/database_storage.dart';
import 'package:slotly/features/catalog/domain/service.dart';

void main() {
  late MemoryDatabaseStorage storage;
  late AppController controller;
  late int notifications;

  setUp(() async {
    storage = MemoryDatabaseStorage();
    controller = AppController(await AppDatabase.open(storage));
    notifications = 0;
    controller.addListener(() => notifications++);
  });

  tearDown(() => controller.dispose());

  test('starts with light theme and the first tabs', () {
    expect(controller.themeMode, ThemeMode.light);
    expect(controller.clientTab, ClientTab.catalog);
    expect(controller.ownerTab, OwnerTab.dashboard);
  });

  test('theme is saved and notifies only on real changes', () async {
    await controller.setDarkMode(true);
    await controller.setDarkMode(true);
    expect(controller.isDarkMode, isTrue);
    expect(notifications, 1);

    final restored = AppController(await AppDatabase.open(storage));
    expect(restored.themeMode, ThemeMode.dark);
  });

  test('tabs are selected and reset for a new session', () {
    controller
      ..selectClientTab(ClientTab.bookings)
      ..selectOwnerTab(OwnerTab.reviews)
      ..selectClientTab(ClientTab.bookings);
    expect(notifications, 2);

    controller.resetTabs();
    expect(controller.clientTab, ClientTab.catalog);
    expect(controller.ownerTab, OwnerTab.dashboard);
  });

  test('keeps the category chosen on the welcome screen', () {
    controller.setInitialCategory(ServiceCategory.dentistry);
    expect(controller.initialCategory, ServiceCategory.dentistry);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slotly/app/app_controller.dart';

void main() {
  late AppController controller;
  late int notifications;

  setUp(() {
    controller = AppController();
    notifications = 0;
    controller.addListener(() => notifications++);
  });

  tearDown(() => controller.dispose());

  test('starts with light theme, catalog tab and notifications on', () {
    expect(controller.themeMode, ThemeMode.light);
    expect(controller.currentTab, HomeTab.services);
    expect(controller.demoNotificationsEnabled, isTrue);
  });

  test('switches theme and notifies only on real changes', () {
    controller.setDarkMode(true);
    controller.setDarkMode(true);
    expect(controller.isDarkMode, isTrue);
    expect(notifications, 1);
  });

  test('selects tabs and toggles demo notifications', () {
    controller.selectTab(HomeTab.bookings);
    controller.setDemoNotifications(false);
    expect(controller.currentTab, HomeTab.bookings);
    expect(controller.demoNotificationsEnabled, isFalse);
    expect(notifications, 2);
  });
}

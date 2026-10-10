import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../domain/reminder_planner.dart';
import 'reminder_service.dart';

class LocalReminderService implements ReminderService {
  LocalReminderService._(this._plugin);

  static const _channelId = 'booking_reminders';
  static const _channelName = 'Напоминания о записях';
  static const _channelDescription =
      'Накануне, утром в день визита и за час до начала';

  final FlutterLocalNotificationsPlugin _plugin;
  final _opened = StreamController<String>.broadcast();
  String? _launchBookingId;

  static Future<ReminderService> create() async {
    try {
      tz_data.initializeTimeZones();
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));

      final service = LocalReminderService._(FlutterLocalNotificationsPlugin());
      await service._plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload != null) service._opened.add(payload);
        },
      );
      final launch = await service._plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        service._launchBookingId = launch?.notificationResponse?.payload;
      }
      return service;
    } on Object catch (error) {
      debugPrint('Local reminders are unavailable: $error');
      return InMemoryReminderService(
        currentPermission: ReminderPermission.denied,
        grantOnRequest: false,
      );
    }
  }

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  Future<ReminderPermission> permission() async {
    final enabled = await _android?.areNotificationsEnabled();
    return switch (enabled) {
      true => ReminderPermission.granted,
      false => ReminderPermission.denied,
      null => ReminderPermission.unknown,
    };
  }

  @override
  Future<ReminderPermission> requestPermission() async {
    final granted = await _android?.requestNotificationsPermission();
    return switch (granted) {
      true => ReminderPermission.granted,
      false => ReminderPermission.denied,
      null => ReminderPermission.unknown,
    };
  }

  @override
  Future<void> schedule(List<PlannedReminder> reminders) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
      ),
    );
    for (final reminder in reminders) {
      await _plugin.zonedSchedule(
        id: reminder.id,
        scheduledDate: tz.TZDateTime.from(reminder.fireAt, tz.local),
        notificationDetails: details,
        // Кирилл: inexact специально: для точных нужно отдельное разрешение на будильники.
        // Android может сдвинуть показ до часа, это описано в docs/notifications.html
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: reminder.title,
        body: reminder.body,
        payload: reminder.bookingId,
      );
    }
  }

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  @override
  Future<List<int>> pendingIds() async => [
    for (final request in await _plugin.pendingNotificationRequests())
      request.id,
  ];

  @override
  Stream<String> get openedBookingIds => _opened.stream;

  @override
  Future<String?> takeLaunchBookingId() async {
    final id = _launchBookingId;
    _launchBookingId = null;
    return id;
  }
}

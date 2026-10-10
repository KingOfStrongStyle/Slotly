import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../domain/reminder_planner.dart';
import 'reminder_service.dart';

/// Android implementation on top of `flutter_local_notifications`.
///
/// * Times are converted with the device time zone (`flutter_timezone`),
///   so a reminder at 18:00 fires at 18:00 local time even across a
///   daylight-saving change.
/// * `inexactAllowWhileIdle`: Android may deliver a few minutes late, but
///   no "exact alarm" permission is needed — fine for an appointment
///   reminder.
/// * The booking id travels in the payload; a tap opens that booking.
class LocalReminderService implements ReminderService {
  LocalReminderService._(this._plugin);

  static const _channelId = 'booking_reminders';
  static const _channelName = 'Напоминания о записях';
  static const _channelDescription =
      'Накануне, утром в день визита и за час до начала';

  final FlutterLocalNotificationsPlugin _plugin;
  final _opened = StreamController<String>.broadcast();
  String? _launchBookingId;

  /// Initialises the plugin and time zones. Falls back to
  /// [InMemoryReminderService] if the platform part is unavailable, so the
  /// app still starts (for example in a desktop build).
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

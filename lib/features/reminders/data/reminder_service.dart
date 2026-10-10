import 'dart:async';

import '../domain/reminder_planner.dart';

enum ReminderPermission { granted, denied, unknown }

/// Local reminders on this device. These are not push notifications: they
/// are scheduled by the app itself and are not sent by a server.
abstract interface class ReminderService {
  Future<ReminderPermission> permission();

  /// Shows the Android 13+ system dialog when it is still allowed.
  Future<ReminderPermission> requestPermission();

  /// Schedules [reminders], replacing reminders with the same ids.
  Future<void> schedule(List<PlannedReminder> reminders);

  Future<void> cancelAll();

  /// Ids of reminders currently scheduled in the system.
  Future<List<int>> pendingIds();

  /// Booking ids from reminders the user tapped while the app was running.
  Stream<String> get openedBookingIds;

  /// Booking id of the reminder that launched the app, if any. Returns it
  /// only once.
  Future<String?> takeLaunchBookingId();
}

/// Keeps reminders in memory. Used by tests and as a safe fallback when the
/// platform plugin cannot be initialised.
class InMemoryReminderService implements ReminderService {
  InMemoryReminderService({
    this.currentPermission = ReminderPermission.granted,
    this.grantOnRequest = true,
  });

  ReminderPermission currentPermission;
  final bool grantOnRequest;
  final Map<int, PlannedReminder> scheduled = {};
  final _opened = StreamController<String>.broadcast();
  String? launchBookingId;
  int requestCount = 0;

  /// Simulates a tap on a delivered reminder.
  void tap(String bookingId) => _opened.add(bookingId);

  @override
  Future<ReminderPermission> permission() async => currentPermission;

  @override
  Future<ReminderPermission> requestPermission() async {
    requestCount++;
    if (grantOnRequest) currentPermission = ReminderPermission.granted;
    if (!grantOnRequest) currentPermission = ReminderPermission.denied;
    return currentPermission;
  }

  @override
  Future<void> schedule(List<PlannedReminder> reminders) async {
    for (final reminder in reminders) {
      scheduled[reminder.id] = reminder;
    }
  }

  @override
  Future<void> cancelAll() async => scheduled.clear();

  @override
  Future<List<int>> pendingIds() async => scheduled.keys.toList();

  @override
  Stream<String> get openedBookingIds => _opened.stream;

  @override
  Future<String?> takeLaunchBookingId() async {
    final id = launchBookingId;
    launchBookingId = null;
    return id;
  }
}

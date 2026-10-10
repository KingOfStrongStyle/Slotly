import 'dart:async';

import '../domain/reminder_planner.dart';

enum ReminderPermission { granted, denied, unknown }

abstract interface class ReminderService {
  Future<ReminderPermission> permission();

  Future<ReminderPermission> requestPermission();

  Future<void> schedule(List<PlannedReminder> reminders);

  Future<void> cancelAll();

  Future<List<int>> pendingIds();

  Stream<String> get openedBookingIds;

  Future<String?> takeLaunchBookingId();
}

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

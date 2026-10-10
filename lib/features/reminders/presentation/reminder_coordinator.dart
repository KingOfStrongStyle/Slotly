import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/app_strings.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/local/app_database.dart';
import '../../auth/presentation/session_controller.dart';
import '../../booking/domain/booking.dart';
import '../../booking/domain/booking_repository.dart';
import '../data/reminder_service.dart';
import '../domain/reminder_planner.dart';

/// Keeps the reminders scheduled on the device in sync with the bookings
/// of the signed-in customer.
///
/// After every change of bookings (created, moved, cancelled, checked in),
/// every sign-in and sign-out, and every change of the setting, it cancels
/// all reminders and schedules the current plan again. A customer has a
/// handful of upcoming bookings, so the full resync is cheap and leaves no
/// orphaned or duplicated reminders.
class ReminderCoordinator extends ChangeNotifier {
  ReminderCoordinator({
    required this._service,
    required this._bookings,
    required this._session,
    required this._database,
    required this._clock,
    ReminderPlanner? planner,
  }) : _planner = planner ?? ReminderPlanner(texts: defaultTexts);

  static final ReminderTexts defaultTexts = (
    title: (b) => AppStrings.reminderTitle(b.serviceTitle),
    dayBefore: (b) => AppStrings.reminderDayBefore(
      b.organizationName,
      Formatters.time(b.startAt),
    ),
    morning: (b) => AppStrings.reminderMorning(
      b.organizationName,
      Formatters.time(b.startAt),
    ),
    hourBefore: (b) => AppStrings.reminderHourBefore(
      b.organizationName,
      Formatters.time(b.startAt),
    ),
  );

  final ReminderService _service;
  final BookingRepository _bookings;
  final SessionController _session;
  final AppDatabase _database;
  final Clock _clock;
  final ReminderPlanner _planner;
  Future<void> _queue = Future.value();
  List<PlannedReminder> _planned = const [];
  ReminderPermission _permission = ReminderPermission.unknown;
  bool _started = false;

  ReminderService get service => _service;
  List<PlannedReminder> get planned => _planned;
  ReminderPermission get permission => _permission;
  bool get isEnabled => _database.tables.settings.remindersEnabled;

  /// Subscribes to changes and performs the first sync.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    _session.addListener(_scheduleSync);
    _bookings.changes.addListener(_scheduleSync);
    await refreshPermission();
    await sync();
  }

  Future<void> refreshPermission() async {
    _permission = await _service.permission();
    notifyListeners();
  }

  Future<ReminderPermission> requestPermission() async {
    _permission = await _service.requestPermission();
    notifyListeners();
    return _permission;
  }

  Future<void> setEnabled(bool enabled) async {
    await _database.update((t) => t.settings.remindersEnabled = enabled);
    notifyListeners();
    await sync();
  }

  void _scheduleSync() => unawaited(sync());

  /// Recomputes and reschedules all reminders. Calls are queued, so two
  /// quick changes never interleave.
  Future<void> sync() => _queue = _queue.then((_) => _sync());

  Future<void> _sync() async {
    final user = _session.currentUser;
    List<Booking> bookings = const [];
    if (user != null && user.isClient && isEnabled) {
      try {
        bookings = await _bookings.fetchBookings();
      } on Exception {
        bookings = const [];
      }
    }
    final planned = _planner.planAll(bookings, _clock());
    await _service.cancelAll();
    if (planned.isNotEmpty) await _service.schedule(planned);
    _planned = planned;
    notifyListeners();
  }

  @override
  void dispose() {
    _session.removeListener(_scheduleSync);
    _bookings.changes.removeListener(_scheduleSync);
    super.dispose();
  }
}

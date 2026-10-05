import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../utils/clock.dart';
import 'lifecycle_event.dart';

/// Records application lifecycle transitions into an in-memory journal.
///
/// Created once at app startup (see `AppDependencies`) so that events are
/// captured even before the diagnostics screen is opened. The journal is not
/// persisted: after the process is killed it starts again from #1. Transitions
/// right before termination can be watched with `adb logcat -s flutter`.
class LifecycleLogger extends ChangeNotifier {
  LifecycleLogger({this.clock = systemClock}) {
    final initialState = WidgetsBinding.instance.lifecycleState;
    if (initialState != null) _record(initialState, isInitial: true);
    _listener = AppLifecycleListener(onStateChange: _record);
  }

  final Clock clock;
  late final AppLifecycleListener _listener;
  final List<LifecycleEvent> _events = [];
  AppLifecycleState? _currentState;

  /// Journal in chronological order.
  List<LifecycleEvent> get events => List.unmodifiable(_events);

  AppLifecycleState? get currentState => _currentState;

  void clear() {
    if (_events.isEmpty) return;
    _events.clear();
    notifyListeners();
  }

  void _record(AppLifecycleState state, {bool isInitial = false}) {
    _currentState = state;
    final event = LifecycleEvent(
      sequenceNumber: _events.length + 1,
      state: state,
      occurredAt: clock(),
      isInitial: isInitial,
    );
    _events.add(event);
    if (kDebugMode) {
      debugPrint('[Slotly lifecycle] #${event.sequenceNumber} ${state.name}');
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }
}

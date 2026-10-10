import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:slotly/core/app_strings.dart';
import 'package:slotly/core/lifecycle/lifecycle_logger.dart';

import '../../helpers/lifecycle.dart';

void main() {
  final fixedTime = DateTime(2026, 10, 5, 10, 30);

  testWidgets('records the initial state as event #1', (tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final logger = LifecycleLogger(clock: () => fixedTime);
    addTearDown(logger.dispose);

    expect(logger.currentState, AppLifecycleState.resumed);
    final first = logger.events.single;
    expect(first.sequenceNumber, 1);
    expect(first.isInitial, isTrue);
    expect(first.occurredAt, fixedTime);
    expect(
      first.readableDescription,
      startsWith(AppStrings.lifecycleLaunchPrefix),
    );
  });

  testWidgets('numbers events sequentially including generated states', (
    tester,
  ) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final logger = LifecycleLogger(clock: () => fixedTime);
    addTearDown(logger.dispose);

    await sendPlatformLifecycle(tester, AppLifecycleState.paused);
    await sendPlatformLifecycle(tester, AppLifecycleState.resumed);

    expect(logger.events.map((e) => e.state), [
      AppLifecycleState.resumed,
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]);
    expect(logger.events.map((e) => e.sequenceNumber), [1, 2, 3, 4, 5, 6, 7]);
    expect(logger.currentState, AppLifecycleState.resumed);
  });

  testWidgets('clear empties the journal and restarts numbering', (
    tester,
  ) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final logger = LifecycleLogger(clock: () => fixedTime);
    addTearDown(logger.dispose);
    var notifications = 0;
    logger.addListener(() => notifications++);

    logger.clear();
    expect(logger.events, isEmpty);
    expect(logger.currentState, AppLifecycleState.resumed);
    expect(notifications, 1);

    await sendPlatformLifecycle(tester, AppLifecycleState.inactive);
    expect(logger.events.single.sequenceNumber, 1);
    expect(logger.events.single.isInitial, isFalse);
  });

  testWidgets('dispose releases the AppLifecycleListener', (tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final logger = LifecycleLogger(clock: () => fixedTime);
    final eventsBefore = logger.events.length;

    logger.dispose();
    await sendPlatformLifecycle(tester, AppLifecycleState.paused);

    expect(tester.takeException(), isNull);
    expect(logger.events.length, eventsBefore);
  });
}

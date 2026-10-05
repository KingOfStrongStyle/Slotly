import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:slotly/core/app_strings.dart';
import 'package:slotly/core/lifecycle/lifecycle_event.dart';

void main() {
  test('every lifecycle state has a distinct title and description', () {
    final titles = AppLifecycleState.values.map(lifecycleStateTitle).toSet();
    final descriptions = AppLifecycleState.values
        .map(describeLifecycleState)
        .toSet();

    expect(titles, hasLength(AppLifecycleState.values.length));
    expect(descriptions, hasLength(AppLifecycleState.values.length));
    expect(titles.every((t) => t.isNotEmpty), isTrue);
  });

  test('hidden is explained as an intermediate state on Android', () {
    expect(
      describeLifecycleState(AppLifecycleState.hidden),
      contains('промежуточное'),
    );
  });

  test('initial event is marked in the readable description', () {
    final time = DateTime(2026, 10, 5, 12);
    const state = AppLifecycleState.detached;
    final regular = LifecycleEvent(
      sequenceNumber: 3,
      state: state,
      occurredAt: time,
    );
    final initial = LifecycleEvent(
      sequenceNumber: 1,
      state: state,
      occurredAt: time,
      isInitial: true,
    );

    expect(regular.readableDescription, describeLifecycleState(state));
    expect(
      initial.readableDescription,
      '${AppStrings.lifecycleLaunchPrefix}${describeLifecycleState(state)}',
    );
  });
}

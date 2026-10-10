import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slotly/core/app_strings.dart';
import 'package:slotly/features/reminders/data/reminder_service.dart';
import 'package:slotly/features/reminders/presentation/reminders_screen.dart';

import '../../helpers/test_app.dart';

void main() {
  Future<InMemoryReminderService> pumpReminders(
    WidgetTester tester, {
    ReminderPermission permission = ReminderPermission.granted,
    bool grantOnRequest = true,
  }) async {
    final service = InMemoryReminderService(
      currentPermission: permission,
      grantOnRequest: grantOnRequest,
    );
    final deps = await createTestDependencies(reminders: service);
    addTearDown(deps.dispose);
    await signIn(deps, 'damir');
    await deps.reminders.sync();
    await pumpScreen(
      tester,
      RemindersScreen(coordinator: deps.reminders),
      dependencies: deps,
    );
    return service;
  }

  testWidgets('lists planned reminders and the system count', (tester) async {
    final service = await pumpReminders(tester);
    expect(find.text(AppStrings.remindersPermissionGranted), findsOneWidget);
    expect(find.text(AppStrings.remindersRequestPermission), findsNothing);
    expect(find.byIcon(Icons.alarm), findsWidgets);
    expect(
      find.text(AppStrings.remindersPendingInSystem(service.scheduled.length)),
      findsOneWidget,
    );
    expect(find.text(AppStrings.remindersLocalNote), findsOneWidget);
  });

  testWidgets('denied permission explains and offers a request', (
    tester,
  ) async {
    final service = await pumpReminders(
      tester,
      permission: ReminderPermission.denied,
      grantOnRequest: true,
    );
    expect(find.text(AppStrings.remindersPermissionDenied), findsOneWidget);

    await tester.tap(find.text(AppStrings.remindersRequestPermission));
    await tester.pumpAndSettle();
    expect(service.requestCount, 1);
    expect(find.text(AppStrings.remindersPermissionGranted), findsOneWidget);
  });

  testWidgets('switching reminders off clears the plan', (tester) async {
    final service = await pumpReminders(tester);
    await tester.tap(find.text(AppStrings.remindersEnabled));
    await tester.pumpAndSettle();
    expect(service.scheduled, isEmpty);
    expect(find.text(AppStrings.remindersPlannedEmpty), findsOneWidget);
  });
}

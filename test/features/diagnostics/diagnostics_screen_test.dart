import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slotly/core/app_strings.dart';
import 'package:slotly/core/lifecycle/lifecycle_logger.dart';
import 'package:slotly/features/diagnostics/presentation/diagnostics_screen.dart';

import '../../helpers/lifecycle.dart';
import '../../helpers/test_app.dart';

void main() {
  testWidgets('shows current state, journal and clears it', (tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final logger = LifecycleLogger(
      clock: () => DateTime(2026, 10, 5, 10, 0, 5),
    );
    addTearDown(logger.dispose);

    await pumpScreen(tester, DiagnosticsScreen(logger: logger));

    expect(
      find.text('resumed · ${AppStrings.lifecycleResumedTitle}'),
      findsWidgets,
    );
    expect(find.text('#1'), findsOneWidget);
    expect(find.text('10:00:05'), findsOneWidget);

    await sendPlatformLifecycle(tester, AppLifecycleState.inactive);
    await tester.pump();
    expect(find.text('#2'), findsOneWidget);
    expect(
      find.text('inactive · ${AppStrings.lifecycleInactiveTitle}'),
      findsWidgets,
    );

    await tester.tap(find.byTooltip(AppStrings.diagnosticsClear));
    await tester.pump();

    expect(find.text(AppStrings.diagnosticsEmptyTitle), findsOneWidget);
    expect(find.text(AppStrings.diagnosticsCleared), findsOneWidget);
    expect(find.text('#1'), findsNothing);
  });
}

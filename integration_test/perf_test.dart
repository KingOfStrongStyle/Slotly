import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:slotly/app/app.dart';
import 'package:slotly/app/app_scope.dart';
import 'package:slotly/core/app_strings.dart';
import 'package:slotly/data/local/database_storage.dart';
import 'package:slotly/features/business/data/photo_storage.dart';
import 'package:slotly/features/reminders/data/reminder_service.dart';

import '../test/helpers/test_app.dart' show FakePhotoPicker;

/// Frame timings of the heaviest scrolling scenarios, collected from the
/// engine's [FrameTiming] reports. Build time measures the app's Dart code;
/// raster time on an emulator mostly measures its software GPU, so the two
/// are reported separately. Run with `flutter drive --profile` (see
/// test_driver/perf_driver.dart).
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final report = <String, Object?>{};

  Future<void> measure(String key, Future<void> Function() action) async {
    final timings = <FrameTiming>[];
    void collect(List<FrameTiming> batch) => timings.addAll(batch);
    SchedulerBinding.instance.addTimingsCallback(collect);
    await action();
    // Timings arrive in batches; wait for the last one.
    await Future<void>.delayed(const Duration(seconds: 1));
    SchedulerBinding.instance.removeTimingsCallback(collect);
    report[key] = _summarize(timings);
  }

  testWidgets('scrolling catalog, organization and dashboard', (tester) async {
    final deps = await AppDependencies.create(
      storage: MemoryDatabaseStorage(),
      photoStorage: MemoryPhotoStorage(),
      reminderService: InMemoryReminderService(),
      photoPicker: FakePhotoPicker(),
    );
    await deps.session.signIn('aliya', 'aliya-demo');
    await tester.pumpWidget(SlotlyApp(dependencies: deps));
    await tester.pumpAndSettle();

    // Warm-up pass, not measured: first-time costs (glyph loading, first
    // layout of each card) are reported separately from steady scrolling.
    await measure('catalog_first_pass', () async {
      final list = find.byType(Scrollable).first;
      await tester.fling(list, const Offset(0, -800), 2000);
      await tester.pumpAndSettle();
      await tester.fling(list, const Offset(0, 800), 2000);
      await tester.pumpAndSettle();
    });
    await measure('catalog_scrolling', () async {
      final list = find.byType(Scrollable).first;
      for (var i = 0; i < 3; i++) {
        await tester.fling(list, const Offset(0, -800), 2000);
        await tester.pumpAndSettle();
        await tester.fling(list, const Offset(0, 800), 2000);
        await tester.pumpAndSettle();
      }
    });

    await tester.tap(find.text('Барбершоп «Северный»'));
    await tester.pump(kDoubleTapTimeout);
    await tester.pumpAndSettle();
    await measure('organization_gallery_and_scroll', () async {
      for (var i = 0; i < 3; i++) {
        await tester.fling(
          find.byType(PageView).first,
          const Offset(-300, 0),
          1500,
        );
        await tester.pumpAndSettle();
      }
      final page = find.byType(Scrollable).first;
      for (var i = 0; i < 3; i++) {
        await tester.fling(page, const Offset(0, -900), 2000);
        await tester.pumpAndSettle();
      }
    });

    await deps.session.signOut();
    await tester.pumpAndSettle();
    await deps.session.signIn('north', 'north-demo');
    await tester.pumpAndSettle();
    await measure('dashboard_filters_and_scroll', () async {
      for (final days in [90, 7, 30]) {
        await tester.tap(find.text(AppStrings.periodDays(days)));
        await tester.pumpAndSettle();
      }
      final dashboard = find.byType(Scrollable).first;
      for (var i = 0; i < 2; i++) {
        await tester.fling(dashboard, const Offset(0, -1200), 2000);
        await tester.pumpAndSettle();
        await tester.fling(dashboard, const Offset(0, 1200), 2000);
        await tester.pumpAndSettle();
      }
    });

    binding.reportData = report;
    await deps.session.signOut();
  });
}

Map<String, Object> _summarize(List<FrameTiming> timings) {
  double ms(Duration d) => d.inMicroseconds / 1000;
  List<double> sorted(Iterable<double> values) => values.toList()..sort();
  double percentile(List<double> values, double p) =>
      values.isEmpty ? 0 : values[((values.length - 1) * p).round()];
  double average(List<double> values) =>
      values.isEmpty ? 0 : values.reduce((a, b) => a + b) / values.length;
  final build = sorted(timings.map((t) => ms(t.buildDuration)));
  final raster = sorted(timings.map((t) => ms(t.rasterDuration)));
  const budget = 1000 / 60;
  return {
    'frames': timings.length,
    'build_avg_ms': average(build),
    'build_p90_ms': percentile(build, 0.9),
    'build_p99_ms': percentile(build, 0.99),
    'build_worst_ms': build.isEmpty ? 0 : build.last,
    'build_over_16ms': build.where((v) => v > budget).length,
    'raster_avg_ms': average(raster),
    'raster_p90_ms': percentile(raster, 0.9),
    'raster_over_16ms': raster.where((v) => v > budget).length,
  };
}

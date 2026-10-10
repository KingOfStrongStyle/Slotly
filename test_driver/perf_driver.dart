import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

/// Saves frame timing summaries reported by `integration_test/perf_test.dart`
/// to build/perf/. Run with:
///   flutter drive --profile -d emulator-5554 \
///     --driver=test_driver/perf_driver.dart \
///     --target=integration_test/perf_test.dart
Future<void> main() => integrationDriver(
  responseDataCallback: (data) async {
    if (data == null) return;
    final directory = Directory('build/perf')..createSync(recursive: true);
    File('${directory.path}/frame_summary.json')
        .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(data));
  },
);

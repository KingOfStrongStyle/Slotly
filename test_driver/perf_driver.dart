import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver(
  responseDataCallback: (data) async {
    if (data == null) return;
    final directory = Directory('build/perf')..createSync(recursive: true);
    File('${directory.path}/frame_summary.json')
        .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(data));
  },
);

// Prints line coverage from coverage/lcov.info grouped by layer.
//
// Usage:
//   flutter test --coverage
//   dart run tool/coverage_summary.dart
import 'dart:io';

void main(List<String> args) {
  final file = File(args.isEmpty ? 'coverage/lcov.info' : args.first);
  if (!file.existsSync()) {
    stderr.writeln('${file.path} not found. Run `flutter test --coverage`.');
    exitCode = 1;
    return;
  }

  final files = <String, ({int found, int hit})>{};
  String? current;
  var found = 0;
  var hit = 0;
  for (final line in file.readAsLinesSync()) {
    if (line.startsWith('SF:')) {
      current = line.substring(3);
      found = 0;
      hit = 0;
    } else if (line.startsWith('DA:')) {
      found++;
      if (!line.endsWith(',0')) hit++;
    } else if (line == 'end_of_record' && current != null) {
      files[current] = (found: found, hit: hit);
    }
  }

  final groups = <String, bool Function(String)>{
    'domain + data (lib/data, features/*/domain, features/*/data)': (p) =>
        p.contains('/domain/') || p.contains('/data/'),
    'core (lifecycle, utils, widgets, strings)': (p) =>
        p.startsWith('lib/core/'),
    'app (shell, routes, theme, controller)': (p) => p.startsWith('lib/app/'),
    'presentation (features/*/presentation, welcome)': (p) =>
        p.contains('/presentation/') || p.contains('/welcome/'),
    'all lib/': (p) => true,
  };

  stdout.writeln('Line coverage by layer');
  for (final entry in groups.entries) {
    final matching = files.entries.where((e) => entry.value(e.key));
    final total = matching.fold(0, (sum, e) => sum + e.value.found);
    final covered = matching.fold(0, (sum, e) => sum + e.value.hit);
    stdout.writeln(
      '  ${entry.key}: ${_percent(covered, total)} ($covered/$total lines)',
    );
  }

  stdout.writeln('\nFiles below 80 %:');
  final weak = files.entries.where((e) => e.value.hit < e.value.found * 0.8);
  for (final entry in weak) {
    stdout.writeln(
      '  ${entry.key}: ${_percent(entry.value.hit, entry.value.found)}',
    );
  }
  if (weak.isEmpty) stdout.writeln('  none');
}

String _percent(int covered, int total) =>
    total == 0 ? 'n/a' : '${(covered * 100 / total).toStringAsFixed(1)} %';

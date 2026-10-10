import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:slotly/data/local/app_database.dart';
import 'package:slotly/data/local/database_storage.dart';
import 'package:slotly/data/local/schema.dart';
import 'package:slotly/data/seed/demo_seed.dart';

import '../helpers/booking_fixtures.dart';

void main() {
  test('a saved database is read back with the same data', () async {
    final storage = MemoryDatabaseStorage();
    final first = await AppDatabase.open(storage);
    await DemoSeed(clock: () => DateTime(2026, 10, 5, 9)).apply(first);
    final booking = first.tables.bookings.values.first;

    final second = await AppDatabase.open(storage);

    expect(second.tables.bookings.length, first.tables.bookings.length);
    expect(second.tables.reviews.length, first.tables.reviews.length);
    final restored = second.tables.bookings[booking.id]!;
    expect(restored.startAt, booking.startAt);
    expect(restored.startAt.isUtc, isFalse, reason: 'shown in local time');
    expect(restored.specialist, booking.specialist);
    expect(second.tables.settings.seedVersion, DemoSeed.version);
  });

  test('dates are stored as UTC ISO-8601 strings', () async {
    final storage = MemoryDatabaseStorage();
    final database = await AppDatabase.open(storage);
    await database.update(
      (t) => t.bookings['b1'] = fixtureBooking(
        id: 'b1',
        startAt: DateTime(2026, 10, 6, 12),
      ),
    );

    final json = jsonDecode(storage.contents!) as Map<String, Object?>;
    final stored = (json['bookings']! as List).single as Map<String, Object?>;
    expect(
      stored['startAt'],
      DateTime(2026, 10, 6, 12).toUtc().toIso8601String(),
    );
    expect(stored['startAt'] as String, endsWith('Z'));
    expect(json['schemaVersion'], latestSchemaVersion);
  });

  test(
    'update notifies listeners, increases revision and writes once',
    () async {
      final storage = MemoryDatabaseStorage();
      final database = await AppDatabase.open(storage);
      var notified = 0;
      database.addListener(() => notified++);

      final result = await database.update((t) {
        t.settings.darkTheme = true;
        return 42;
      });

      expect(result, 42);
      expect(notified, 1);
      expect(database.revision, 1);
      expect(storage.writes, 1);
    },
  );

  test('quick consecutive updates are saved in order', () async {
    final storage = MemoryDatabaseStorage();
    final database = await AppDatabase.open(storage);
    final first = database.update((t) => t.settings.darkTheme = true);
    final second = database.update((t) => t.settings.darkTheme = false);
    await Future.wait([first, second]);
    await database.flush();

    final reopened = await AppDatabase.open(storage);
    expect(reopened.tables.settings.darkTheme, isFalse);
    expect(storage.writes, 2);
  });

  test('an unreadable file is backed up and the app starts empty', () async {
    final storage = MemoryDatabaseStorage('{not json');
    final database = await AppDatabase.open(storage);

    expect(database.tables.isEmpty, isTrue);
    expect(storage.corrupted, '{not json');
  });

  test('data from a newer app version is not read', () async {
    final raw = jsonEncode({'schemaVersion': latestSchemaVersion + 1});
    final storage = MemoryDatabaseStorage(raw);
    final database = await AppDatabase.open(storage);

    expect(database.tables.isEmpty, isTrue);
    expect(storage.corrupted, raw);
  });

  group('SchemaMigrator', () {
    test('version 1 gets the isHidden flag on services', () {
      final migrated = const SchemaMigrator().migrate({
        'schemaVersion': 1,
        'services': [
          {'id': 'svc-a'},
          {'id': 'svc-b', 'isHidden': true},
        ],
      });

      expect(migrated['schemaVersion'], 2);
      final services = (migrated['services']! as List)
          .cast<Map<String, Object?>>();
      expect(services.map((s) => s['isHidden']), [false, true]);
    });

    test('applies migrations one by one', () {
      final calls = <int>[];
      final migrator = SchemaMigrator(
        currentVersion: 3,
        migrations: {
          1: (data) {
            calls.add(1);
            return data..['fromV1'] = true;
          },
          2: (data) {
            calls.add(2);
            return data..['fromV2'] = data['fromV1'];
          },
        },
      );

      final migrated = migrator.migrate({'schemaVersion': 1});

      expect(calls, [1, 2]);
      expect(migrated['fromV2'], isTrue);
      expect(migrated['schemaVersion'], 3);
    });

    test('rejects data without a version or without a migration path', () {
      expect(
        () => const SchemaMigrator().migrate({}),
        throwsA(isA<UnsupportedSchemaException>()),
      );
      expect(
        () => const SchemaMigrator(
          currentVersion: 3,
          migrations: {},
        ).migrate({'schemaVersion': 2}),
        throwsA(isA<UnsupportedSchemaException>()),
      );
    });

    test('current data passes unchanged', () {
      final data = {'schemaVersion': latestSchemaVersion, 'x': 1};
      expect(const SchemaMigrator().migrate(data), data);
    });
  });
}

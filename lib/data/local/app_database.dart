import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'database_codec.dart';
import 'database_storage.dart';
import 'database_tables.dart';
import 'schema.dart';

/// Single source of truth for all local data.
///
/// The whole data set is small (hundreds of records), so it is kept in
/// memory and saved as one JSON document after every change. Reads are
/// synchronous lookups in [tables]; every change goes through [update],
/// which:
/// 1. applies the change to the in-memory tables,
/// 2. increases [revision] and notifies listeners (controllers reload),
/// 3. writes a snapshot to [DatabaseStorage].
///
/// Writes are queued, so two quick changes can never be saved out of order.
class AppDatabase extends ChangeNotifier {
  AppDatabase._(this._storage, this._tables);

  /// Loads stored data, migrating it to the latest schema. Unreadable or
  /// newer-than-supported data is backed up and replaced by an empty
  /// database, so the app still starts.
  static Future<AppDatabase> open(
    DatabaseStorage storage, {
    SchemaMigrator migrator = const SchemaMigrator(),
  }) async {
    final raw = await storage.read();
    var tables = DatabaseTables();
    if (raw != null) {
      try {
        final json = jsonDecode(raw) as JsonMap;
        tables = DatabaseCodec.decode(migrator.migrate(json));
      } on Object catch (error) {
        debugPrint('Slotly database is unreadable, starting over: $error');
        await storage.backupCorrupted(raw);
      }
    }
    return AppDatabase._(storage, tables);
  }

  /// Empty database in memory, for tests.
  static Future<AppDatabase> inMemory() => open(MemoryDatabaseStorage());

  final DatabaseStorage _storage;
  final DatabaseTables _tables;
  Future<void> _pendingWrite = Future.value();
  int _revision = 0;

  /// Read-only by convention: change data only through [update].
  DatabaseTables get tables => _tables;

  /// Increases with every change; caches compare it to know they are stale.
  int get revision => _revision;

  /// Applies [change], notifies listeners and persists the result.
  /// Completes when the snapshot has been written.
  Future<T> update<T>(T Function(DatabaseTables tables) change) {
    final result = change(_tables);
    _revision++;
    notifyListeners();
    final snapshot = jsonEncode(DatabaseCodec.encode(_tables));
    final write = _pendingWrite.then((_) => _storage.write(snapshot));
    // A failed write must not block later writes; the error is still
    // delivered to the caller of this update.
    _pendingWrite = write.catchError((Object _) {});
    return write.then((_) => result);
  }

  /// Completes when all queued writes are finished.
  Future<void> flush() => _pendingWrite;
}

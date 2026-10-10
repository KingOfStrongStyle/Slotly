import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'database_codec.dart';
import 'database_storage.dart';
import 'database_tables.dart';
import 'schema.dart';

class AppDatabase extends ChangeNotifier {
  AppDatabase._(this._storage, this._tables);

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

  static Future<AppDatabase> inMemory() => open(MemoryDatabaseStorage());

  final DatabaseStorage _storage;
  final DatabaseTables _tables;
  Future<void> _pendingWrite = Future.value();
  int _revision = 0;

  DatabaseTables get tables => _tables;

  int get revision => _revision;

  // Влад: меняем снимок в памяти сразу, а на диск пишем по очереди целиком.
  // revision нужен аналитике, чтобы понять, что кэш устарел
  Future<T> update<T>(T Function(DatabaseTables tables) change) {
    final result = change(_tables);
    _revision++;
    notifyListeners();
    final snapshot = jsonEncode(DatabaseCodec.encode(_tables));
    final write = _pendingWrite.then((_) => _storage.write(snapshot));
    _pendingWrite = write.catchError((Object _) {});
    return write.then((_) => result);
  }

  Future<void> flush() => _pendingWrite;
}

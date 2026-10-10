import 'dart:io';

/// Where the serialized database lives. The database itself does not know
/// whether it is a file on the device or a string in a test.
abstract interface class DatabaseStorage {
  /// `null` when nothing has been saved yet.
  Future<String?> read();

  Future<void> write(String contents);

  /// Keeps an unreadable snapshot for diagnostics before it is replaced.
  Future<void> backupCorrupted(String contents);
}

/// Stores the database as one JSON file.
///
/// Every write goes to a temporary file first and then replaces the real
/// file with a rename, which is atomic on Android and iOS file systems: a
/// crash in the middle of a write leaves the previous version intact.
class FileDatabaseStorage implements DatabaseStorage {
  FileDatabaseStorage(this.file);

  final File file;

  @override
  Future<String?> read() async =>
      await file.exists() ? file.readAsString() : null;

  @override
  Future<void> write(String contents) async {
    await file.parent.create(recursive: true);
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(contents, flush: true);
    await temporary.rename(file.path);
  }

  @override
  Future<void> backupCorrupted(String contents) =>
      File('${file.path}.corrupted').writeAsString(contents, flush: true);
}

/// In-memory storage for tests and previews.
class MemoryDatabaseStorage implements DatabaseStorage {
  MemoryDatabaseStorage([this.contents]);

  String? contents;
  String? corrupted;
  int writes = 0;

  @override
  Future<String?> read() async => contents;

  @override
  Future<void> write(String value) async {
    contents = value;
    writes++;
  }

  @override
  Future<void> backupCorrupted(String value) async => corrupted = value;
}

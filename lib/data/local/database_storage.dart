import 'dart:io';

abstract interface class DatabaseStorage {
  Future<String?> read();

  Future<void> write(String contents);

  Future<void> backupCorrupted(String contents);
}

class FileDatabaseStorage implements DatabaseStorage {
  FileDatabaseStorage(this.file);

  final File file;

  @override
  Future<String?> read() async =>
      await file.exists() ? file.readAsString() : null;

  @override
  // Влад: сначала во временный файл, потом rename - если приложение убьют
  // посреди записи, старый файл останется целым
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

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:slotly/data/local/app_database.dart';
import 'package:slotly/data/local/database_storage.dart';
import 'package:slotly/features/business/data/photo_storage.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('slotly_test_');
  });

  tearDown(() => directory.delete(recursive: true));

  group('FileDatabaseStorage', () {
    test('returns null before the first write', () async {
      final storage = FileDatabaseStorage(File('${directory.path}/db.json'));
      expect(await storage.read(), isNull);
    });

    test('writes through a temporary file and replaces the target', () async {
      final file = File('${directory.path}/nested/db.json');
      final storage = FileDatabaseStorage(file);

      await storage.write('{"a":1}');
      await storage.write('{"a":2}');

      expect(await storage.read(), '{"a":2}');
      expect(File('${file.path}.tmp').existsSync(), isFalse);
    });

    test('keeps a copy of corrupted data', () async {
      final file = File('${directory.path}/db.json');
      await file.writeAsString('{broken');
      final database = await AppDatabase.open(FileDatabaseStorage(file));

      expect(database.tables.isEmpty, isTrue);
      expect(File('${file.path}.corrupted').readAsStringSync(), '{broken');
    });

    test('the database survives a restart on disk', () async {
      final file = File('${directory.path}/db.json');
      final first = await AppDatabase.open(FileDatabaseStorage(file));
      await first.update((t) => t.settings.darkTheme = true);

      final second = await AppDatabase.open(FileDatabaseStorage(file));
      expect(second.tables.settings.darkTheme, isTrue);
    });
  });

  group('FilePhotoStorage', () {
    test('copies the picked file into the app directory and deletes it', () async {
      final source = File('${directory.path}/picked.jpg')
        ..writeAsBytesSync(List.filled(2048, 7));
      final storage = FilePhotoStorage(Directory('${directory.path}/photos'));

      expect(await storage.sizeOf(source.path), 2048);
      final path = await storage.importPhoto(source.path, 'photo-1');

      expect(path, endsWith('photos/photo-1.jpg'));
      expect(File(path).lengthSync(), 2048);
      // The original may disappear later; the copy stays.
      source.deleteSync();
      expect(File(path).existsSync(), isTrue);

      await storage.delete(path);
      expect(File(path).existsSync(), isFalse);
      await storage.delete(path);
    });
  });
}

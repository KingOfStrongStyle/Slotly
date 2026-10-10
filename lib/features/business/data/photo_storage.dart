import 'dart:io';

abstract interface class PhotoStorage {
  Future<int> sizeOf(String sourcePath);

  Future<String> importPhoto(String sourcePath, String photoId);

  Future<void> delete(String path);
}

class FilePhotoStorage implements PhotoStorage {
  FilePhotoStorage(this.directory);

  final Directory directory;

  @override
  Future<int> sizeOf(String sourcePath) => File(sourcePath).length();

  @override
  // Влад: копируем файл к себе, в базе только путь. Если фото удалят из галереи,
  // у организации оно останется
  Future<String> importPhoto(String sourcePath, String photoId) async {
    await directory.create(recursive: true);
    final dot = sourcePath.lastIndexOf('.');
    final extension = dot < 0 ? '.jpg' : sourcePath.substring(dot);
    final target = File('${directory.path}/$photoId$extension');
    await File(sourcePath).copy(target.path);
    return target.path;
  }

  @override
  Future<void> delete(String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
  }
}

class MemoryPhotoStorage implements PhotoStorage {
  MemoryPhotoStorage({this.sizes = const {}});

  final Map<String, int> sizes;
  final Set<String> stored = {};

  @override
  Future<int> sizeOf(String sourcePath) async =>
      sizes[sourcePath] ?? 100 * 1024;

  @override
  Future<String> importPhoto(String sourcePath, String photoId) async {
    final path = 'memory://$photoId';
    stored.add(path);
    return path;
  }

  @override
  Future<void> delete(String path) async => stored.remove(path);
}

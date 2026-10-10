import 'dart:io';

/// Copies picked images into a directory owned by the app.
///
/// The picker returns a temporary file or a content URI that may disappear
/// later; the copy keeps the photo available until the owner removes it.
abstract interface class PhotoStorage {
  /// Size of the picked file in bytes.
  Future<int> sizeOf(String sourcePath);

  /// Returns the path of the managed copy.
  Future<String> importPhoto(String sourcePath, String photoId);

  Future<void> delete(String path);
}

class FilePhotoStorage implements PhotoStorage {
  FilePhotoStorage(this.directory);

  final Directory directory;

  @override
  Future<int> sizeOf(String sourcePath) => File(sourcePath).length();

  @override
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

/// Keeps "files" in memory; used by tests.
class MemoryPhotoStorage implements PhotoStorage {
  MemoryPhotoStorage({this.sizes = const {}});

  /// Size of each source path; unknown paths are 100 KB.
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

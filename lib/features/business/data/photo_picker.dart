import 'package:image_picker/image_picker.dart';

/// Picks one image from the gallery. Behind an interface so widget tests
/// can return a fixed path without the platform plugin.
abstract interface class PhotoPicker {
  /// Path of the picked (already downscaled) image, or null if cancelled.
  Future<String?> pickImage();
}

/// Uses the Android Photo Picker (Android 13+) or the system gallery; no
/// storage permission is needed. The image is downscaled to 1600 px and
/// recompressed, so a 12 MP photo becomes a few hundred kilobytes.
class SystemPhotoPicker implements PhotoPicker {
  SystemPhotoPicker([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  static const maxSide = 1600.0;
  static const quality = 85;

  final ImagePicker _picker;

  @override
  Future<String?> pickImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: maxSide,
      maxHeight: maxSide,
      imageQuality: quality,
    );
    return file?.path;
  }
}

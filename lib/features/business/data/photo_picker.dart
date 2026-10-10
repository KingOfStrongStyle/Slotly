import 'package:image_picker/image_picker.dart';

abstract interface class PhotoPicker {
  Future<String?> pickImage();
}

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

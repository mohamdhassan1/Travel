import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import '../../core/utils/app_logger.dart';

enum PhotoSource { gallery, camera }

/// A picked photo as bytes (no `dart:io`, so it works on Android and Web).
class PickedPhoto {
  const PickedPhoto(this.bytes, this.contentType);
  final Uint8List bytes;
  final String contentType;
}

/// Picks a photo for the profile. Faked in tests.
abstract interface class PhotoPicker {
  bool get canUseCamera;

  /// `null` if the user cancelled.
  Future<PickedPhoto?> pick(PhotoSource source);
}

class ImagePickerPhotoPicker implements PhotoPicker {
  ImagePickerPhotoPicker({ImagePicker? picker, required this.canUseCamera}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  final bool canUseCamera;

  @override
  Future<PickedPhoto?> pick(PhotoSource source) async {
    final file = await _picker.pickImage(
      source: source == PhotoSource.camera ? ImageSource.camera : ImageSource.gallery,
      // A profile photo never needs more; keeps uploads well under 2 MB.
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
      preferredCameraDevice: CameraDevice.front,
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    return PickedPhoto(bytes, _contentType(file.mimeType, file.name, bytes));
  }

  static String _contentType(String? mime, String name, Uint8List bytes) {
    if (mime != null && mime.startsWith('image/')) return mime == 'image/jpg' ? 'image/jpeg' : mime;
    // Sniff the magic number when the platform doesn't say.
    if (bytes.length > 3 && bytes[0] == 0xFF && bytes[1] == 0xD8) return 'image/jpeg';
    if (bytes.length > 3 && bytes[0] == 0x89 && bytes[1] == 0x50) return 'image/png';
    if (bytes.length > 11 && String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') return 'image/webp';
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    AppLogger.info('Unknown photo type for $name; assuming JPEG');
    return 'image/jpeg';
  }
}

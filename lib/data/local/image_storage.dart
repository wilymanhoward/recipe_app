import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// True for photos shipped inside the app (the sample recipes), as opposed
/// to photos the user took, which live in the documents folder.
bool isBundledImage(String path) => path.startsWith('assets/');

abstract interface class ImageStorage {
  /// Lets the user take or choose a photo and stores a private copy of it.
  /// Returns the stored file's path, or null if the user cancelled.
  Future<String?> pick(ImageSource source);

  /// Deletes a stored photo. Missing files are ignored.
  Future<void> delete(String path);
}

class DeviceImageStorage implements ImageStorage {
  DeviceImageStorage({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<String?> pick(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked == null) return null;

    // The picker returns a temporary file the OS may delete at any time,
    // so keep our own copy in the app's documents folder.
    // shortcut: stores an absolute path; iOS can move the app container on
    // update, so switch to relative paths before shipping on iOS.
    final documents = await getApplicationDocumentsDirectory();
    final folder = Directory(p.join(documents.path, 'recipe_images'));
    await folder.create(recursive: true);
    final target = p.join(
      folder.path,
      '${DateTime.now().microsecondsSinceEpoch}${p.extension(picked.path)}',
    );
    await picked.saveTo(target);
    return target;
  }

  @override
  Future<void> delete(String path) async {
    // Sample recipe photos are bundled with the app and can't be deleted.
    if (isBundledImage(path)) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } on FileSystemException {
      // Best effort: a leftover file only wastes space.
    }
  }
}

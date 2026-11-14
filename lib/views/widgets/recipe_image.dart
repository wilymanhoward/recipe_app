import 'dart:io';

import 'package:material_ui/material_ui.dart';

import '../../data/local/image_storage.dart';

/// Shows a recipe photo (bundled with the app or taken on the device), or a
/// placeholder when there is no photo or the file can no longer be read.
class RecipeImage extends StatelessWidget {
  const RecipeImage({super.key, required this.imagePath});

  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final path = imagePath;
    if (path == null) return const _Placeholder();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Decode at display size, not full camera resolution, to keep
        // memory low when many photos are on screen.
        final pixelRatio = MediaQuery.devicePixelRatioOf(context);
        final cacheWidth = constraints.hasBoundedWidth
            ? (constraints.maxWidth * pixelRatio).round()
            : null;
        final ImageProvider image = isBundledImage(path)
            ? AssetImage(path)
            : FileImage(File(path));
        return Image(
          image: ResizeImage.resizeIfNeeded(cacheWidth, null, image),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) => const _Placeholder(),
        );
      },
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      // Soft warm gradient so recipes without a photo still look inviting.
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primaryContainer, colors.surfaceContainerHigh],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.restaurant_menu,
          size: 44,
          color: colors.primary.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}

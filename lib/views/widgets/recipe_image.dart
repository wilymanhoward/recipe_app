import 'dart:io';

import 'package:material_ui/material_ui.dart';

/// Shows a recipe photo from the device, or a placeholder when there is
/// no photo or the file can no longer be read.
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
        return Image.file(
          File(path),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          cacheWidth: cacheWidth,
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
    return ColoredBox(
      color: colors.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.restaurant_menu,
          size: 48,
          color: colors.onSurfaceVariant,
        ),
      ),
    );
  }
}

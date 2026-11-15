import 'package:material_ui/material_ui.dart';

/// Heart toggle used on recipe cards and the detail page.
class FavouriteButton extends StatelessWidget {
  const FavouriteButton({
    super.key,
    required this.isFavourite,
    required this.onPressed,
  });

  final bool isFavourite;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: isFavourite ? 'Remove from favourites' : 'Add to favourites',
      onPressed: onPressed,
      // Solid background so the heart reads on any photo.
      style: IconButton.styleFrom(
        backgroundColor: colors.surface.withValues(alpha: 0.85),
      ),
      icon: Icon(
        isFavourite ? Icons.favorite : Icons.favorite_border,
        color: isFavourite ? colors.primary : colors.onSurface,
      ),
    );
  }
}

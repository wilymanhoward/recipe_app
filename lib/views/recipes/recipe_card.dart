import 'package:material_ui/material_ui.dart';

import '../../models/recipe.dart';
import '../widgets/favourite_button.dart';
import '../widgets/recipe_image.dart';
import '../widgets/type_pill.dart';
import 'recipe_detail_page.dart';

class RecipeCard extends StatelessWidget {
  const RecipeCard({
    super.key,
    required this.recipe,
    required this.typeName,
    this.onTap,
    this.onFavouriteToggle,
  });

  /// Image height relative to card width.
  static const double imageAspectRatio = 16 / 9;

  /// Height of the text area under the image at normal text size.
  static const double textAreaHeight = 88;

  final Recipe recipe;
  final String typeName;
  final VoidCallback? onTap;
  final VoidCallback? onFavouriteToggle;

  static String _count(int count, String noun) =>
      '$count $noun${count == 1 ? '' : 's'}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metaStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontSize: 13,
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: imageAspectRatio,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Flies into the detail page's header when opened.
                  Hero(
                    tag: RecipeDetailPage.heroTag(recipe.id!),
                    child: RecipeImage(imagePath: recipe.imagePath),
                  ),
                  Positioned(
                    left: 12,
                    top: 12,
                    // Leaves room for the heart button on the right.
                    right: 64,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TypePill(typeName),
                    ),
                  ),
                  if (onFavouriteToggle case final onToggle?)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: FavouriteButton(
                        isFavourite: recipe.isFavourite,
                        onPressed: onToggle,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      // One step below the screen's headline, so the card title never
                      // competes with the wordmark.
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_count(recipe.ingredients.length, 'ingredient')}'
                      ' · ${_count(recipe.steps.length, 'step')}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: metaStyle,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

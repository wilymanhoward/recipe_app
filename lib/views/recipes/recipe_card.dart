import 'package:material_ui/material_ui.dart';

import '../../models/recipe.dart';
import '../widgets/recipe_image.dart';
import '../widgets/type_pill.dart';
import 'recipe_detail_page.dart';

class RecipeCard extends StatelessWidget {
  const RecipeCard({
    super.key,
    required this.recipe,
    required this.typeName,
    this.onTap,
  });

  /// Image height relative to card width.
  static const double imageAspectRatio = 16 / 10;

  /// Height of the text area under the image at normal text size.
  static const double textAreaHeight = 84;

  final Recipe recipe;
  final String typeName;
  final VoidCallback? onTap;

  static String _count(int count, String noun) =>
      '$count $noun${count == 1 ? '' : 's'}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSurfaceVariant;
    final metaStyle = theme.textTheme.bodySmall?.copyWith(color: mutedColor);

    WidgetSpan icon(IconData data) => WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Icon(data, size: 16, color: mutedColor),
      ),
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
                    right: 12,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TypePill(typeName),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge,
                    ),
                    const Spacer(),
                    // One Text with inline icons, so it ellipsizes on
                    // narrow cards instead of overflowing like a Row would.
                    Text.rich(
                      TextSpan(
                        style: metaStyle,
                        children: [
                          icon(Icons.shopping_basket_outlined),
                          TextSpan(
                            text: _count(
                              recipe.ingredients.length,
                              'ingredient',
                            ),
                          ),
                          const TextSpan(text: '     '),
                          icon(Icons.format_list_numbered),
                          TextSpan(text: _count(recipe.steps.length, 'step')),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

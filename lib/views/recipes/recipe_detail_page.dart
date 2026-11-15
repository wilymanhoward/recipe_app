import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/di/locator.dart';
import '../../models/recipe.dart';
import '../../models/recipe_type.dart';
import '../../viewmodels/recipe_detail_view_model.dart';
import '../widgets/favourite_button.dart';
import '../widgets/recipe_image.dart';
import '../widgets/type_pill.dart';
import 'recipe_form_page.dart';

/// Shows one recipe with edit and delete. Pops with the recipe's title
/// when it has been deleted.
class RecipeDetailPage extends StatelessWidget {
  const RecipeDetailPage({super.key});

  /// Wider than this, the photo sits beside the text instead of above it.
  static const double _sideBySideWidth = 700;

  static Route<String> route(int recipeId) {
    return MaterialPageRoute<String>(
      builder: (_) => ChangeNotifierProvider(
        create: (_) => RecipeDetailViewModel(
          recipeRepository: locator(),
          recipeTypeRepository: locator(),
          imageStorage: locator(),
          recipeId: recipeId,
        ),
        child: const RecipeDetailPage(),
      ),
    );
  }

  static String heroTag(int recipeId) => 'recipe-image-$recipeId';

  Future<void> _edit(BuildContext context, Recipe recipe) async {
    final saved = await Navigator.of(context)
        .push(RecipeFormPage.route(recipe: recipe));
    if (saved == null || !context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Changes saved')));
  }

  Future<void> _delete(
    BuildContext context,
    RecipeDetailViewModel viewModel,
    Recipe recipe,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${recipe.title}"?'),
        content: Text(
          recipe.imagePath == null
              ? 'This recipe will be removed.'
              : 'This recipe and its photo will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false) || !context.mounted) return;

    final deleted = await viewModel.delete(recipe);
    if (!context.mounted) return;
    if (deleted) {
      Navigator.of(context).pop(recipe.title);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete the recipe.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<RecipeDetailViewModel>();

    return StreamBuilder<Recipe?>(
      stream: viewModel.recipe,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _MessageScaffold('Could not load this recipe.');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final recipe = snapshot.data;
        if (recipe == null) {
          return const _MessageScaffold('This recipe no longer exists.');
        }

        return FutureBuilder<List<RecipeType>>(
          future: viewModel.recipeTypes,
          builder: (context, typesSnapshot) {
            final typeName = typesSnapshot.data
                ?.where((type) => type.id == recipe.typeId)
                .firstOrNull
                ?.name;
            return _buildRecipe(context, viewModel, recipe, typeName);
          },
        );
      },
    );
  }

  Widget _buildRecipe(
    BuildContext context,
    RecipeDetailViewModel viewModel,
    Recipe recipe,
    String? typeName,
  ) {
    final actions = [
      FavouriteButton(
        isFavourite: recipe.isFavourite,
        onPressed: () => viewModel.toggleFavourite(recipe),
      ),
      IconButton(
        tooltip: 'Delete',
        icon: const Icon(Icons.delete_outline),
        onPressed: viewModel.isDeleting
            ? null
            : () => _delete(context, viewModel, recipe),
      ),
    ];
    final editButton = FloatingActionButton.extended(
      onPressed: () => _edit(context, recipe),
      icon: const Icon(Icons.edit_outlined),
      label: const Text('Edit recipe'),
    );
    final image = Hero(
      tag: heroTag(recipe.id!),
      child: RecipeImage(imagePath: recipe.imagePath),
    );
    final content = _RecipeContent(recipe: recipe, typeName: typeName);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _sideBySideWidth) {
          return Scaffold(
            appBar: AppBar(actions: actions),
            floatingActionButton: editButton,
            body: SafeArea(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: AspectRatio(aspectRatio: 4 / 3, child: image),
                      ),
                    ),
                  ),
                  Expanded(child: SingleChildScrollView(child: content)),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          floatingActionButton: editButton,
          body: CustomScrollView(
            slivers: [
              // Round cream backgrounds keep the back and delete buttons
              // readable on top of dark photos.
              Theme(
                data: Theme.of(context).copyWith(
                  iconButtonTheme: IconButtonThemeData(
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surface
                          .withValues(alpha: 0.85),
                    ),
                  ),
                ),
                child: SliverAppBar(
                  pinned: true,
                  // 16:10 photo, but never taller than 60% of the screen.
                  expandedHeight: math.min(
                    constraints.maxWidth * 10 / 16,
                    constraints.maxHeight * 0.6,
                  ),
                  actions: actions,
                  flexibleSpace: FlexibleSpaceBar(background: image),
                ),
              ),
              SliverSafeArea(
                top: false,
                sliver: SliverToBoxAdapter(child: content),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RecipeContent extends StatelessWidget {
  const _RecipeContent({required this.recipe, required this.typeName});

  final Recipe recipe;
  final String? typeName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final name = typeName;

    return Padding(
      // Bottom padding keeps the last step clear of the Edit button.
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (name != null) ...[TypePill(name), const SizedBox(height: 10)],
          Text(recipe.title, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 24),
          // Ingredients sit on a cream "index card", like a handwritten
          // recipe card.
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(
                    'Ingredients',
                    count: recipe.ingredients.length,
                  ),
                  for (final ingredient in recipe.ingredients)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 8, right: 12),
                            child: Icon(
                              Icons.circle,
                              size: 7,
                              color: colors.secondary,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              ingredient,
                              style: theme.textTheme.bodyLarge,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          _SectionTitle('Steps', count: recipe.steps.length),
          for (final (index, step) in recipe.steps.indexed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    child: Text(
                      '${index + 1}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colors.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(step, style: theme.textTheme.bodyLarge),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      // One Text (not a Row) so it wraps instead of overflowing with
      // large font sizes.
      child: Text.rich(
        TextSpan(
          text: title,
          style: theme.textTheme.titleLarge,
          children: [
            TextSpan(
              text: '  ($count)',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageScaffold extends StatelessWidget {
  const _MessageScaffold(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

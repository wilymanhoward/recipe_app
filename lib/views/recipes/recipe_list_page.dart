import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../models/recipe.dart';
import '../../models/recipe_type.dart';
import '../../viewmodels/recipe_list_view_model.dart';
import '../widgets/wordmark.dart';
import 'recipe_card.dart';
import 'recipe_detail_page.dart';
import 'recipe_form_page.dart';
import 'type_filter_dropdown.dart';

class RecipeListPage extends StatelessWidget {
  const RecipeListPage({super.key});

  static const double _padding = 20;
  static const double _spacing = 20;
  static const double _fabClearance = 88;

  Future<void> _addRecipe(BuildContext context) async {
    final saved = await Navigator.of(context).push(RecipeFormPage.route());
    if (saved == null || !context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('"${saved.title}" saved')));
  }

  Future<void> _openRecipe(BuildContext context, Recipe recipe) async {
    // Looked up before leaving: [context] belongs to the recipe's card,
    // which may already be gone when we return if the recipe was deleted.
    final messenger = ScaffoldMessenger.of(context);
    final deletedTitle = await Navigator.of(context)
        .push(RecipeDetailPage.route(recipe.id!));
    if (deletedTitle == null) return;
    // Snackbars queue; replace an older one (e.g. "Changes saved") so this
    // message shows straight away.
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('"$deletedTitle" deleted')));
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<RecipeListViewModel>();
    final favouritesOnly = viewModel.favouritesOnly;

    return Scaffold(
      // Top-level tabs get a bigger title than other pages so the screen
      // name reads clearly.
      appBar: AppBar(
        toolbarHeight: 64,
        // Left-aligned on every platform, in line with the 16px page margin.
        centerTitle: false,
        title: favouritesOnly
            ? Text(
                'Favourites',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              )
            : const Wordmark(size: 28),
      ),
      floatingActionButton: favouritesOnly
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _addRecipe(context),
              icon: const Icon(Icons.add),
              label: const Text('Add recipe'),
            ),
      body: SafeArea(
        child: FutureBuilder<List<RecipeType>>(
          future: viewModel.recipeTypes,
          builder: (context, typesSnapshot) {
            if (typesSnapshot.hasError) {
              return const _Message(
                icon: Icons.error_outline,
                text: 'Could not load recipe types.',
              );
            }
            if (!typesSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final types = typesSnapshot.requireData;

            // One stream for the count in the filter and for the list below.
            return StreamBuilder<List<Recipe>>(
              stream: viewModel.recipes,
              builder: (context, snapshot) {
                final shown = snapshot.hasData
                    ? viewModel.applyFilter(snapshot.requireData).length
                    : null;
                return CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        _padding,
                        8,
                        _padding,
                        24,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TypeFilterDropdown(
                              types: types,
                              selectedTypeId: viewModel.selectedTypeId,
                              onChanged: viewModel.selectType,
                              countLabel: shown == null
                                  ? null
                                  : '$shown ${shown == 1 ? 'recipe' : 'recipes'}',
                            ),
                          ],
                        ),
                      ),
                    ),
                    _buildRecipes(context, snapshot, viewModel, types),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildRecipes(
    BuildContext context,
    AsyncSnapshot<List<Recipe>> snapshot,
    RecipeListViewModel viewModel,
    List<RecipeType> types,
  ) {
    if (snapshot.hasError) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: _Message(
          icon: Icons.error_outline,
          text: 'Could not load recipes.',
        ),
      );
    }
    if (!snapshot.hasData) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final recipes = viewModel.applyFilter(snapshot.requireData);
    if (recipes.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _Message(
          icon: viewModel.favouritesOnly
              ? Icons.favorite_border
              : Icons.menu_book_outlined,
          text: switch ((viewModel.favouritesOnly, viewModel.selectedTypeId)) {
            (true, null) =>
              'No favourites yet.\nTap the heart on a recipe to save it here.',
            (true, _) => 'No favourites of this type yet.',
            (false, null) => 'No recipes yet.',
            (false, _) => 'No recipes of this type yet.',
          },
        ),
      );
    }

    final typeNames = {for (final type in types) type.id: type.name};

    return SliverPadding(
      // Extra bottom space so the last card can scroll above the button.
      padding: const EdgeInsets.fromLTRB(_padding, 0, _padding, _fabClearance),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.crossAxisExtent;
          final columns = width < 600
              ? 1
              : width < 900
              ? 2
              : 3;
          final tileWidth = (width - _spacing * (columns - 1)) / columns;
          // Fixed tile height: image height plus a text area that grows
          // with the user's font size setting, so text never overflows.
          // Android scales small text more than large text, so take the
          // ratio of the card's smallest font (13) as the worst case.
          final textScale = MediaQuery.textScalerOf(context).scale(13) / 13;
          final tileHeight =
              tileWidth / RecipeCard.imageAspectRatio +
              RecipeCard.textAreaHeight * textScale;

          return SliverGrid.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: _spacing,
              crossAxisSpacing: _spacing,
              mainAxisExtent: tileHeight,
            ),
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return RecipeCard(
                recipe: recipe,
                typeName: typeNames[recipe.typeId] ?? 'Unknown',
                onTap: () => _openRecipe(context, recipe),
                onFavouriteToggle: () => viewModel.toggleFavourite(recipe),
              );
            },
          );
        },
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

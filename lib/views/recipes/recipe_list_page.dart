import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../models/recipe.dart';
import '../../models/recipe_type.dart';
import '../../viewmodels/recipe_list_view_model.dart';
import 'recipe_card.dart';
import 'recipe_detail_page.dart';
import 'recipe_form_page.dart';
import 'type_filter_dropdown.dart';

class RecipeListPage extends StatelessWidget {
  const RecipeListPage({super.key});

  static const double _padding = 16;
  static const double _spacing = 12;
  static const double _fabClearance = 88;

  Future<void> _addRecipe(BuildContext context) async {
    final saved = await Navigator.of(context).push(RecipeFormPage.route());
    if (saved == null || !context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('"${saved.title}" saved')));
  }

  Future<void> _openRecipe(BuildContext context, Recipe recipe) async {
    final deletedTitle = await Navigator.of(context)
        .push(RecipeDetailPage.route(recipe.id!));
    if (deletedTitle == null || !context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('"$deletedTitle" deleted')));
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<RecipeListViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Recipe Book')),
      floatingActionButton: FloatingActionButton.extended(
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

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    _padding,
                    _padding,
                    _padding,
                    _spacing,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: TypeFilterDropdown(
                      types: types,
                      selectedTypeId: viewModel.selectedTypeId,
                      onChanged: viewModel.selectType,
                    ),
                  ),
                ),
                StreamBuilder<List<Recipe>>(
                  stream: viewModel.recipes,
                  builder: (context, snapshot) =>
                      _buildRecipes(context, snapshot, viewModel, types),
                ),
              ],
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
          icon: Icons.menu_book_outlined,
          text: viewModel.selectedTypeId == null
              ? 'No recipes yet.'
              : 'No recipes of this type yet.',
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
          final tileHeight =
              tileWidth / RecipeCard.imageAspectRatio +
              MediaQuery.textScalerOf(context).scale(RecipeCard.textAreaHeight);

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

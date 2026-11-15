import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_app/viewmodels/recipe_list_view_model.dart';

import '../helpers/fakes.dart';

void main() {
  final recipes = [
    testRecipe(id: 1, title: 'Pancakes', isFavourite: true),
    testRecipe(id: 2, title: 'Omelette'),
    testRecipe(id: 3, title: 'Brownies', typeId: 4, isFavourite: true),
  ];

  RecipeListViewModel create({bool favouritesOnly = false}) {
    return RecipeListViewModel(
      recipeRepository: FakeRecipeRepository(recipes),
      recipeTypeRepository: FakeRecipeTypeRepository(),
      favouritesOnly: favouritesOnly,
    );
  }

  List<String> titles(Iterable<dynamic> list) => [
    for (final r in list) r.title as String,
  ];

  test('favourites tab shows only favourites, with the type filter', () {
    final viewModel = create(favouritesOnly: true);

    expect(titles(viewModel.applyFilter(recipes)), ['Pancakes', 'Brownies']);
    viewModel.selectType(4);
    expect(titles(viewModel.applyFilter(recipes)), ['Brownies']);
  });

  test('recipes tab shows everything', () {
    expect(titles(create().applyFilter(recipes)), hasLength(3));
  });

  test('toggleFavourite flips the stored flag', () async {
    final repository = FakeRecipeRepository(recipes);
    final viewModel = RecipeListViewModel(
      recipeRepository: repository,
      recipeTypeRepository: FakeRecipeTypeRepository(),
    );

    await viewModel.toggleFavourite(recipes[1]);

    expect(repository.recipes[1].isFavourite, isTrue);
  });
}

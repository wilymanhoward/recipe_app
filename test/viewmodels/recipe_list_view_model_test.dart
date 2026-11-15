import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_app/models/recipe_type.dart';
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

  group('when the recipe types are refreshed', () {
    const brunch = RecipeType(id: 9, name: 'Brunch');
    late FakeRecipeTypeRepository types;
    late RecipeListViewModel viewModel;

    setUp(() {
      types = FakeRecipeTypeRepository();
      viewModel = RecipeListViewModel(
        recipeRepository: FakeRecipeRepository(recipes),
        recipeTypeRepository: types,
      );
    });

    test('it picks up the new list and tells its listeners', () async {
      var notified = 0;
      viewModel.addListener(() => notified++);
      types.types = [...testTypes, brunch];

      await types.refresh();
      await pumpEventQueue();

      expect(
        (await viewModel.recipeTypes).map((t) => t.name),
        contains('Brunch'),
      );
      expect(notified, 1);
    });

    test('it keeps the selected type while it is still in the list', () async {
      viewModel.selectType(4);
      types.types = [...testTypes, brunch];

      await types.refresh();
      await pumpEventQueue();

      expect(viewModel.selectedTypeId, 4);
    });

    test('it clears the selected type when the new list lacks it', () async {
      viewModel.selectType(4);
      types.types = [testTypes.first];

      await types.refresh();
      await pumpEventQueue();

      expect(viewModel.selectedTypeId, isNull);
    });

    test('it stops listening once it is disposed', () async {
      expect(types.hasListeners, isTrue);

      viewModel.dispose();
      await pumpEventQueue();

      expect(types.hasListeners, isFalse);
    });
  });
}

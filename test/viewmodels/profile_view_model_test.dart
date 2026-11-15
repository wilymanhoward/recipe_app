import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_app/data/repositories/recipe_type_repository.dart';
import 'package:recipe_app/models/recipe_type.dart';
import 'package:recipe_app/viewmodels/profile_view_model.dart';

import '../helpers/fakes.dart';

void main() {
  group('CookbookStats', () {
    test('counts recipes, favourites and recipes per type', () {
      final stats = CookbookStats.from([
        testRecipe(id: 1, typeId: 1, isFavourite: true),
        testRecipe(id: 2, typeId: 4),
        testRecipe(id: 3, typeId: 4, isFavourite: true),
      ], testTypes);

      expect(stats.total, 3);
      expect(stats.favourites, 2);
      // Most used type first.
      expect(stats.byType.map((t) => '${t.name} ${t.count}'), [
        'Dessert 2',
        'Breakfast 1',
      ]);
    });

    test('names a type it does not know "Unknown"', () {
      final stats = CookbookStats.from([testRecipe(typeId: 99)], testTypes);

      expect(stats.byType.single.name, 'Unknown');
    });

    test('an empty cookbook has all zeros', () {
      final stats = CookbookStats.from([], testTypes);

      expect(stats.total, 0);
      expect(stats.favourites, 0);
      expect(stats.byType, isEmpty);
    });
  });

  group('ProfileViewModel', () {
    test('stats follow the recipes live', () async {
      final recipes = FakeRecipeRepository([testRecipe()]);
      final viewModel = ProfileViewModel(
        recipeRepository: recipes,
        recipeTypeRepository: FakeRecipeTypeRepository(),
      );
      addTearDown(viewModel.dispose);

      final totals = <int>[];
      final subscription = viewModel.stats.listen((s) => totals.add(s.total));
      addTearDown(subscription.cancel);

      await pumpEventQueue();
      await recipes.insert(testRecipe(id: 2, title: 'Cake', typeId: 4));
      await pumpEventQueue();
      await recipes.delete(1);
      await pumpEventQueue();

      expect(totals, [1, 2, 1]);
    });

    test('stats are recounted when the recipe types are refreshed', () async {
      final types = FakeRecipeTypeRepository();
      final viewModel = ProfileViewModel(
        recipeRepository: FakeRecipeRepository([testRecipe(typeId: 1)]),
        recipeTypeRepository: types,
      );
      addTearDown(viewModel.dispose);

      final names = <String>[];
      final subscription = viewModel.stats.listen(
        (s) => names.add(s.byType.single.name),
      );
      await pumpEventQueue();

      // The server renamed type 1.
      types.types = [const RecipeType(id: 1, name: 'Brunch')];
      await types.refresh();
      await pumpEventQueue();

      expect(names, ['Breakfast', 'Brunch']);

      await subscription.cancel();
      expect(types.hasListeners, isFalse);
    });

    test('loads where the recipe types came from', () async {
      final viewModel = ProfileViewModel(
        recipeRepository: FakeRecipeRepository([]),
        recipeTypeRepository: FakeRecipeTypeRepository(),
      );
      addTearDown(viewModel.dispose);
      expect(viewModel.typesInfo, isNull);

      await pumpEventQueue();

      expect(viewModel.typesInfo?.source, RecipeTypesSource.bundled);
    });

    test('refresh reports whether the server answered', () async {
      final types = FakeRecipeTypeRepository();
      final viewModel = ProfileViewModel(
        recipeRepository: FakeRecipeRepository([]),
        recipeTypeRepository: types,
      );
      addTearDown(viewModel.dispose);

      expect(await viewModel.refreshTypes(), isTrue);
      expect(viewModel.typesInfo?.source, RecipeTypesSource.server);
      expect(viewModel.isRefreshing, isFalse);

      types.refreshSource = RecipeTypesSource.savedCopy;
      expect(await viewModel.refreshTypes(), isFalse);
      expect(viewModel.typesInfo?.source, RecipeTypesSource.savedCopy);
    });
  });
}

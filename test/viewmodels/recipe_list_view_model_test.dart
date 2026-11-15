import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_app/models/recipe.dart';
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
  group('search and sort', () {
    Recipe recipe(
      int id,
      String title, {
      List<String> ingredients = const ['Salt'],
      int typeId = 1,
      bool favourite = false,
    }) {
      return Recipe(
        id: id,
        title: title,
        typeId: typeId,
        ingredients: ingredients,
        steps: const ['Cook'],
        createdAt: DateTime(2024, 1, id),
        isFavourite: favourite,
      );
    }

    // Newest first, the way the repository delivers them.
    final list = [
      recipe(4, 'banana pancakes', ingredients: ['Flour', 'Banana', 'Milk']),
      recipe(3, 'Nasi Lemak', ingredients: ['Rice', 'Coconut milk', 'Egg']),
      recipe(
        2,
        'Egg Fried Rice',
        ingredients: ['Rice', 'Egg', 'Soy sauce'],
        typeId: 2,
      ),
      recipe(
        1,
        'Apple Pie',
        ingredients: ['Apples', 'Butter'],
        typeId: 4,
        favourite: true,
      ),
    ];

    RecipeListViewModel create({bool favouritesOnly = false}) {
      return RecipeListViewModel(
        recipeRepository: FakeRecipeRepository(list),
        recipeTypeRepository: FakeRecipeTypeRepository(),
        favouritesOnly: favouritesOnly,
      );
    }

    test('with no search, everything shows, newest first', () {
      expect(titles(create().applyFilter(list)), [
        'banana pancakes',
        'Nasi Lemak',
        'Egg Fried Rice',
        'Apple Pie',
      ]);
    });

    test('finds a title, ignoring capital letters', () {
      final viewModel = create()..setQuery('NASI');

      expect(titles(viewModel.applyFilter(list)), ['Nasi Lemak']);
    });

    test('finds an ingredient', () {
      final viewModel = create()..setQuery('butter');

      expect(titles(viewModel.applyFilter(list)), ['Apple Pie']);
    });

    test('every word must match, in the title or the ingredients', () {
      final viewModel = create()..setQuery('rice egg');
      expect(titles(viewModel.applyFilter(list)), [
        'Nasi Lemak',
        'Egg Fried Rice',
      ]);

      viewModel.setQuery('rice soy');
      expect(titles(viewModel.applyFilter(list)), ['Egg Fried Rice']);
    });

    test('extra spaces are ignored, and only spaces is no search', () {
      final viewModel = create()..setQuery('   ');
      expect(viewModel.hasSearch, isFalse);
      expect(viewModel.applyFilter(list), hasLength(4));

      viewModel.setQuery('  egg  ');
      expect(viewModel.hasSearch, isTrue);
      expect(titles(viewModel.applyFilter(list)), [
        'Nasi Lemak',
        'Egg Fried Rice',
      ]);
    });

    test('a search with no match gives an empty list', () {
      final viewModel = create()..setQuery('pizza');

      expect(viewModel.applyFilter(list), isEmpty);
    });

    test('clearSearch brings everything back', () {
      final viewModel = create()
        ..setQuery('pizza')
        ..clearSearch();

      expect(viewModel.query, isEmpty);
      expect(viewModel.hasSearch, isFalse);
      expect(viewModel.applyFilter(list), hasLength(4));
    });

    test('search works together with the type filter', () {
      final viewModel = create()
        ..setQuery('egg')
        ..selectType(2);

      expect(titles(viewModel.applyFilter(list)), ['Egg Fried Rice']);
    });

    test('search works together with the favourites tab', () {
      final viewModel = create(favouritesOnly: true)..setQuery('a');

      expect(titles(viewModel.applyFilter(list)), ['Apple Pie']);
    });

    test('oldest first reverses the list', () {
      final viewModel = create()..setSort(RecipeSort.oldest);

      expect(titles(viewModel.applyFilter(list)), [
        'Apple Pie',
        'Egg Fried Rice',
        'Nasi Lemak',
        'banana pancakes',
      ]);
    });

    test('name sorts A to Z, ignoring capital letters', () {
      final viewModel = create()..setSort(RecipeSort.name);

      expect(titles(viewModel.applyFilter(list)), [
        'Apple Pie',
        'banana pancakes',
        'Egg Fried Rice',
        'Nasi Lemak',
      ]);
    });

    test('recipes with the same title stay newest first', () {
      final soups = [recipe(6, 'Soup'), recipe(5, 'Soup'), recipe(7, 'Apple')];
      final viewModel = create()..setSort(RecipeSort.name);

      expect(viewModel.applyFilter(soups).map((r) => r.id), [7, 6, 5]);
    });

    test('the sort order applies to the search results', () {
      final viewModel = create()
        ..setQuery('rice')
        ..setSort(RecipeSort.name);

      expect(titles(viewModel.applyFilter(list)), [
        'Egg Fried Rice',
        'Nasi Lemak',
      ]);
    });

    test('listeners hear about a new search or sort, not a repeat', () {
      final viewModel = create();
      var notified = 0;
      viewModel.addListener(() => notified++);

      viewModel
        ..setQuery('egg')
        ..setQuery('egg')
        ..setSort(RecipeSort.name)
        ..setSort(RecipeSort.name);

      expect(notified, 2);
    });
  });
}

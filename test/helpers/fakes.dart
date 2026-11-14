import 'package:recipe_app/data/repositories/recipe_repository.dart';
import 'package:recipe_app/data/repositories/recipe_type_repository.dart';
import 'package:recipe_app/models/recipe.dart';
import 'package:recipe_app/models/recipe_type.dart';

const testTypes = [
  RecipeType(id: 1, name: 'Breakfast'),
  RecipeType(id: 4, name: 'Dessert'),
];

Recipe testRecipe({int id = 1, String title = 'Pancakes', int typeId = 1}) {
  return Recipe(
    id: id,
    title: title,
    typeId: typeId,
    ingredients: const ['Flour', 'Milk'],
    steps: const ['Mix', 'Cook'],
    createdAt: DateTime(2024),
  );
}

/// In-memory stand-in for the SQLite repository, used by widget tests.
class FakeRecipeRepository implements RecipeRepository {
  FakeRecipeRepository(this.recipes);

  final List<Recipe> recipes;

  @override
  Stream<List<Recipe>> watchAll() => Stream.value(recipes);

  @override
  Future<Recipe> insert(Recipe recipe) => throw UnimplementedError();

  @override
  Future<void> update(Recipe recipe) => throw UnimplementedError();

  @override
  Future<void> delete(int id) => throw UnimplementedError();
}

class FakeRecipeTypeRepository implements RecipeTypeRepository {
  @override
  Future<List<RecipeType>> getAll() async => testTypes;
}

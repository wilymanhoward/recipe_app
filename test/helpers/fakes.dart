import 'package:image_picker/image_picker.dart';
import 'package:recipe_app/data/local/image_storage.dart';
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
  FakeRecipeRepository(List<Recipe> recipes) : recipes = [...recipes];

  final List<Recipe> recipes;

  @override
  Stream<List<Recipe>> watchAll() => Stream.value(List.of(recipes));

  @override
  Future<Recipe> insert(Recipe recipe) async {
    final saved = recipe.copyWith(id: recipes.length + 1);
    recipes.add(saved);
    return saved;
  }

  @override
  Future<void> update(Recipe recipe) async {
    final index = recipes.indexWhere((r) => r.id == recipe.id);
    recipes[index] = recipe;
  }

  @override
  Future<void> delete(int id) async => recipes.removeWhere((r) => r.id == id);
}

class FakeRecipeTypeRepository implements RecipeTypeRepository {
  @override
  Future<List<RecipeType>> getAll() async => testTypes;
}

class FakeImageStorage implements ImageStorage {
  @override
  Future<String?> pick(ImageSource source) async => null;

  @override
  Future<void> delete(String path) async {}
}

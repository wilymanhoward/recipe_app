import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_app/data/local/app_database.dart';
import 'package:recipe_app/data/local/seed_data.dart';
import 'package:recipe_app/data/repositories/recipe_repository.dart';
import 'package:recipe_app/models/recipe.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late AppDatabase database;
  late SqliteRecipeRepository repository;
  final seedCount = buildSeedRecipes(DateTime.now()).length;

  Recipe newRecipe({String title = 'Toast'}) => Recipe(
    title: title,
    typeId: 1,
    ingredients: const ['Bread'],
    steps: const ['Toast it'],
    createdAt: DateTime.now().add(const Duration(days: 1)),
  );

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    database = await AppDatabase.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    repository = SqliteRecipeRepository(database.db);
  });

  tearDown(() => database.close());

  Future<List<Recipe>> current() => repository.watchAll().first;

  test('a new database contains the seed recipes', () async {
    expect(await current(), hasLength(seedCount));
  });

  test('insert assigns an id and puts the recipe first', () async {
    final saved = await repository.insert(newRecipe());

    final recipes = await current();
    expect(saved.id, isNotNull);
    expect(recipes, hasLength(seedCount + 1));
    expect(recipes.first.id, saved.id);
  });

  test('update changes the stored recipe', () async {
    final saved = await repository.insert(newRecipe());

    await repository.update(
      saved.copyWith(title: 'French Toast', steps: ['Dip', 'Fry']),
    );

    final stored = (await current()).firstWhere((r) => r.id == saved.id);
    expect(stored.title, 'French Toast');
    expect(stored.steps, ['Dip', 'Fry']);
  });

  test('update rejects a recipe that was never saved', () {
    expect(() => repository.update(newRecipe()), throwsArgumentError);
  });

  test('delete removes the recipe', () async {
    final saved = await repository.insert(newRecipe());

    await repository.delete(saved.id!);

    final recipes = await current();
    expect(recipes, hasLength(seedCount));
    expect(recipes.any((r) => r.id == saved.id), isFalse);
  });

  test('watchAll emits again after a change', () async {
    final updated = repository
        .watchAll()
        .firstWhere((recipes) => recipes.length == seedCount + 1)
        .timeout(const Duration(seconds: 5));

    await repository.insert(newRecipe(title: 'Watched'));

    expect((await updated).first.title, 'Watched');
  });
}

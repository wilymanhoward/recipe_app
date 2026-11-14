import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_app/data/local/seed_data.dart';
import 'package:recipe_app/models/recipe.dart';
import 'package:recipe_app/models/recipe_type.dart';

void main() {
  group('Recipe', () {
    test('survives a toMap/fromMap round trip', () {
      final original = Recipe(
        id: 7,
        title: 'Toast',
        typeId: 1,
        imagePath: '/data/toast.jpg',
        ingredients: const ['Bread', 'Butter'],
        steps: const ['Toast the bread', 'Spread the butter'],
        createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
      );

      final copy = Recipe.fromMap(original.toMap());

      expect(copy.id, original.id);
      expect(copy.title, original.title);
      expect(copy.typeId, original.typeId);
      expect(copy.imagePath, original.imagePath);
      expect(copy.ingredients, original.ingredients);
      expect(copy.steps, original.steps);
      expect(copy.createdAt, original.createdAt);
    });

    test('toMap leaves out a null id so SQLite can assign one', () {
      final recipe = Recipe(
        title: 'Toast',
        typeId: 1,
        ingredients: const ['Bread'],
        steps: const ['Toast it'],
        createdAt: DateTime(2024),
      );

      expect(recipe.toMap().containsKey('id'), isFalse);
    });
  });

  group('RecipeType', () {
    test('parses the bundled recipetypes.json', () {
      final json = File('assets/recipetypes.json').readAsStringSync();

      final types = RecipeType.listFromJson(json);

      expect(types, isNotEmpty);
      expect(types.map((t) => t.id).toSet(), hasLength(types.length));
    });

    test('compares equal by id', () {
      expect(
        const RecipeType(id: 1, name: 'Breakfast'),
        const RecipeType(id: 1, name: 'Breakfast'),
      );
    });
  });

  test('every seed recipe uses a type from recipetypes.json', () {
    final json = File('assets/recipetypes.json').readAsStringSync();
    final typeIds = RecipeType.listFromJson(json).map((t) => t.id).toSet();

    for (final recipe in buildSeedRecipes(DateTime.now())) {
      expect(typeIds, contains(recipe.typeId), reason: recipe.title);
    }
  });
}

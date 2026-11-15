import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_app/data/local/image_storage.dart';
import 'package:recipe_app/data/local/seed_data.dart';

void main() {
  test('every sample recipe has a bundled photo that exists', () {
    for (final recipe in buildSeedRecipes(DateTime(2024))) {
      final path = recipe.imagePath!;
      expect(isBundledImage(path), isTrue, reason: recipe.title);
      expect(File(path).existsSync(), isTrue, reason: path);
    }
  });

  test('deleting a bundled photo does nothing', () async {
    await DeviceImageStorage().delete('assets/images/recipes/teh_tarik.jpg');

    expect(File('assets/images/recipes/teh_tarik.jpg').existsSync(), isTrue);
  });

  test('sample recipes have different titles and real content', () {
    final recipes = buildSeedRecipes(DateTime(2024));

    expect(recipes.map((r) => r.title).toSet(), hasLength(recipes.length));
    for (final recipe in recipes) {
      expect(recipe.ingredients, isNotEmpty, reason: recipe.title);
      expect(recipe.steps, isNotEmpty, reason: recipe.title);
    }
  });

  test('the sample recipes cover every recipe type', () {
    final used = buildSeedRecipes(DateTime(2024)).map((r) => r.typeId).toSet();

    expect(used, {1, 2, 3, 4, 5, 6});
  });
}

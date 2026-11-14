import 'package:flutter/services.dart';

import '../../models/recipe_type.dart';

abstract interface class RecipeTypeRepository {
  Future<List<RecipeType>> getAll();
}

/// Reads recipe types from the bundled `assets/recipetypes.json`.
class AssetRecipeTypeRepository implements RecipeTypeRepository {
  AssetRecipeTypeRepository(this._bundle);

  static const String assetPath = 'assets/recipetypes.json';

  final AssetBundle _bundle;
  Future<List<RecipeType>>? _cache;

  // The file never changes at runtime, so it is parsed once and reused.
  @override
  Future<List<RecipeType>> getAll() {
    return _cache ??= _bundle
        .loadString(assetPath)
        .then(RecipeType.listFromJson);
  }
}

import 'package:flutter/foundation.dart';

import '../data/repositories/recipe_repository.dart';
import '../data/repositories/recipe_type_repository.dart';
import '../models/recipe.dart';
import '../models/recipe_type.dart';

/// State for a recipe list screen: the recipe stream, the available
/// recipe types and the currently selected type filter. With
/// [favouritesOnly] it powers the Favourites tab.
class RecipeListViewModel extends ChangeNotifier {
  RecipeListViewModel({
    required this._recipeRepository,
    required RecipeTypeRepository recipeTypeRepository,
    this.favouritesOnly = false,
  }) : recipes = _recipeRepository.watchAll(),
       recipeTypes = recipeTypeRepository.getAll();

  final RecipeRepository _recipeRepository;
  final bool favouritesOnly;

  /// Created once so the StreamBuilder keeps a single subscription
  /// across rebuilds.
  final Stream<List<Recipe>> recipes;
  final Future<List<RecipeType>> recipeTypes;

  int? _selectedTypeId;

  /// Null means "All types".
  int? get selectedTypeId => _selectedTypeId;

  void selectType(int? typeId) {
    if (typeId == _selectedTypeId) return;
    _selectedTypeId = typeId;
    notifyListeners();
  }

  List<Recipe> applyFilter(List<Recipe> all) {
    final typeId = _selectedTypeId;
    return [
      for (final recipe in all)
        if ((!favouritesOnly || recipe.isFavourite) &&
            (typeId == null || recipe.typeId == typeId))
          recipe,
    ];
  }

  /// The list updates through the recipe stream, so nothing to notify.
  Future<void> toggleFavourite(Recipe recipe) {
    return _recipeRepository.setFavourite(
      recipe.id!,
      isFavourite: !recipe.isFavourite,
    );
  }
}

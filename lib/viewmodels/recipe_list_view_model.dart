import 'package:flutter/foundation.dart';

import '../data/repositories/recipe_repository.dart';
import '../data/repositories/recipe_type_repository.dart';
import '../models/recipe.dart';
import '../models/recipe_type.dart';

/// State for the recipe list screen: the recipe stream, the available
/// recipe types and the currently selected type filter.
class RecipeListViewModel extends ChangeNotifier {
  RecipeListViewModel({
    required RecipeRepository recipeRepository,
    required RecipeTypeRepository recipeTypeRepository,
  }) : recipes = recipeRepository.watchAll(),
       recipeTypes = recipeTypeRepository.getAll();

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
    if (typeId == null) return all;
    return all.where((recipe) => recipe.typeId == typeId).toList();
  }
}

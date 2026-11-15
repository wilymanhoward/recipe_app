import 'dart:async';

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
    required this._recipeTypeRepository,
    this.favouritesOnly = false,
  }) : recipes = _recipeRepository.watchAll(),
       _recipeTypes = _recipeTypeRepository.getAll() {
    // The tabs stay alive, so the Profile tab's "Refresh" has to reach us.
    _typesRefreshed = _recipeTypeRepository.refreshed.listen(
      (_) => unawaited(_reloadTypes()),
    );
  }

  final RecipeRepository _recipeRepository;
  final RecipeTypeRepository _recipeTypeRepository;
  final bool favouritesOnly;

  /// Created once so the StreamBuilder keeps a single subscription
  /// across rebuilds.
  final Stream<List<Recipe>> recipes;

  Future<List<RecipeType>> _recipeTypes;
  StreamSubscription<void>? _typesRefreshed;
  bool _isDisposed = false;
  int? _selectedTypeId;

  /// The current list. Replaced when the types are refreshed, so the
  /// FutureBuilder that shows it picks up the new one.
  Future<List<RecipeType>> get recipeTypes => _recipeTypes;

  /// Null means "All types".
  int? get selectedTypeId => _selectedTypeId;

  void selectType(int? typeId) {
    if (typeId == _selectedTypeId) return;
    _selectedTypeId = typeId;
    notifyListeners();
  }

  Future<void> _reloadTypes() async {
    final future = _recipeTypeRepository.getAll();
    final List<RecipeType> types;
    try {
      types = await future;
    } catch (error) {
      // Keep the list we already have.
      debugPrint('Could not reload the recipe types: $error');
      return;
    }
    if (_isDisposed) return;
    _recipeTypes = future;
    // The new list may no longer have the type that is selected.
    if (_selectedTypeId != null && !types.any((t) => t.id == _selectedTypeId)) {
      _selectedTypeId = null;
    }
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

  @override
  void dispose() {
    _isDisposed = true;
    unawaited(_typesRefreshed?.cancel());
    super.dispose();
  }
}

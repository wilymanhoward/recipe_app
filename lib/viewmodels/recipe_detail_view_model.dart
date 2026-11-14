import 'package:flutter/foundation.dart';

import '../data/local/image_storage.dart';
import '../data/repositories/recipe_repository.dart';
import '../data/repositories/recipe_type_repository.dart';
import '../models/recipe.dart';
import '../models/recipe_type.dart';

/// State for the recipe detail screen.
class RecipeDetailViewModel extends ChangeNotifier {
  RecipeDetailViewModel({
    required this._recipeRepository,
    required RecipeTypeRepository recipeTypeRepository,
    required this._imageStorage,
    required int recipeId,
  }) : recipe = _recipeRepository.watchAll().map(
         (recipes) => recipes.where((r) => r.id == recipeId).firstOrNull,
       ),
       recipeTypes = recipeTypeRepository.getAll();

  final RecipeRepository _recipeRepository;
  final ImageStorage _imageStorage;

  /// The recipe, updated live after edits. Emits null once it is deleted.
  final Stream<Recipe?> recipe;
  final Future<List<RecipeType>> recipeTypes;

  bool _isDeleting = false;
  bool get isDeleting => _isDeleting;

  /// Deletes the recipe and its photo. Returns false if it failed.
  Future<bool> delete(Recipe recipe) async {
    final id = recipe.id;
    if (id == null || _isDeleting) return false;
    _isDeleting = true;
    notifyListeners();
    try {
      await _recipeRepository.delete(id);
      // Remove the photo only once the row is gone, so a failed delete
      // never leaves a recipe pointing at a missing file.
      final imagePath = recipe.imagePath;
      if (imagePath != null) await _imageStorage.delete(imagePath);
      return true;
    } catch (_) {
      return false;
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }
}

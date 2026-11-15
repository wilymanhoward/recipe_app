import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/repositories/recipe_repository.dart';
import '../data/repositories/recipe_type_repository.dart';
import '../models/recipe.dart';
import '../models/recipe_type.dart';

/// How the list is ordered.
enum RecipeSort {
  /// Newest first. This is the order the repository already delivers.
  newest,

  oldest,

  /// By title, A to Z, ignoring capital letters.
  name,
}

/// State for a recipe list screen: the recipe stream, the available
/// recipe types, the type filter, the search text and the sort order. With
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
  String _query = '';
  RecipeSort _sort = RecipeSort.newest;

  /// What the user typed in the search box, as typed.
  String get query => _query;

  /// True when the search box holds something other than spaces.
  bool get hasSearch => _query.trim().isNotEmpty;

  RecipeSort get sort => _sort;

  void setQuery(String value) {
    if (value == _query) return;
    _query = value;
    notifyListeners();
  }

  void clearSearch() => setQuery('');

  void setSort(RecipeSort value) {
    if (value == _sort) return;
    _sort = value;
    notifyListeners();
  }

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

  /// Keeps the recipes that pass the favourites, type and search filters,
  /// in the chosen order. [all] must be newest first, as the repository
  /// delivers it.
  List<Recipe> applyFilter(List<Recipe> all) {
    final typeId = _selectedTypeId;
    final words = _searchWords;
    final result = [
      for (final recipe in all)
        if ((!favouritesOnly || recipe.isFavourite) &&
            (typeId == null || recipe.typeId == typeId) &&
            _matches(recipe, words))
          recipe,
    ];
    switch (_sort) {
      case RecipeSort.newest:
        break;
      case RecipeSort.oldest:
        return result.reversed.toList();
      case RecipeSort.name:
        // sort() is not stable, so equal titles fall back to the incoming
        // (newest first) position to stay predictable.
        final position = {for (final (i, r) in result.indexed) r: i};
        result.sort((a, b) {
          final byName = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          return byName != 0 ? byName : position[a]!.compareTo(position[b]!);
        });
    }
    return result;
  }

  /// The search split into lower-case words; empty when there is no search.
  List<String> get _searchWords {
    final text = _query.trim().toLowerCase();
    return text.isEmpty ? const [] : text.split(RegExp(r'\s+'));
  }

  /// A recipe matches when every word is found in its title or ingredients,
  /// so "rice egg" finds a recipe with rice in the title and egg in the list.
  static bool _matches(Recipe recipe, List<String> words) {
    if (words.isEmpty) return true;
    final text = '${recipe.title}\n${recipe.ingredients.join('\n')}'
        .toLowerCase();
    return words.every(text.contains);
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

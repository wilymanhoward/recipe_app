import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/repositories/recipe_repository.dart';
import '../data/repositories/recipe_type_repository.dart';
import '../models/recipe.dart';
import '../models/recipe_type.dart';

/// How many recipes use one recipe type.
class TypeCount {
  const TypeCount(this.name, this.count);

  final String name;
  final int count;
}

/// The numbers shown under "Your cookbook".
class CookbookStats {
  const CookbookStats({
    required this.total,
    required this.favourites,
    required this.byType,
  });

  /// Counts [recipes], with the most used type first. Types with no
  /// recipes are left out.
  factory CookbookStats.from(List<Recipe> recipes, List<RecipeType> types) {
    final names = {for (final type in types) type.id: type.name};
    final counts = <String, int>{};
    for (final recipe in recipes) {
      final name = names[recipe.typeId] ?? 'Unknown';
      counts[name] = (counts[name] ?? 0) + 1;
    }
    final byType =
        [for (final entry in counts.entries) TypeCount(entry.key, entry.value)]
          ..sort((a, b) {
            final byCount = b.count.compareTo(a.count);
            return byCount != 0 ? byCount : a.name.compareTo(b.name);
          });
    return CookbookStats(
      total: recipes.length,
      favourites: recipes.where((r) => r.isFavourite).length,
      byType: byType,
    );
  }

  final int total;
  final int favourites;
  final List<TypeCount> byType;
}

/// State for the Profile screen: live cookbook numbers and the status of
/// the downloaded recipe types.
class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel({
    required RecipeRepository recipeRepository,
    required this._recipeTypeRepository,
  }) : stats = _watchStats(recipeRepository, _recipeTypeRepository) {
    unawaited(_loadTypesInfo());
  }

  final RecipeTypeRepository _recipeTypeRepository;

  /// Recounts whenever a recipe changes, and also when the recipe types are
  /// refreshed, because a type may have been renamed.
  static Stream<CookbookStats> _watchStats(
    RecipeRepository recipes,
    RecipeTypeRepository types,
  ) {
    late final StreamController<CookbookStats> controller;
    StreamSubscription<List<Recipe>>? recipesSubscription;
    StreamSubscription<void>? typesSubscription;
    List<Recipe>? latest;

    Future<void> emit() async {
      final current = latest;
      if (current == null) return;
      try {
        final stats = CookbookStats.from(current, await types.getAll());
        // Skip a result that a newer list has already replaced.
        if (!controller.isClosed && identical(current, latest)) {
          controller.add(stats);
        }
      } catch (error, stackTrace) {
        if (!controller.isClosed) controller.addError(error, stackTrace);
      }
    }

    controller = StreamController<CookbookStats>(
      onListen: () {
        recipesSubscription = recipes.watchAll().listen((list) {
          latest = list;
          unawaited(emit());
        }, onError: controller.addError);
        typesSubscription = types.refreshed.listen((_) => unawaited(emit()));
      },
      onCancel: () async {
        await recipesSubscription?.cancel();
        await typesSubscription?.cancel();
      },
    );
    return controller.stream;
  }

  /// Emits new numbers whenever a recipe is added, changed, favourited or
  /// deleted. Created once so the StreamBuilder keeps one subscription.
  final Stream<CookbookStats> stats;

  RecipeTypesInfo? _typesInfo;
  bool _isRefreshing = false;
  bool _isDisposed = false;

  /// Null until the first load has finished.
  RecipeTypesInfo? get typesInfo => _typesInfo;
  bool get isRefreshing => _isRefreshing;

  Future<void> _loadTypesInfo() async {
    try {
      final info = await _recipeTypeRepository.getInfo();
      if (_isDisposed) return;
      _typesInfo = info;
      notifyListeners();
    } catch (error) {
      debugPrint('Could not read the recipe types status: $error');
    }
  }

  /// Downloads the recipe types again. Returns true when the server answered,
  /// false when the saved copy or the bundled list was used instead.
  Future<bool> refreshTypes() async {
    if (_isRefreshing) return false;
    _isRefreshing = true;
    notifyListeners();
    try {
      final info = await _recipeTypeRepository.refresh();
      if (!_isDisposed) _typesInfo = info;
      return info.source == RecipeTypesSource.server;
    } catch (error) {
      debugPrint('Recipe types refresh failed: $error');
      return false;
    } finally {
      _isRefreshing = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

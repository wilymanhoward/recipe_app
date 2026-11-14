import 'dart:async';

import 'package:sqflite/sqflite.dart';

import '../../models/recipe.dart';
import '../local/app_database.dart';

abstract interface class RecipeRepository {
  /// Emits the full recipe list (newest first) now and after every change.
  Stream<List<Recipe>> watchAll();

  /// Saves a new recipe and returns it with its database id.
  Future<Recipe> insert(Recipe recipe);

  Future<void> update(Recipe recipe);

  Future<void> delete(int id);
}

class SqliteRecipeRepository implements RecipeRepository {
  SqliteRecipeRepository(this._db);

  final Database _db;
  final StreamController<List<Recipe>> _changes =
      StreamController<List<Recipe>>.broadcast();

  @override
  Stream<List<Recipe>> watchAll() {
    late final StreamController<List<Recipe>> controller;
    StreamSubscription<List<Recipe>>? subscription;
    var changedSinceListen = false;

    controller = StreamController<List<Recipe>>(
      onListen: () {
        // Subscribe to changes before the first query, so a write that
        // happens while the query runs is not lost.
        subscription = _changes.stream.listen((recipes) {
          changedSinceListen = true;
          controller.add(recipes);
        }, onError: controller.addError);
        _fetchAll().then((recipes) {
          // A newer list already arrived, so this result would be stale.
          if (!changedSinceListen) controller.add(recipes);
        }, onError: controller.addError);
      },
      onCancel: () => subscription?.cancel(),
    );
    return controller.stream;
  }

  @override
  Future<Recipe> insert(Recipe recipe) async {
    final id = await _db.insert(AppDatabase.recipesTable, recipe.toMap());
    await _notifyListeners();
    return recipe.copyWith(id: id);
  }

  @override
  Future<void> update(Recipe recipe) async {
    final id = recipe.id;
    if (id == null) {
      throw ArgumentError.value(
        recipe,
        'recipe',
        'Cannot update an unsaved recipe',
      );
    }
    await _db.update(
      AppDatabase.recipesTable,
      recipe.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
    await _notifyListeners();
  }

  @override
  Future<void> delete(int id) async {
    await _db.delete(
      AppDatabase.recipesTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    await _notifyListeners();
  }

  Future<List<Recipe>> _fetchAll() async {
    final rows = await _db.query(
      AppDatabase.recipesTable,
      orderBy: 'created_at DESC, id DESC',
    );
    return rows.map(Recipe.fromMap).toList();
  }

  Future<void> _notifyListeners() async {
    if (!_changes.hasListener) return;
    _changes.add(await _fetchAll());
  }
}

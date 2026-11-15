import 'dart:async';

import 'package:image_picker/image_picker.dart';
import 'package:recipe_app/data/local/image_storage.dart';
import 'package:recipe_app/data/local/session_store.dart';
import 'package:recipe_app/data/repositories/auth_repository.dart';
import 'package:recipe_app/data/repositories/recipe_repository.dart';
import 'package:recipe_app/data/repositories/recipe_type_repository.dart';
import 'package:recipe_app/models/recipe.dart';
import 'package:recipe_app/models/recipe_type.dart';
import 'package:recipe_app/models/user.dart';

const testTypes = [
  RecipeType(id: 1, name: 'Breakfast'),
  RecipeType(id: 4, name: 'Dessert'),
];

Recipe testRecipe({
  int id = 1,
  String title = 'Pancakes',
  int typeId = 1,
  bool isFavourite = false,
}) {
  return Recipe(
    id: id,
    title: title,
    typeId: typeId,
    ingredients: const ['Flour', 'Milk'],
    steps: const ['Mix', 'Cook'],
    createdAt: DateTime(2024),
    isFavourite: isFavourite,
  );
}

/// In-memory stand-in for the SQLite repository, used by widget tests.
class FakeRecipeRepository implements RecipeRepository {
  FakeRecipeRepository(List<Recipe> recipes) : recipes = [...recipes];

  final List<Recipe> recipes;
  final StreamController<List<Recipe>> _changes =
      StreamController<List<Recipe>>.broadcast();

  /// Like the real repository: the current list, then every change.
  @override
  Stream<List<Recipe>> watchAll() async* {
    yield List.of(recipes);
    yield* _changes.stream;
  }

  void _emit() => _changes.add(List.of(recipes));

  @override
  Future<Recipe> insert(Recipe recipe) async {
    final saved = recipe.copyWith(id: recipes.length + 1);
    recipes.add(saved);
    _emit();
    return saved;
  }

  @override
  Future<void> update(Recipe recipe) async {
    final index = recipes.indexWhere((r) => r.id == recipe.id);
    recipes[index] = recipe;
    _emit();
  }

  @override
  Future<void> delete(int id) async {
    recipes.removeWhere((r) => r.id == id);
    _emit();
  }

  @override
  Future<void> setFavourite(int id, {required bool isFavourite}) async {
    final index = recipes.indexWhere((r) => r.id == id);
    recipes[index] = recipes[index].copyWith(isFavourite: isFavourite);
    _emit();
  }
}

class FakeRecipeTypeRepository implements RecipeTypeRepository {
  @override
  Future<List<RecipeType>> getAll() async => testTypes;
}

class FakeSessionStore implements SessionStore {
  int? userId;

  @override
  Future<int?> readUserId() async => userId;

  @override
  Future<void> saveUserId(int userId) async => this.userId = userId;

  @override
  Future<void> clear() async => userId = null;
}

/// Accepts one account: "cook" / "secret1".
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.sessionUser});

  User? sessionUser;
  static const User cook = User(id: 1, username: 'cook');

  @override
  Future<User?> restoreSession() async => sessionUser;

  @override
  Future<User> register(String username, String password) async {
    if (username.trim().toLowerCase() == 'cook') {
      throw const AuthException('That username is already taken.');
    }
    return sessionUser = User(id: 2, username: username.trim());
  }

  @override
  Future<User> login(String username, String password) async {
    if (username != 'cook' || password != 'secret1') {
      throw const AuthException('Wrong username or password.');
    }
    return sessionUser = cook;
  }

  @override
  Future<void> logout() async => sessionUser = null;
}

class FakeImageStorage implements ImageStorage {
  @override
  Future<String?> pick(ImageSource source) async => null;

  @override
  Future<void> delete(String path) async {}
}

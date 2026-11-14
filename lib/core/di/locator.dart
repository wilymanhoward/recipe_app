import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';

import '../../data/local/app_database.dart';
import '../../data/repositories/recipe_repository.dart';
import '../../data/repositories/recipe_type_repository.dart';

final GetIt locator = GetIt.instance;

/// Registers app-wide services. Called once from `main` before `runApp`.
/// Callers depend on the abstract repository types, so an implementation
/// can be swapped here (e.g. a fake in tests) without touching the UI.
Future<void> setupLocator() async {
  final database = await AppDatabase.open();
  locator
    ..registerSingleton<AppDatabase>(database)
    ..registerLazySingleton<RecipeRepository>(
      () => SqliteRecipeRepository(locator<AppDatabase>().db),
    )
    ..registerLazySingleton<RecipeTypeRepository>(
      () => AssetRecipeTypeRepository(rootBundle),
    );
}

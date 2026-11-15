import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';

import '../../data/local/app_database.dart';
import '../../data/local/image_storage.dart';
import '../../data/repositories/recipe_repository.dart';
import '../../data/remote/api_client.dart';
import '../../data/repositories/recipe_type_repository.dart';
import '../app_config.dart';

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
    ..registerLazySingleton<ApiClient>(ApiClient.new)
    // Only this line changed when networking was added: screens still ask
    // for a RecipeTypeRepository and don't know where the data comes from.
    ..registerLazySingleton<RecipeTypeRepository>(
      () => RemoteRecipeTypeRepository(
        apiClient: locator(),
        db: locator<AppDatabase>().db,
        url: Uri.parse(recipeTypesUrl),
        fallback: AssetRecipeTypeRepository(rootBundle),
      ),
    )
    ..registerLazySingleton<ImageStorage>(DeviceImageStorage.new);
}

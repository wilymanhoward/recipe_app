import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

import '../../models/recipe_type.dart';
import '../local/app_database.dart';
import '../remote/api_client.dart';

abstract interface class RecipeTypeRepository {
  Future<List<RecipeType>> getAll();
}

/// Reads recipe types from the bundled `assets/recipetypes.json`.
class AssetRecipeTypeRepository implements RecipeTypeRepository {
  AssetRecipeTypeRepository(this._bundle);

  static const String assetPath = 'assets/recipetypes.json';

  final AssetBundle _bundle;
  Future<List<RecipeType>>? _cache;

  // The file never changes at runtime, so it is parsed once and reused.
  @override
  Future<List<RecipeType>> getAll() {
    return _cache ??= _bundle
        .loadString(assetPath)
        .then(RecipeType.listFromJson);
  }
}

/// Downloads the latest recipe types and keeps the last good copy in
/// SQLite. Order: network -> saved copy -> [fallback] (the bundled file),
/// so the app always has types, even offline on first launch.
class RemoteRecipeTypeRepository implements RecipeTypeRepository {
  RemoteRecipeTypeRepository({
    // Private named parameters: callers still write `apiClient:` etc.
    required this._apiClient,
    required this._db,
    required this._url,
    required this._fallback,
  });

  final ApiClient _apiClient;
  final Database _db;
  final Uri _url;
  final RecipeTypeRepository _fallback;
  Future<List<RecipeType>>? _cache;

  // Loaded once per app launch; every screen then shares the result.
  @override
  Future<List<RecipeType>> getAll() => _cache ??= _load();

  Future<List<RecipeType>> _load() async {
    try {
      final body = await _apiClient.getText(_url);
      // Parse before saving, so a broken download never replaces a good copy.
      final types = _parse(body);
      await _db.insert(AppDatabase.cacheTable, {
        'key': '$_url',
        'body': body,
        'saved_at': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      return types;
    } catch (error) {
      debugPrint('Recipe types download failed, using saved copy: $error');
    }

    try {
      final rows = await _db.query(
        AppDatabase.cacheTable,
        columns: ['body'],
        where: 'key = ?',
        whereArgs: ['$_url'],
      );
      if (rows.isNotEmpty) return _parse(rows.single['body']! as String);
    } catch (error) {
      debugPrint('Saved recipe types unreadable, using bundled file: $error');
    }

    return _fallback.getAll();
  }

  static List<RecipeType> _parse(String body) {
    final types = RecipeType.listFromJson(body);
    // An empty list would leave the dropdowns with nothing to pick.
    if (types.isEmpty) throw const FormatException('No recipe types');
    return types;
  }
}

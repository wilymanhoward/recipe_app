import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

import '../../models/recipe_type.dart';
import '../local/app_database.dart';
import '../remote/api_client.dart';

/// Where the recipe types in use came from.
enum RecipeTypesSource {
  /// Downloaded just now.
  server,

  /// The last good download, kept in SQLite (the server was not reachable).
  savedCopy,

  /// The list bundled with the app (nothing downloaded or saved yet).
  bundled,
}

/// How the current recipe types were loaded, for the Profile screen.
class RecipeTypesInfo {
  const RecipeTypesInfo({
    required this.source,
    required this.count,
    this.updatedAt,
  });

  final RecipeTypesSource source;
  final int count;

  /// When the copy was downloaded; null for the bundled list.
  final DateTime? updatedAt;
}

abstract interface class RecipeTypeRepository {
  Future<List<RecipeType>> getAll();

  /// Where the types in use came from. Waits for the first load.
  Future<RecipeTypesInfo> getInfo();

  /// Tries the server again and returns how the types were loaded this time.
  /// Afterwards [getAll] returns the new list, and [refreshed] fires.
  Future<RecipeTypesInfo> refresh();

  /// Fires each time [refresh] has finished. Screens that are already open
  /// (the tabs stay alive) call [getAll] again to pick up the new list.
  Stream<void> get refreshed;
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

  @override
  Future<RecipeTypesInfo> getInfo() async {
    final types = await getAll();
    return RecipeTypesInfo(
      source: RecipeTypesSource.bundled,
      count: types.length,
    );
  }

  // Nothing to download: the bundled file is all there is.
  @override
  Future<RecipeTypesInfo> refresh() => getInfo();

  @override
  Stream<void> get refreshed => const Stream<void>.empty();
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
  Future<_Loaded>? _loaded;

  // Lives as long as the app (the repository is a singleton), so it is
  // never closed.
  final StreamController<void> _refreshed = StreamController<void>.broadcast();

  // Loaded once per app launch; every screen then shares the result.
  @override
  Future<List<RecipeType>> getAll() async => (await _current()).types;

  @override
  Future<RecipeTypesInfo> getInfo() async => (await _current()).info;

  @override
  Stream<void> get refreshed => _refreshed.stream;

  @override
  Future<RecipeTypesInfo> refresh() async {
    final loaded = _loaded = _load();
    final info = (await loaded).info;
    _refreshed.add(null);
    return info;
  }

  Future<_Loaded> _current() => _loaded ??= _load();

  Future<_Loaded> _load() async {
    try {
      final body = await _apiClient.getText(_url);
      // Parse before saving, so a broken download never replaces a good copy.
      final types = _parse(body);
      final now = DateTime.now();
      await _db.insert(AppDatabase.cacheTable, {
        'key': '$_url',
        'body': body,
        'saved_at': now.millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      return _Loaded(
        types,
        RecipeTypesInfo(
          source: RecipeTypesSource.server,
          count: types.length,
          updatedAt: now,
        ),
      );
    } catch (error) {
      debugPrint('Recipe types download failed, using saved copy: $error');
    }

    try {
      final rows = await _db.query(
        AppDatabase.cacheTable,
        columns: ['body', 'saved_at'],
        where: 'key = ?',
        whereArgs: ['$_url'],
      );
      if (rows.isNotEmpty) {
        final types = _parse(rows.single['body']! as String);
        return _Loaded(
          types,
          RecipeTypesInfo(
            source: RecipeTypesSource.savedCopy,
            count: types.length,
            updatedAt: DateTime.fromMillisecondsSinceEpoch(
              rows.single['saved_at']! as int,
            ),
          ),
        );
      }
    } catch (error) {
      debugPrint('Saved recipe types unreadable, using bundled file: $error');
    }

    final types = await _fallback.getAll();
    return _Loaded(
      types,
      RecipeTypesInfo(source: RecipeTypesSource.bundled, count: types.length),
    );
  }

  static List<RecipeType> _parse(String body) {
    final types = RecipeType.listFromJson(body);
    // An empty list would leave the dropdowns with nothing to pick.
    if (types.isEmpty) throw const FormatException('No recipe types');
    return types;
  }
}

/// A loaded list of types together with where it came from.
class _Loaded {
  const _Loaded(this.types, this.info);

  final List<RecipeType> types;
  final RecipeTypesInfo info;
}

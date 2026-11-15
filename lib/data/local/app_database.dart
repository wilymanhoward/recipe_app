import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'seed_data.dart';

/// Owns the SQLite connection, the schema and the first-run seed.
class AppDatabase {
  AppDatabase._(this.db);

  static const String recipesTable = 'recipes';

  /// Last good copy of downloaded files, keyed by URL (added in version 2).
  static const String cacheTable = 'cached_responses';

  static const int _version = 2;
  static const String _fileName = 'recipe_app.db';

  final Database db;

  /// [factory] and [path] are only passed by tests (in-memory FFI database).
  static Future<AppDatabase> open({
    DatabaseFactory? factory,
    String? path,
  }) async {
    final dbFactory = factory ?? databaseFactory;
    final dbPath =
        path ?? p.join(await dbFactory.getDatabasesPath(), _fileName);
    final db = await dbFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: _version,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
    return AppDatabase._(db);
  }

  // onCreate runs only when the database file does not exist yet,
  // so the sample recipes are inserted exactly once.
  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $recipesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        type_id INTEGER NOT NULL,
        image_path TEXT,
        ingredients TEXT NOT NULL,
        steps TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    await _createCacheTable(db);

    final batch = db.batch();
    for (final recipe in buildSeedRecipes(DateTime.now())) {
      batch.insert(recipesTable, recipe.toMap());
    }
    await batch.commit(noResult: true);
  }

  // Runs instead of onCreate for users who already have an older database,
  // so their recipes are kept. Each step brings the schema up one version.
  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) await _createCacheTable(db);
  }

  static Future<void> _createCacheTable(Database db) {
    return db.execute('''
      CREATE TABLE $cacheTable (
        key TEXT PRIMARY KEY,
        body TEXT NOT NULL,
        saved_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> close() => db.close();
}

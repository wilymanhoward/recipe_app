import 'package:sqflite/sqflite.dart';

import '../local/app_database.dart';

/// Small app settings (like the colour theme) that must survive a restart.
abstract interface class SettingsRepository {
  Future<String?> read(String key);

  Future<void> write(String key, String value);
}

/// Keeps settings in the existing key/value table, so no new table or
/// database upgrade is needed. Keys carry a prefix so they can't clash with
/// the downloaded-file copies stored next to them.
class SqliteSettingsRepository implements SettingsRepository {
  SqliteSettingsRepository(this._db);

  static const String _prefix = 'setting:';

  final Database _db;

  @override
  Future<String?> read(String key) async {
    final rows = await _db.query(
      AppDatabase.cacheTable,
      columns: ['body'],
      where: 'key = ?',
      whereArgs: ['$_prefix$key'],
    );
    return rows.isEmpty ? null : rows.single['body']! as String;
  }

  @override
  Future<void> write(String key, String value) {
    return _db.insert(AppDatabase.cacheTable, {
      'key': '$_prefix$key',
      'body': value,
      'saved_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}

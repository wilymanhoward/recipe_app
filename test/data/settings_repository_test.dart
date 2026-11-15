import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_app/data/local/app_database.dart';
import 'package:recipe_app/data/repositories/settings_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late AppDatabase database;
  late SqliteSettingsRepository settings;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    database = await AppDatabase.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    settings = SqliteSettingsRepository(database.db);
  });

  tearDown(() => database.close());

  test('reads nothing before anything was saved', () async {
    expect(await settings.read('theme_mode'), isNull);
  });

  test('saves a value, and saving again replaces it', () async {
    await settings.write('theme_mode', 'dark');
    await settings.write('theme_mode', 'light');

    expect(await settings.read('theme_mode'), 'light');
  });
}

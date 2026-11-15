import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:recipe_app/data/local/app_database.dart';
import 'package:recipe_app/data/local/seed_data.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test(
    'upgrading from version 1 adds the new tables and keeps recipes',
    () async {
      final folder = await Directory.systemTemp.createTemp('recipe_db');
      addTearDown(() => folder.delete(recursive: true));
      final path = p.join(folder.path, 'recipe_app.db');

      // A database as version 1 of the app left it: recipes only.
      final v1 = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, _) async {
            await db.execute(
              'CREATE TABLE recipes (id INTEGER PRIMARY KEY AUTOINCREMENT, '
              'title TEXT NOT NULL, type_id INTEGER NOT NULL, image_path TEXT, '
              'ingredients TEXT NOT NULL, steps TEXT NOT NULL, '
              'created_at INTEGER NOT NULL)',
            );
            await db.insert('recipes', {
              'title': 'My own recipe',
              'type_id': 1,
              'ingredients': '["Rice"]',
              'steps': '["Cook"]',
              'created_at': 0,
            });
          },
        ),
      );
      await v1.close();

      final upgraded = await AppDatabase.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      addTearDown(upgraded.close);

      final recipes = await upgraded.db.query(AppDatabase.recipesTable);
      final mine = recipes.singleWhere((r) => r['title'] == 'My own recipe');
      // Existing recipes get the new column with its default.
      expect(mine['is_favourite'], 0);
      expect(await upgraded.db.query(AppDatabase.cacheTable), isEmpty);
      expect(await upgraded.db.query(AppDatabase.usersTable), isEmpty);
      expect(await upgraded.db.getVersion(), 4);
    },
  );

  test('upgrading from version 3 adds the extra sample recipes once', () async {
    final folder = await Directory.systemTemp.createTemp('recipe_db');
    addTearDown(() => folder.delete(recursive: true));
    final path = p.join(folder.path, 'recipe_app.db');

    // A database as version 3 left it, with one recipe of the user's own.
    final v3 = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 3,
        onCreate: (db, _) async {
          await db.execute(
            'CREATE TABLE recipes (id INTEGER PRIMARY KEY AUTOINCREMENT, '
            'title TEXT NOT NULL, type_id INTEGER NOT NULL, image_path TEXT, '
            'ingredients TEXT NOT NULL, steps TEXT NOT NULL, '
            'created_at INTEGER NOT NULL, '
            'is_favourite INTEGER NOT NULL DEFAULT 0)',
          );
          await db.insert('recipes', {
            'title': 'My own recipe',
            'type_id': 1,
            'ingredients': '["Rice"]',
            'steps': '["Cook"]',
            'created_at': 0,
          });
        },
      ),
    );
    await v3.close();

    final extra = buildExtraSeedRecipes(DateTime.now()).length;
    for (var i = 0; i < 2; i++) {
      // The second open is the app starting again: nothing is added twice.
      final db = await AppDatabase.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      final titles = (await db.db.query(AppDatabase.recipesTable))
          .map((r) => r['title'])
          .toList();
      await db.close();

      expect(titles, hasLength(1 + extra));
      expect(titles, contains('My own recipe'));
      expect(titles, contains('Beef Rendang'));
    }
  });
}

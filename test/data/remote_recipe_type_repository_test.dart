import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:recipe_app/data/local/app_database.dart';
import 'package:recipe_app/data/remote/api_client.dart';
import 'package:recipe_app/data/repositories/recipe_type_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/fakes.dart';

void main() {
  const goodJson = '{"recipeTypes":[{"id":7,"name":"Supper"}]}';
  final url = Uri.parse('https://example.com/recipetypes.json');
  late AppDatabase database;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    database = await AppDatabase.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
  });

  tearDown(() => database.close());

  RemoteRecipeTypeRepository repositoryWith(
    Future<http.Response> Function() respond,
  ) {
    return RemoteRecipeTypeRepository(
      apiClient: ApiClient(client: MockClient((_) => respond())),
      db: database.db,
      url: url,
      fallback: FakeRecipeTypeRepository(),
    );
  }

  Future<http.Response> offline() async =>
      throw http.ClientException('No internet');

  test('uses the downloaded types and saves a copy', () async {
    final types = await repositoryWith(() async => http.Response(goodJson, 200))
        .getAll();

    expect(types.single.name, 'Supper');
    final saved = await database.db.query(AppDatabase.cacheTable);
    expect(saved.single['body'], goodJson);
  });

  test('offline, uses the saved copy from an earlier launch', () async {
    await repositoryWith(() async => http.Response(goodJson, 200)).getAll();

    final types = await repositoryWith(offline).getAll();

    expect(types.single.name, 'Supper');
  });

  test('offline with nothing saved, uses the bundled file', () async {
    final types = await repositoryWith(offline).getAll();

    expect(types, testTypes);
  });

  test('a broken download keeps the last good copy', () async {
    await repositoryWith(() async => http.Response(goodJson, 200)).getAll();

    for (final body in ['<html>Not found</html>', '{"recipeTypes":[]}']) {
      final types = await repositoryWith(() async => http.Response(body, 200))
          .getAll();

      expect(types.single.name, 'Supper', reason: body);
    }
    final saved = await database.db.query(AppDatabase.cacheTable);
    expect(saved.single['body'], goodJson);
  });

  group('info', () {
    test('says the types came from the server, with the time', () async {
      final info = await repositoryWith(
        () async => http.Response(goodJson, 200),
      ).getInfo();

      expect(info.source, RecipeTypesSource.server);
      expect(info.count, 1);
      expect(info.updatedAt, isNotNull);
    });

    test('says a saved copy was used, with when it was saved', () async {
      await repositoryWith(() async => http.Response(goodJson, 200)).getAll();

      final info = await repositoryWith(offline).getInfo();

      expect(info.source, RecipeTypesSource.savedCopy);
      expect(info.updatedAt, isNotNull);
    });

    test('says the bundled file was used when nothing is saved', () async {
      final info = await repositoryWith(offline).getInfo();

      expect(info.source, RecipeTypesSource.bundled);
      expect(info.updatedAt, isNull);
    });

    test('refresh tells listeners that a new list is ready', () async {
      final repository = repositoryWith(
        () async => http.Response(goodJson, 200),
      );
      var announced = 0;
      final subscription = repository.refreshed.listen((_) => announced++);
      addTearDown(subscription.cancel);

      await repository.refresh();
      await pumpEventQueue();

      expect(announced, 1);
    });

    test('refresh tries the server again', () async {
      var online = false;
      final repository = repositoryWith(
        () async => online
            ? http.Response(goodJson, 200)
            : throw http.ClientException('No internet'),
      );
      expect((await repository.getInfo()).source, RecipeTypesSource.bundled);

      online = true;
      final info = await repository.refresh();

      expect(info.source, RecipeTypesSource.server);
      expect((await repository.getAll()).single.name, 'Supper');
    });
  });
}

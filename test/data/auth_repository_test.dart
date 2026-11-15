import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_app/data/local/app_database.dart';
import 'package:recipe_app/data/local/password_hasher.dart';
import 'package:recipe_app/data/repositories/auth_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/fakes.dart';

void main() {
  late AppDatabase database;
  late FakeSessionStore session;
  late SqliteAuthRepository repository;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    database = await AppDatabase.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    session = FakeSessionStore();
    repository = SqliteAuthRepository(db: database.db, sessionStore: session);
  });

  tearDown(() => database.close());

  group('PasswordHasher', () {
    test('verifies the right password only', () {
      final salt = PasswordHasher.newSalt();
      final hash = PasswordHasher.hash('secret1', salt);

      expect(PasswordHasher.verify('secret1', salt: salt, hash: hash), isTrue);
      expect(PasswordHasher.verify('secret2', salt: salt, hash: hash), isFalse);
    });

    test('the same password gets a different hash with a new salt', () {
      final first = PasswordHasher.hash('secret1', PasswordHasher.newSalt());
      final second = PasswordHasher.hash('secret1', PasswordHasher.newSalt());

      expect(first, isNot(second));
    });
  });

  test('register stores a hash, not the password, and logs in', () async {
    final user = await repository.register('  Cook ', 'secret1');

    expect(user.username, 'Cook');
    expect(session.userId, user.id);
    final row = (await database.db.query(AppDatabase.usersTable)).single;
    expect(row.values, isNot(contains('secret1')));
  });

  test('usernames are unique regardless of case', () async {
    await repository.register('Cook', 'secret1');

    expect(
      repository.register('cook', 'another1'),
      throwsA(isA<AuthException>()),
    );
  });

  test('login accepts the right password and rejects others', () async {
    await repository.register('Cook', 'secret1');
    await repository.logout();

    expect(
      repository.login('Cook', 'wrong-password'),
      throwsA(isA<AuthException>()),
    );
    expect(
      repository.login('nobody', 'secret1'),
      throwsA(isA<AuthException>()),
    );
    final user = await repository.login('cook', 'secret1');
    expect(user.username, 'Cook');
    expect(session.userId, user.id);
  });

  test('the session survives a restart until logout', () async {
    final user = await repository.register('Cook', 'secret1');

    // A new repository reads the same stores, like the next app launch.
    final restarted = SqliteAuthRepository(
      db: database.db,
      sessionStore: session,
    );
    expect((await restarted.restoreSession())?.id, user.id);

    await restarted.logout();
    expect(await restarted.restoreSession(), isNull);
  });

  test('a session for a deleted account is cleared', () async {
    session.userId = 99;

    expect(await repository.restoreSession(), isNull);
    expect(session.userId, isNull);
  });
}

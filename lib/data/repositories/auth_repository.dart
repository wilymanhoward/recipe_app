import 'package:sqflite/sqflite.dart';

import '../../models/user.dart';
import '../local/app_database.dart';
import '../local/password_hasher.dart';
import '../local/session_store.dart';

/// A login or sign-up problem the user can fix; [message] is shown as is.
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => 'AuthException: $message';
}

abstract interface class AuthRepository {
  /// The user from the saved session, or null when logged out.
  Future<User?> restoreSession();

  /// Creates an account and logs it in. Throws [AuthException].
  Future<User> register(String username, String password);

  /// Throws [AuthException] when the details are wrong.
  Future<User> login(String username, String password);

  Future<void> logout();
}

/// Local accounts: users live in SQLite, the session in [SessionStore].
class SqliteAuthRepository implements AuthRepository {
  SqliteAuthRepository({required this._db, required this._sessionStore});

  final Database _db;
  final SessionStore _sessionStore;

  @override
  Future<User?> restoreSession() async {
    final userId = await _sessionStore.readUserId();
    if (userId == null) return null;
    final rows = await _db.query(
      AppDatabase.usersTable,
      where: 'id = ?',
      whereArgs: [userId],
    );
    if (rows.isEmpty) {
      // The account no longer exists, so the session is useless.
      await _sessionStore.clear();
      return null;
    }
    return _toUser(rows.single);
  }

  @override
  Future<User> register(String username, String password) async {
    final name = username.trim();
    final salt = PasswordHasher.newSalt();
    final int id;
    try {
      id = await _db.insert(AppDatabase.usersTable, {
        'username': name,
        'password_hash': PasswordHasher.hash(password, salt),
        'salt': salt,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
    } on DatabaseException catch (error) {
      if (error.isUniqueConstraintError()) {
        throw const AuthException('That username is already taken.');
      }
      rethrow;
    }
    await _sessionStore.saveUserId(id);
    return User(id: id, username: name);
  }

  @override
  Future<User> login(String username, String password) async {
    final rows = await _db.query(
      AppDatabase.usersTable,
      where: 'username = ?',
      whereArgs: [username.trim()],
    );
    final row = rows.firstOrNull;
    final matches =
        row != null &&
        PasswordHasher.verify(
          password,
          salt: row['salt']! as String,
          hash: row['password_hash']! as String,
        );
    // Same message either way, so it doesn't reveal which usernames exist.
    if (!matches) {
      throw const AuthException('Wrong username or password.');
    }
    final user = _toUser(row);
    await _sessionStore.saveUserId(user.id);
    return user;
  }

  @override
  Future<void> logout() => _sessionStore.clear();

  static User _toUser(Map<String, Object?> row) {
    return User(id: row['id']! as int, username: row['username']! as String);
  }
}

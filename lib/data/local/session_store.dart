import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Remembers who is logged in between app launches.
abstract interface class SessionStore {
  Future<int?> readUserId();

  Future<void> saveUserId(int userId);

  Future<void> clear();
}

/// Keeps the session encrypted with the Android Keystore / iOS Keychain,
/// so other apps and backups can't read it.
class SecureSessionStore implements SessionStore {
  SecureSessionStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _userIdKey = 'session_user_id';

  final FlutterSecureStorage _storage;

  @override
  Future<int?> readUserId() async {
    try {
      return int.tryParse(await _storage.read(key: _userIdKey) ?? '');
    } catch (error) {
      // e.g. the Keystore key was lost after a restore: ask to log in again
      // rather than crash on start-up.
      debugPrint('Could not read the session: $error');
      return null;
    }
  }

  @override
  Future<void> saveUserId(int userId) {
    return _storage.write(key: _userIdKey, value: '$userId');
  }

  @override
  Future<void> clear() => _storage.delete(key: _userIdKey);
}

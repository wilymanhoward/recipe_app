import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Salted SHA-256 password hashing. Only the salt and the hash are stored,
/// never the password itself.
///
/// shortcut: one round of SHA-256 is fast, so a stolen database could be
/// brute-forced; a real backend should use a slow hash (bcrypt, scrypt or
/// Argon2) on the server.
abstract final class PasswordHasher {
  static final Random _random = Random.secure();

  /// A random salt, different for every user, so two users with the same
  /// password get different hashes.
  static String newSalt() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return base64Url.encode(bytes);
  }

  static String hash(String password, String salt) {
    return sha256.convert(utf8.encode('$salt:$password')).toString();
  }

  static bool verify(
    String password, {
    required String salt,
    required String hash,
  }) {
    final actual = PasswordHasher.hash(password, salt);
    if (actual.length != hash.length) return false;
    // Compares every character, so timing doesn't reveal how much matched.
    var difference = 0;
    for (var i = 0; i < actual.length; i++) {
      difference |= actual.codeUnitAt(i) ^ hash.codeUnitAt(i);
    }
    return difference == 0;
  }
}

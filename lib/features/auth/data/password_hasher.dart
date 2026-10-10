import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Salted SHA-256 for the local demo accounts.
///
/// This only avoids storing demo passwords as plain text in the local file.
/// It is not a security boundary: everything runs on the user's device, and
/// a fast hash such as SHA-256 is not suitable for real passwords. A server
/// version must hash with Argon2id (or bcrypt/scrypt) on the server.
class PasswordHasher {
  const PasswordHasher();

  String newSalt([Random? random]) {
    final generator = random ?? Random.secure();
    final bytes = List.generate(16, (_) => generator.nextInt(256));
    return base64UrlEncode(bytes);
  }

  String hash(String password, String salt) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();

  /// Compares in constant time, so the check does not leak how many
  /// characters matched.
  bool verify(String password, String salt, String expectedHash) {
    final actual = hash(password, salt);
    if (actual.length != expectedHash.length) return false;
    var difference = 0;
    for (var i = 0; i < actual.length; i++) {
      difference |= actual.codeUnitAt(i) ^ expectedHash.codeUnitAt(i);
    }
    return difference == 0;
  }
}

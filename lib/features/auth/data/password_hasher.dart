import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

// Кирилл: соль + sha256 только чтобы не держать пароли открытым текстом в json.
// Это демо-вход, на сервере будет нормальная авторизация
class PasswordHasher {
  const PasswordHasher();

  String newSalt([Random? random]) {
    final generator = random ?? Random.secure();
    final bytes = List.generate(16, (_) => generator.nextInt(256));
    return base64UrlEncode(bytes);
  }

  String hash(String password, String salt) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();

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

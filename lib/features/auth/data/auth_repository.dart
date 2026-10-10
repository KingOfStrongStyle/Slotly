import '../../../data/local/app_database.dart';
import '../domain/app_user.dart';
import 'password_hasher.dart';

class InvalidCredentialsException implements Exception {
  const InvalidCredentialsException();

  @override
  String toString() => 'InvalidCredentialsException';
}

/// Sign-in contract. A server implementation will exchange credentials for
/// access and refresh tokens; screens do not change.
abstract interface class AuthRepository {
  /// Throws [InvalidCredentialsException] for a wrong login or password.
  /// The error does not say which one was wrong.
  Future<AppUser> signIn(String login, String password);

  /// The user of the previous session, or `null`.
  Future<AppUser?> restoreSession();

  Future<void> signOut();
}

/// Demo sign-in against accounts stored in the local database.
class LocalAuthRepository implements AuthRepository {
  const LocalAuthRepository(this._database, {PasswordHasher? hasher})
    : _hasher = hasher ?? const PasswordHasher();

  final AppDatabase _database;
  final PasswordHasher _hasher;

  @override
  Future<AppUser> signIn(String login, String password) async {
    final normalized = normalizeLogin(login);
    final tables = _database.tables;
    final user = tables.users.values
        .where((u) => u.login == normalized)
        .firstOrNull;
    final credential = user == null ? null : tables.credentials[user.id];
    if (user == null ||
        credential == null ||
        !_hasher.verify(password, credential.salt, credential.hash)) {
      throw const InvalidCredentialsException();
    }
    await _database.update((t) => t.settings.sessionUserId = user.id);
    return user;
  }

  @override
  Future<AppUser?> restoreSession() async {
    final tables = _database.tables;
    final id = tables.settings.sessionUserId;
    return id == null ? null : tables.users[id];
  }

  @override
  Future<void> signOut() =>
      _database.update((t) => t.settings.sessionUserId = null);

  static String normalizeLogin(String login) => login.trim().toLowerCase();
}

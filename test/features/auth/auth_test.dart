import 'package:flutter_test/flutter_test.dart';
import 'package:slotly/data/local/app_database.dart';
import 'package:slotly/data/local/database_storage.dart';
import 'package:slotly/data/seed/demo_accounts.dart';
import 'package:slotly/data/seed/demo_seed.dart';
import 'package:slotly/features/auth/data/auth_repository.dart';
import 'package:slotly/features/auth/data/password_hasher.dart';
import 'package:slotly/features/auth/presentation/session_controller.dart';

void main() {
  late MemoryDatabaseStorage storage;
  late AppDatabase database;
  late SessionController session;

  setUp(() async {
    storage = MemoryDatabaseStorage();
    database = await AppDatabase.open(storage);
    await DemoSeed(
      clock: () => DateTime(2026, 10, 5, 9),
      withActivity: false,
    ).apply(database);
    session = SessionController(LocalAuthRepository(database));
  });

  for (final account in demoAccounts) {
    test('signs in ${account.user.login} with the demo password', () async {
      final user = await session.signIn(account.user.login, account.password);
      expect(user, account.user);
      expect(user.role, account.user.role);
      expect(session.currentUser, account.user);
    });
  }

  test('login ignores case and surrounding spaces', () async {
    final user = await session.signIn('  ALIYA ', 'aliya-demo');
    expect(user.id, clientAliyaId);
  });

  test('wrong password and unknown login give the same error', () async {
    await expectLater(
      session.signIn('aliya', 'wrong'),
      throwsA(isA<InvalidCredentialsException>()),
    );
    await expectLater(
      session.signIn('nobody', 'aliya-demo'),
      throwsA(isA<InvalidCredentialsException>()),
    );
    await expectLater(
      session.signIn('aliya', ''),
      throwsA(isA<InvalidCredentialsException>()),
    );
    expect(session.currentUser, isNull);
  });

  test('the session is restored after a restart', () async {
    await session.signIn('north', 'north-demo');
    await database.flush();

    final reopened = await AppDatabase.open(storage);
    final restored = SessionController(LocalAuthRepository(reopened));
    expect(restored.isRestored, isFalse);
    await restored.restore();

    expect(restored.isRestored, isTrue);
    expect(restored.currentUser?.id, ownerNorthId);
    expect(restored.currentUser?.organizationId, isNotNull);
  });

  test('sign-out forgets the session after a restart', () async {
    await session.signIn('aliya', 'aliya-demo');
    await session.signOut();
    expect(session.currentUser, isNull);
    await database.flush();

    final restored = SessionController(
      LocalAuthRepository(await AppDatabase.open(storage)),
    );
    await restored.restore();
    expect(restored.currentUser, isNull);
  });

  test('passwords are not stored as plain text', () async {
    final raw = storage.contents!;
    for (final account in demoAccounts) {
      expect(raw, isNot(contains(account.password)));
    }
    final credential = database.tables.credentials[clientAliyaId]!;
    expect(credential.hash, hasLength(64));
    expect(credential.salt, isNotEmpty);
  });

  test('hasher verifies only the original password', () {
    const hasher = PasswordHasher();
    final salt = hasher.newSalt();
    final hash = hasher.hash('secret', salt);

    expect(hasher.verify('secret', salt, hash), isTrue);
    expect(hasher.verify('Secret', salt, hash), isFalse);
    expect(hasher.verify('secret', hasher.newSalt(), hash), isFalse);
    expect(hasher.verify('secret', salt, 'short'), isFalse);
  });
}

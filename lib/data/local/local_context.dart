import '../../core/access/access_policy.dart';
import '../../core/utils/clock.dart';
import '../../features/auth/domain/app_user.dart';
import 'app_database.dart';

class LocalContext {
  const LocalContext({
    required this.database,
    required this.currentUser,
    required this.clock,
    this.policy = const AccessPolicy(),
  });

  final AppDatabase database;
  final CurrentUser currentUser;
  final Clock clock;
  final AccessPolicy policy;

  AppUser? get user => currentUser();

  void require(
    AppAction action, {
    String? organizationId,
    String? resourceOwnerId,
  }) => policy.require(
    user,
    action,
    organizationId: organizationId,
    resourceOwnerId: resourceOwnerId,
  );
}

class RecordNotFoundException implements Exception {
  const RecordNotFoundException(this.what, this.id);

  final String what;
  final String id;

  @override
  String toString() => 'RecordNotFoundException($what $id)';
}

class ValidationException<T extends Enum> implements Exception {
  const ValidationException(this.issues);

  final List<T> issues;

  @override
  String toString() => 'ValidationException($issues)';
}

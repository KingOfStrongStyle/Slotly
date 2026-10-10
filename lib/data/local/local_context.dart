import '../../core/access/access_policy.dart';
import '../../core/utils/clock.dart';
import '../../features/auth/domain/app_user.dart';
import 'app_database.dart';

/// What every local repository needs: the data, the permission rules, the
/// signed-in user and the current time.
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

/// The requested record does not exist or is not visible to the user.
/// Records of other tenants are reported the same way as missing ones.
class RecordNotFoundException implements Exception {
  const RecordNotFoundException(this.what, this.id);

  final String what;
  final String id;

  @override
  String toString() => 'RecordNotFoundException($what $id)';
}

/// Input broke a validation rule; [issues] are enum values of the
/// corresponding draft class.
class ValidationException<T extends Enum> implements Exception {
  const ValidationException(this.issues);

  final List<T> issues;

  @override
  String toString() => 'ValidationException($issues)';
}

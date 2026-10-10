enum UserRole { client, owner }

/// Signed-in person. Passwords are not part of the user: the demo
/// credentials live separately in the local database.
class AppUser {
  const AppUser({
    required this.id,
    required this.login,
    required this.displayName,
    required this.role,
    this.organizationId,
  }) : assert(
         (role == UserRole.owner) == (organizationId != null),
         'Only owners belong to an organization',
       );

  final String id;
  final String login;
  final String displayName;
  final UserRole role;

  /// The organization an owner manages; `null` for clients.
  final String? organizationId;

  bool get isClient => role == UserRole.client;
  bool get isOwner => role == UserRole.owner;

  bool ownsOrganization(String id) => isOwner && organizationId == id;

  @override
  bool operator ==(Object other) => other is AppUser && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'AppUser($id, ${role.name})';
}

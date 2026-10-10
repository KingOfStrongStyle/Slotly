/// A customer saved an organization to come back to it later.
///
/// One record per (customer, organization); removing the favorite deletes
/// it. [createdAt] feeds the "added to favorites" metric of the owner.
class Favorite {
  const Favorite({
    required this.userId,
    required this.organizationId,
    required this.createdAt,
  });

  final String userId;
  final String organizationId;
  final DateTime createdAt;

  String get key => keyFor(userId, organizationId);

  static String keyFor(String userId, String organizationId) =>
      '$userId|$organizationId';
}

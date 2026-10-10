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

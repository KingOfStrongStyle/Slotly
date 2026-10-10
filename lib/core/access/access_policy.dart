import '../../features/auth/domain/app_user.dart';

/// Every operation that needs a permission check.
///
/// Client actions work with the client's own records; owner actions work
/// with the records of the owner's organization.
enum AppAction {
  // Everyone, including a guest.
  browseCatalog,

  // Client.
  toggleFavorite,
  createBooking,
  viewOwnBookings,
  changeOwnBooking,
  checkInOwnBooking,
  writeReview,
  editOwnReview,

  // Owner, only for their own organization.
  viewDashboard,
  viewOrganizationBookings,
  manageOrganizationBookings,
  editOrganization,
  managePhotos,
  manageServices,
  viewOrganizationReviews,
  replyToReview,
}

enum AccessScope { everyone, client, owner }

extension AppActionScope on AppAction {
  AccessScope get scope => switch (this) {
    AppAction.browseCatalog => AccessScope.everyone,
    AppAction.toggleFavorite ||
    AppAction.createBooking ||
    AppAction.viewOwnBookings ||
    AppAction.changeOwnBooking ||
    AppAction.checkInOwnBooking ||
    AppAction.writeReview ||
    AppAction.editOwnReview => AccessScope.client,
    AppAction.viewDashboard ||
    AppAction.viewOrganizationBookings ||
    AppAction.manageOrganizationBookings ||
    AppAction.editOrganization ||
    AppAction.managePhotos ||
    AppAction.manageServices ||
    AppAction.viewOrganizationReviews ||
    AppAction.replyToReview => AccessScope.owner,
  };
}

class AccessDeniedException implements Exception {
  const AccessDeniedException(this.action, this.reason);

  final AppAction action;
  final String reason;

  @override
  String toString() => 'AccessDeniedException(${action.name}: $reason)';
}

/// The permission matrix of Slotly in one place.
///
/// Repositories call [require] before every read of private data and every
/// change, so a hidden button is never the only protection. The UI calls
/// [can] to decide what to show. On a server the same rules become
/// permission classes and queryset filters.
class AccessPolicy {
  const AccessPolicy();

  /// [organizationId] — organization that owns the resource;
  /// [resourceOwnerId] — client who owns the resource (booking, review).
  bool can(
    AppUser? user,
    AppAction action, {
    String? organizationId,
    String? resourceOwnerId,
  }) => _denialReason(user, action, organizationId, resourceOwnerId) == null;

  /// Throws [AccessDeniedException] when [can] would return false.
  void require(
    AppUser? user,
    AppAction action, {
    String? organizationId,
    String? resourceOwnerId,
  }) {
    final reason = _denialReason(user, action, organizationId, resourceOwnerId);
    if (reason != null) throw AccessDeniedException(action, reason);
  }

  String? _denialReason(
    AppUser? user,
    AppAction action,
    String? organizationId,
    String? resourceOwnerId,
  ) {
    switch (action.scope) {
      case AccessScope.everyone:
        return null;
      case AccessScope.client:
        if (user == null) return 'sign-in required';
        if (!user.isClient) return 'only customers can do this';
        if (resourceOwnerId != null && resourceOwnerId != user.id) {
          return 'the record belongs to another customer';
        }
        return null;
      case AccessScope.owner:
        if (user == null) return 'sign-in required';
        if (!user.isOwner) return 'only business owners can do this';
        if (organizationId == null) return 'organization is not specified';
        if (!user.ownsOrganization(organizationId)) {
          return 'the record belongs to another organization';
        }
        return null;
    }
  }
}

/// Returns the signed-in user. Repositories receive this function instead
/// of the session object, just like a server reads the user from a token.
typedef CurrentUser = AppUser? Function();

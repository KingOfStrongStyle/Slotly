import '../../features/auth/domain/app_user.dart';

enum AppAction {
  browseCatalog,

  toggleFavorite,
  createBooking,
  viewOwnBookings,
  changeOwnBooking,
  checkInOwnBooking,
  writeReview,
  editOwnReview,

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

// Кирилл: одна таблица прав на всё приложение. UI только прячет кнопки,
// а реальная проверка - require() в каждом методе репозитория
class AccessPolicy {
  const AccessPolicy();

  bool can(
    AppUser? user,
    AppAction action, {
    String? organizationId,
    String? resourceOwnerId,
  }) => _denialReason(user, action, organizationId, resourceOwnerId) == null;

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

typedef CurrentUser = AppUser? Function();

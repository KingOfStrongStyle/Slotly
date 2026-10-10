import 'package:flutter_test/flutter_test.dart';
import 'package:slotly/core/access/access_policy.dart';
import 'package:slotly/data/seed/demo_accounts.dart';
import 'package:slotly/data/seed/demo_catalog.dart';
import 'package:slotly/features/auth/domain/app_user.dart';

import '../../helpers/test_app.dart';

/// The permission matrix as a table: every action × every kind of actor.
///
/// Client actions are checked on a record of Aliya; owner actions on the
/// organization "Северный". "own" and "other" columns show that ownership
/// of the record matters, not only the role.
void main() {
  const policy = AccessPolicy();
  final aliya = userOf('aliya');
  final damir = userOf('damir');
  final ownerNorth = userOf('north');
  final ownerWhiteLine = userOf('whiteline');

  final actors = <String, AppUser?>{
    'guest': null,
    'client (own record)': aliya,
    'client (other record)': damir,
    'owner (own organization)': ownerNorth,
    'owner (other organization)': ownerWhiteLine,
  };

  // Expected results in the order of [actors].
  const matrix = <AppAction, List<bool>>{
    AppAction.browseCatalog: [true, true, true, true, true],
    AppAction.toggleFavorite: [false, true, true, false, false],
    AppAction.createBooking: [false, true, true, false, false],
    AppAction.viewOwnBookings: [false, true, true, false, false],
    AppAction.changeOwnBooking: [false, true, false, false, false],
    AppAction.checkInOwnBooking: [false, true, false, false, false],
    AppAction.writeReview: [false, true, false, false, false],
    AppAction.editOwnReview: [false, true, false, false, false],
    AppAction.viewDashboard: [false, false, false, true, false],
    AppAction.viewOrganizationBookings: [false, false, false, true, false],
    AppAction.manageOrganizationBookings: [false, false, false, true, false],
    AppAction.editOrganization: [false, false, false, true, false],
    AppAction.managePhotos: [false, false, false, true, false],
    AppAction.manageServices: [false, false, false, true, false],
    AppAction.viewOrganizationReviews: [false, false, false, true, false],
    AppAction.replyToReview: [false, false, false, true, false],
  };

  test('the matrix lists every action', () {
    expect(matrix.keys.toSet(), AppAction.values.toSet());
  });

  for (final MapEntry(key: action, value: expected) in matrix.entries) {
    final names = actors.keys.toList();
    for (var i = 0; i < names.length; i++) {
      final actor = actors[names[i]];
      test(
        '${action.name} — ${names[i]}: ${expected[i] ? 'allowed' : 'denied'}',
        () {
          // Client-scoped actions without a record (e.g. createBooking) ignore
          // the owner id, so "other record" is the same as "own" there.
          final isRecordAction = action.scope == AccessScope.client;
          final allowed = policy.can(
            actor,
            action,
            organizationId: orgNorth,
            resourceOwnerId:
                isRecordAction &&
                    !{
                      AppAction.toggleFavorite,
                      AppAction.createBooking,
                      AppAction.viewOwnBookings,
                    }.contains(action)
                ? aliya.id
                : null,
          );
          expect(allowed, expected[i]);
          if (!expected[i]) {
            expect(
              () => policy.require(
                actor,
                action,
                organizationId: orgNorth,
                resourceOwnerId: aliya.id,
              ),
              throwsA(isA<AccessDeniedException>()),
            );
          }
        },
      );
    }
  }

  test('owner actions without an organization are denied', () {
    expect(policy.can(ownerNorth, AppAction.viewDashboard), isFalse);
  });

  test('demo owners manage exactly their organizations', () {
    expect(ownerNorth.ownsOrganization(orgNorth), isTrue);
    expect(ownerNorth.ownsOrganization(orgWhiteLine), isFalse);
    expect(ownerWhiteLine.ownsOrganization(orgWhiteLine), isTrue);
    expect(aliya.ownsOrganization(orgNorth), isFalse);
    expect(clientAliyaId, aliya.id);
  });
}

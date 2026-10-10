import 'package:flutter_test/flutter_test.dart';
import 'package:slotly/data/local/local_context.dart';
import 'package:slotly/data/seed/demo_catalog.dart';
import 'package:slotly/features/favorites/data/favorites_repository.dart';

import '../../helpers/test_app.dart';

void main() {
  late TestData data;
  late LocalFavoritesRepository favorites;

  setUp(() async {
    data = await TestData.create();
    favorites = LocalFavoritesRepository(data.context);
    data.signInAs('aliya');
  });

  test('toggle adds and removes one organization', () async {
    expect(await favorites.toggle(orgNorth), isTrue);
    expect(await favorites.fetchFavoriteIds(), {orgNorth});
    final favorite = data.database.tables.favorites.values.single;
    expect(favorite.createdAt, testNow);

    expect(await favorites.toggle(orgNorth), isFalse);
    expect(await favorites.fetchFavoriteIds(), isEmpty);
  });

  test('favorites are per customer', () async {
    await favorites.toggle(orgNorth);
    data.signInAs('damir');
    expect(await favorites.fetchFavoriteIds(), isEmpty);
    await favorites.toggle(orgGarage);
    data.signInAs('aliya');
    expect(await favorites.fetchFavoriteIds(), {orgNorth});
  });

  test('owners and guests have no favorites', () async {
    data.signInAs('north');
    expect(await favorites.fetchFavoriteIds(), isEmpty);
    data.signInAs(null);
    expect(await favorites.fetchFavoriteIds(), isEmpty);
  });

  test('an unknown organization cannot be added', () {
    expect(
      () => favorites.toggle('org-missing'),
      throwsA(isA<RecordNotFoundException>()),
    );
  });
}

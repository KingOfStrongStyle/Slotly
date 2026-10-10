import 'package:flutter/foundation.dart';

import '../../../core/access/access_policy.dart';
import '../../../data/local/local_context.dart';
import '../domain/favorite.dart';

abstract interface class FavoritesRepository {
  Listenable get changes;

  Future<Set<String>> fetchFavoriteIds();

  Future<bool> toggle(String organizationId);
}

class LocalFavoritesRepository implements FavoritesRepository {
  const LocalFavoritesRepository(this._context);

  final LocalContext _context;

  @override
  Listenable get changes => _context.database;

  @override
  Future<Set<String>> fetchFavoriteIds() async {
    final user = _context.user;
    if (user == null || !user.isClient) return const {};
    return {
      for (final favorite in _context.database.tables.favorites.values)
        if (favorite.userId == user.id) favorite.organizationId,
    };
  }

  @override
  Future<bool> toggle(String organizationId) async {
    _context.require(AppAction.toggleFavorite);
    if (!_context.database.tables.organizations.containsKey(organizationId)) {
      throw RecordNotFoundException('organization', organizationId);
    }
    final userId = _context.user!.id;
    final key = Favorite.keyFor(userId, organizationId);
    return _context.database.update((t) {
      if (t.favorites.remove(key) != null) return false;
      t.favorites[key] = Favorite(
        userId: userId,
        organizationId: organizationId,
        createdAt: _context.clock(),
      );
      return true;
    });
  }
}

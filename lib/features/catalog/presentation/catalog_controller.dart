import 'package:flutter/foundation.dart';

import '../../../core/state/live_query.dart';
import '../../favorites/data/favorites_repository.dart';
import '../../reviews/data/review_repository.dart';
import '../../reviews/domain/rating_summary.dart';
import '../data/catalog_repository.dart';
import '../domain/organization.dart';
import '../domain/service.dart';

class CatalogData {
  const CatalogData({
    required this.organizations,
    required this.services,
    required this.ratings,
    required this.covers,
    required this.favoriteIds,
  });

  final List<Organization> organizations;
  final List<Service> services;

  final Map<String, RatingSummary> ratings;

  final Map<String, BusinessPhoto> covers;
  final Set<String> favoriteIds;

  RatingSummary ratingOf(String organizationId) =>
      ratings[organizationId] ?? RatingSummary.empty;

  Organization? organizationOf(String id) =>
      organizations.where((o) => o.id == id).firstOrNull;

  bool isFavorite(String organizationId) =>
      favoriteIds.contains(organizationId);
}

class CatalogController extends LiveQuery<CatalogData> {
  CatalogController({
    required CatalogRepository catalog,
    required ReviewRepository reviews,
    required FavoritesRepository favorites,
  }) : _favorites = favorites,
       super(
         () => _load(catalog, reviews, favorites),
         refreshOn: Listenable.merge([
           catalog.changes,
           reviews.changes,
           favorites.changes,
         ]),
       );

  final FavoritesRepository _favorites;

  Future<bool> toggleFavorite(String organizationId) =>
      _favorites.toggle(organizationId);

  static Future<CatalogData> _load(
    CatalogRepository catalog,
    ReviewRepository reviews,
    FavoritesRepository favorites,
  ) async {
    final organizations = await catalog.fetchOrganizations();
    final ratings = <String, RatingSummary>{};
    final covers = <String, BusinessPhoto>{};
    for (final organization in organizations) {
      ratings[organization.id] = RatingSummary.of(
        await reviews.fetchOrganizationReviews(organization.id),
      );
      final photos = await catalog.fetchPhotos(organization.id);
      if (photos.isNotEmpty) covers[organization.id] = photos.first;
    }
    return CatalogData(
      organizations: organizations,
      services: await catalog.fetchServices(),
      ratings: ratings,
      covers: covers,
      favoriteIds: await favorites.fetchFavoriteIds(),
    );
  }
}

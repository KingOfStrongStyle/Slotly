import 'package:flutter/foundation.dart';

import '../../../core/access/access_policy.dart';
import '../../../data/local/local_context.dart';
import '../domain/analytics_calculator.dart';
import '../domain/owner_analytics.dart';

abstract interface class AnalyticsRepository {
  Listenable get changes;

  Future<OwnerAnalytics> fetch(String organizationId, AnalyticsPeriod period);
}

class LocalAnalyticsRepository implements AnalyticsRepository {
  LocalAnalyticsRepository(this._context);

  final LocalContext _context;
  // Влад: кэш по ревизии базы: пока данные не менялись, при переключении
  // 7/30/90 не пересчитываем
  final Map<(String, AnalyticsPeriod), (int, OwnerAnalytics)> _cache = {};

  @override
  Listenable get changes => _context.database;

  @override
  Future<OwnerAnalytics> fetch(
    String organizationId,
    AnalyticsPeriod period,
  ) async {
    _context.require(AppAction.viewDashboard, organizationId: organizationId);
    final revision = _context.database.revision;
    final key = (organizationId, period);
    final cached = _cache[key];
    final now = _context.clock();
    if (cached != null &&
        cached.$1 == revision &&
        cached.$2.to.day == now.day &&
        now.difference(cached.$2.to) < const Duration(minutes: 5)) {
      return cached.$2;
    }
    final tables = _context.database.tables;
    final result = AnalyticsCalculator.calculate(
      period: period,
      now: now,
      bookings: tables.bookings.values.where(
        (b) => b.organizationId == organizationId,
      ),
      reviews: tables.reviews.values.where(
        (r) => r.organizationId == organizationId,
      ),
      favorites: tables.favorites.values.where(
        (f) => f.organizationId == organizationId,
      ),
    );
    _cache[key] = (revision, result);
    return result;
  }
}

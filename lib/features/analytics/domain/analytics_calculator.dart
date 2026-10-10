import '../../../core/utils/clock.dart';
import '../../booking/domain/booking.dart';
import '../../favorites/domain/favorite.dart';
import '../../reviews/domain/review.dart';
import 'owner_analytics.dart';

/// Turns raw records of ONE organization into dashboard numbers.
///
/// Pure Dart: no Flutter, no storage, so every formula is unit-tested on
/// small hand-made data sets. The caller (the repository) is responsible
/// for passing only records of the organization the owner manages.
///
/// Formulas:
/// * period = from 00:00 of the day `N-1` days ago until now;
/// * bookings = visits with `startAt` in the period, any status;
/// * cancellation rate = cancelled / bookings (null when bookings = 0);
/// * average rating = mean of reviews created in the period;
/// * top specialist / service = most non-cancelled bookings, ties by name;
/// * series = the same counts split by day (7, 30) or by week (90).
abstract final class AnalyticsCalculator {
  static OwnerAnalytics calculate({
    required AnalyticsPeriod period,
    required DateTime now,
    required Iterable<Booking> bookings,
    required Iterable<Review> reviews,
    required Iterable<Favorite> favorites,
  }) {
    final today = now.dateOnly;
    final from = today.subtract(Duration(days: period.days - 1));
    bool inPeriod(DateTime moment) =>
        !moment.isBefore(from) && !moment.isAfter(now);

    final periodBookings = [
      for (final b in bookings)
        if (inPeriod(b.startAt)) b,
    ];
    final periodReviews = [
      for (final r in reviews)
        if (inPeriod(r.createdAt)) r,
    ];
    final periodFavorites = [
      for (final f in favorites)
        if (inPeriod(f.createdAt)) f,
    ];
    final allReviews = reviews.toList();

    final statusCounts = {
      for (final status in BookingStatus.values)
        status: periodBookings.where((b) => b.status == status).length,
    };
    final cancelled = statusCounts[BookingStatus.cancelled]!;
    final visits = periodBookings.where((b) => !b.isCancelled);
    final bySpecialist = _countBy(visits.map((b) => b.specialist.name));
    final byService = _countBy(visits.map((b) => b.serviceTitle));
    final buckets = _buckets(period, from, today);

    return OwnerAnalytics(
      period: period,
      from: from,
      to: now,
      bookings: periodBookings.length,
      completed: statusCounts[BookingStatus.completed]!,
      cancelled: cancelled,
      cancellationRate: periodBookings.isEmpty
          ? null
          : cancelled / periodBookings.length,
      averageRating: _average(periodReviews),
      overallRating: _average(allReviews),
      newReviews: periodReviews.length,
      favoritesAdded: periodFavorites.length,
      topSpecialist: bySpecialist.firstOrNull,
      topService: byService.firstOrNull,
      statusCounts: statusCounts,
      bySpecialist: bySpecialist,
      byService: byService,
      bookingsSeries: _series(buckets, periodBookings.map((b) => b.startAt)),
      reviewsSeries: _series(buckets, periodReviews.map((r) => r.createdAt)),
      favoritesSeries: _series(
        buckets,
        periodFavorites.map((f) => f.createdAt),
      ),
    );
  }

  static double? _average(List<Review> reviews) => reviews.isEmpty
      ? null
      : reviews.fold(0, (sum, r) => sum + r.rating) / reviews.length;

  /// Counts by name, most frequent first; equal counts sorted by name so
  /// the order (and the "top" item) is stable.
  static List<NamedCount> _countBy(Iterable<String> names) {
    final counts = <String, int>{};
    for (final name in names) {
      counts[name] = (counts[name] ?? 0) + 1;
    }
    return [
      for (final entry in counts.entries) NamedCount(entry.key, entry.value),
    ]..sort((a, b) {
      final byCount = b.count.compareTo(a.count);
      return byCount != 0 ? byCount : a.name.compareTo(b.name);
    });
  }

  /// Day or week intervals covering the period, oldest first. Weeks are
  /// counted back from today, so the last bar is always "the last 7 days"
  /// and only the oldest one may be shorter.
  static List<(DateTime, DateTime)> _buckets(
    AnalyticsPeriod period,
    DateTime from,
    DateTime today,
  ) {
    final size = period.groupsByWeek ? 7 : 1;
    final result = <(DateTime, DateTime)>[];
    var end = today;
    while (!end.isBefore(from)) {
      var start = end.subtract(Duration(days: size - 1));
      if (start.isBefore(from)) start = from;
      result.add((start, end));
      end = start.subtract(const Duration(days: 1));
    }
    return result.reversed.toList();
  }

  static List<TimeBucket> _series(
    List<(DateTime, DateTime)> buckets,
    Iterable<DateTime> moments,
  ) {
    final counts = List.filled(buckets.length, 0);
    for (final moment in moments) {
      final day = moment.dateOnly;
      for (var i = 0; i < buckets.length; i++) {
        final (start, end) = buckets[i];
        if (!day.isBefore(start) && !day.isAfter(end)) {
          counts[i]++;
          break;
        }
      }
    }
    return [
      for (var i = 0; i < buckets.length; i++)
        TimeBucket(start: buckets[i].$1, end: buckets[i].$2, value: counts[i]),
    ];
  }
}

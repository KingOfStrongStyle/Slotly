import '../../booking/domain/booking.dart';

/// Period filter of the dashboard.
enum AnalyticsPeriod {
  days7(7),
  days30(30),
  days90(90);

  const AnalyticsPeriod(this.days);

  final int days;

  /// 7 and 30 days are shown per day; 90 days per week, otherwise the
  /// chart would have 90 bars that are too thin to read on a phone.
  bool get groupsByWeek => days > 30;
}

/// One bar of a time chart: an interval and a value.
class TimeBucket {
  const TimeBucket({
    required this.start,
    required this.end,
    required this.value,
  });

  /// First day of the bucket (00:00).
  final DateTime start;

  /// Last day of the bucket (00:00), inclusive.
  final DateTime end;
  final num value;
}

/// A named count, for example bookings of one specialist.
class NamedCount {
  const NamedCount(this.name, this.count);

  final String name;
  final int count;

  @override
  bool operator ==(Object other) =>
      other is NamedCount && other.name == name && other.count == count;

  @override
  int get hashCode => Object.hash(name, count);

  @override
  String toString() => '$name: $count';
}

/// Everything the owner dashboard shows for one organization and period.
/// All numbers are computed from bookings, reviews and favorites by
/// `AnalyticsCalculator`; nothing here is stored.
class OwnerAnalytics {
  const OwnerAnalytics({
    required this.period,
    required this.from,
    required this.to,
    required this.bookings,
    required this.completed,
    required this.cancelled,
    required this.cancellationRate,
    required this.averageRating,
    required this.overallRating,
    required this.newReviews,
    required this.favoritesAdded,
    required this.topSpecialist,
    required this.topService,
    required this.statusCounts,
    required this.bySpecialist,
    required this.byService,
    required this.bookingsSeries,
    required this.reviewsSeries,
    required this.favoritesSeries,
  });

  final AnalyticsPeriod period;

  /// Start of the first day of the period.
  final DateTime from;

  /// Moment of the calculation; future bookings are not counted.
  final DateTime to;

  /// Bookings with a visit time inside the period, any status.
  final int bookings;
  final int completed;
  final int cancelled;

  /// cancelled / bookings; null when there are no bookings (not 0 %).
  final double? cancellationRate;

  /// Mean rating of reviews written in the period; null without reviews.
  final double? averageRating;

  /// Mean rating of all reviews of the organization.
  final double? overallRating;
  final int newReviews;
  final int favoritesAdded;

  /// Most booked specialist and service (cancelled visits not counted);
  /// null when the period has no such bookings.
  final NamedCount? topSpecialist;
  final NamedCount? topService;

  /// Bookings of the period by status.
  final Map<BookingStatus, int> statusCounts;
  final List<NamedCount> bySpecialist;
  final List<NamedCount> byService;

  /// Bookings per day (7/30 days) or per week (90 days).
  final List<TimeBucket> bookingsSeries;

  /// Number of new reviews per bucket.
  final List<TimeBucket> reviewsSeries;

  /// New favorites per bucket.
  final List<TimeBucket> favoritesSeries;

  bool get isEmpty => bookings == 0 && newReviews == 0 && favoritesAdded == 0;
}

import '../../booking/domain/booking.dart';

enum AnalyticsPeriod {
  days7(7),
  days30(30),
  days90(90);

  const AnalyticsPeriod(this.days);

  final int days;

  bool get groupsByWeek => days > 30;
}

class TimeBucket {
  const TimeBucket({
    required this.start,
    required this.end,
    required this.value,
  });

  final DateTime start;

  final DateTime end;
  final num value;
}

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

  final DateTime from;

  final DateTime to;

  final int bookings;
  final int completed;
  final int cancelled;

  final double? cancellationRate;

  final double? averageRating;

  final double? overallRating;
  final int newReviews;
  final int favoritesAdded;

  final NamedCount? topSpecialist;
  final NamedCount? topService;

  final Map<BookingStatus, int> statusCounts;
  final List<NamedCount> bySpecialist;
  final List<NamedCount> byService;

  final List<TimeBucket> bookingsSeries;

  final List<TimeBucket> reviewsSeries;

  final List<TimeBucket> favoritesSeries;

  bool get isEmpty => bookings == 0 && newReviews == 0 && favoritesAdded == 0;
}

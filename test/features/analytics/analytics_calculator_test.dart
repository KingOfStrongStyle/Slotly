import 'package:flutter_test/flutter_test.dart';
import 'package:slotly/data/seed/demo_catalog.dart';
import 'package:slotly/features/analytics/domain/analytics_calculator.dart';
import 'package:slotly/features/analytics/domain/owner_analytics.dart';
import 'package:slotly/features/booking/domain/booking.dart';
import 'package:slotly/features/favorites/domain/favorite.dart';
import 'package:slotly/features/reviews/domain/review.dart';

import '../../helpers/booking_fixtures.dart';

/// Hand-made data with numbers that are easy to check by eye.
void main() {
  final now = DateTime(2026, 10, 5, 15);

  Booking booking(
    String id,
    DateTime startAt, {
    BookingStatus status = BookingStatus.completed,
    String serviceId = 'svc-men-haircut',
  }) => fixtureBooking(
    id: id,
    startAt: startAt,
    status: status,
    serviceId: serviceId,
  );

  Review review(String id, int rating, DateTime createdAt) => Review(
    id: id,
    bookingId: id,
    organizationId: orgNorth,
    serviceId: 'svc-men-haircut',
    serviceTitle: 'Мужская стрижка',
    specialistId: 'sp-arman',
    authorId: 'u',
    authorName: 'u',
    rating: rating,
    text: '',
    createdAt: createdAt,
  );

  Favorite favorite(String user, DateTime at) =>
      Favorite(userId: user, organizationId: orgNorth, createdAt: at);

  OwnerAnalytics calc(
    AnalyticsPeriod period, {
    List<Booking> bookings = const [],
    List<Review> reviews = const [],
    List<Favorite> favorites = const [],
  }) => AnalyticsCalculator.calculate(
    period: period,
    now: now,
    bookings: bookings,
    reviews: reviews,
    favorites: favorites,
  );

  final sample = [
    booking('a', DateTime(2026, 10, 5, 10)),
    booking('b', DateTime(2026, 10, 4, 12)),
    booking('c', DateTime(2026, 10, 4, 14), status: BookingStatus.cancelled),
    booking('d', DateTime(2026, 9, 30, 11), serviceId: 'svc-beard'),
    // Outside 7 days, inside 30.
    booking('e', DateTime(2026, 9, 20, 11), serviceId: 'svc-beard'),
    // Later today: not counted yet.
    booking('f', DateTime(2026, 10, 5, 18), status: BookingStatus.confirmed),
  ];

  test('counts bookings, statuses and the cancellation rate', () {
    final week = calc(AnalyticsPeriod.days7, bookings: sample);
    expect(week.from, DateTime(2026, 9, 29));
    expect(week.bookings, 4);
    expect(week.completed, 3);
    expect(week.cancelled, 1);
    expect(week.cancellationRate, 0.25);
    expect(week.statusCounts[BookingStatus.confirmed], 0);

    final month = calc(AnalyticsPeriod.days30, bookings: sample);
    expect(month.bookings, 5);
    expect(month.cancellationRate, 0.2);
  });

  test('top service and specialist ignore cancelled visits', () {
    final month = calc(AnalyticsPeriod.days30, bookings: sample);
    expect(month.byService, [
      const NamedCount('Мужская стрижка', 2),
      const NamedCount('Оформление бороды', 2),
    ]);
    // Equal counts: alphabetical order decides.
    expect(month.topService, const NamedCount('Мужская стрижка', 2));
    expect(month.topSpecialist, const NamedCount('Арман С.', 4));
  });

  test('daily series has one bucket per day', () {
    final week = calc(AnalyticsPeriod.days7, bookings: sample);
    expect(week.bookingsSeries, hasLength(7));
    expect(week.bookingsSeries.first.start, DateTime(2026, 9, 29));
    expect(week.bookingsSeries.last.start, DateTime(2026, 10, 5));
    expect(week.bookingsSeries.map((b) => b.value), [0, 1, 0, 0, 0, 2, 1]);
    expect(
      week.bookingsSeries.fold<num>(0, (s, b) => s + b.value),
      week.bookings,
    );
  });

  test('90 days are grouped by week, newest week ends today', () {
    final quarter = calc(AnalyticsPeriod.days90, bookings: sample);
    final series = quarter.bookingsSeries;
    expect(series, hasLength(13));
    expect(series.last.end, DateTime(2026, 10, 5));
    expect(series.last.start, DateTime(2026, 9, 29));
    expect(series.first.start, quarter.from);
    expect(series.fold<num>(0, (s, b) => s + b.value), quarter.bookings);
    expect(series.last.value, 4);
  });

  test('ratings and favorites are counted by their creation date', () {
    final result = calc(
      AnalyticsPeriod.days7,
      reviews: [
        review('r1', 5, DateTime(2026, 10, 3)),
        review('r2', 3, DateTime(2026, 10, 1)),
        review('r3', 1, DateTime(2026, 8, 1)),
      ],
      favorites: [
        favorite('u1', DateTime(2026, 10, 4)),
        favorite('u2', DateTime(2026, 9, 1)),
      ],
    );
    expect(result.newReviews, 2);
    expect(result.averageRating, 4);
    expect(result.overallRating, 3);
    expect(result.favoritesAdded, 1);
    expect(result.reviewsSeries.fold<num>(0, (s, b) => s + b.value), 2);
    expect(result.favoritesSeries.fold<num>(0, (s, b) => s + b.value), 1);
  });

  test('an empty period has no division by zero', () {
    final empty = calc(AnalyticsPeriod.days30);
    expect(empty.isEmpty, isTrue);
    expect(empty.bookings, 0);
    expect(empty.cancellationRate, isNull);
    expect(empty.averageRating, isNull);
    expect(empty.topSpecialist, isNull);
    expect(empty.topService, isNull);
    expect(empty.bookingsSeries, hasLength(30));
    expect(empty.bookingsSeries.every((b) => b.value == 0), isTrue);
  });

  test('a longer period never shows fewer bookings', () {
    final counts = [
      for (final period in AnalyticsPeriod.values)
        calc(period, bookings: sample).bookings,
    ];
    expect(counts, orderedEquals([...counts]..sort()));
  });
}

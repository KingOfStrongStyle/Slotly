import 'review.dart';

/// Average rating, count and distribution by stars, always computed from
/// the reviews themselves so it cannot drift away from them.
class RatingSummary {
  RatingSummary._(this.count, this.average, this.countsByStars);

  factory RatingSummary.of(Iterable<Review> reviews) {
    final counts = List.filled(Review.maxRating, 0);
    var sum = 0;
    var count = 0;
    for (final review in reviews) {
      counts[review.rating - 1]++;
      sum += review.rating;
      count++;
    }
    return RatingSummary._(count, count == 0 ? null : sum / count, counts);
  }

  static final empty = RatingSummary.of(const []);

  final int count;

  /// `null` when there are no reviews: "no rating" is not the same as 0.
  final double? average;

  /// Index 0 is one star, index 4 is five stars.
  final List<int> countsByStars;

  bool get isEmpty => count == 0;

  int countFor(int stars) => countsByStars[stars - 1];

  /// Share of reviews with [stars], 0…1.
  double shareFor(int stars) => count == 0 ? 0 : countFor(stars) / count;
}

import 'review.dart';

// Влад: средний рейтинг нигде не храним, всегда считаем из отзывов.
// Без отзывов average = null, чтобы не показывать "0,0"
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

  final double? average;

  final List<int> countsByStars;

  bool get isEmpty => count == 0;

  int countFor(int stars) => countsByStars[stars - 1];

  double shareFor(int stars) => count == 0 ? 0 : countFor(stars) / count;
}

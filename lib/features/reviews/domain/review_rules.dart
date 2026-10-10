import '../../booking/domain/booking.dart';
import 'review.dart';

enum ReviewIssue { ratingOutOfRange, textTooLong, replyEmpty, replyTooLong }

enum ReviewEligibility { allowed, notCompleted, alreadyReviewed, notOwnBooking }

abstract final class ReviewRules {
  static const maxReplyLength = 500;

  static ReviewEligibility eligibility({
    required Booking booking,
    required String userId,
    required Iterable<Review> existingReviews,
  }) {
    if (booking.clientId != userId) return ReviewEligibility.notOwnBooking;
    if (!booking.isCompleted) return ReviewEligibility.notCompleted;
    if (existingReviews.any((r) => r.bookingId == booking.id)) {
      return ReviewEligibility.alreadyReviewed;
    }
    return ReviewEligibility.allowed;
  }

  static List<ReviewIssue> validate({
    required int rating,
    required String text,
  }) => [
    if (rating < Review.minRating || rating > Review.maxRating)
      ReviewIssue.ratingOutOfRange,
    if (text.trim().length > Review.maxTextLength) ReviewIssue.textTooLong,
  ];

  static List<ReviewIssue> validateReply(String text) => [
    if (text.trim().isEmpty) ReviewIssue.replyEmpty,
    if (text.trim().length > maxReplyLength) ReviewIssue.replyTooLong,
  ];
}

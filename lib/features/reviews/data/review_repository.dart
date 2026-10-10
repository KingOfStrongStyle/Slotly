import 'package:flutter/foundation.dart';

import '../../../core/access/access_policy.dart';
import '../../../data/local/local_context.dart';
import '../domain/review.dart';
import '../domain/review_rules.dart';

class ReviewNotAllowedException implements Exception {
  const ReviewNotAllowedException(this.reason);

  final ReviewEligibility reason;

  @override
  String toString() => 'ReviewNotAllowedException(${reason.name})';
}

/// Reviews of organizations. Ratings are never stored: callers build a
/// `RatingSummary` from the returned reviews.
abstract interface class ReviewRepository {
  Listenable get changes;

  /// Public reviews of an organization, newest first.
  Future<List<Review>> fetchOrganizationReviews(String organizationId);

  /// Reviews written by the signed-in customer.
  Future<List<Review>> fetchMyReviews();

  /// Throws [ReviewNotAllowedException] unless the signed-in customer owns
  /// the completed booking and has not reviewed it yet.
  Future<Review> createReview({
    required String bookingId,
    required int rating,
    required String text,
  });

  Future<Review> updateReview(
    String reviewId, {
    required int rating,
    required String text,
  });

  Future<void> deleteReview(String reviewId);

  /// Owner answers a review of their organization. The review itself
  /// cannot be changed by the owner.
  Future<Review> replyToReview(String reviewId, String text);
}

class LocalReviewRepository implements ReviewRepository {
  const LocalReviewRepository(this._context);

  final LocalContext _context;

  @override
  Listenable get changes => _context.database;

  @override
  Future<List<Review>> fetchOrganizationReviews(String organizationId) async {
    _context.require(AppAction.browseCatalog);
    return _sorted(
      _context.database.tables.reviews.values.where(
        (r) => r.organizationId == organizationId,
      ),
    );
  }

  @override
  Future<List<Review>> fetchMyReviews() async {
    _context.require(AppAction.viewOwnBookings);
    final userId = _context.user!.id;
    return _sorted(
      _context.database.tables.reviews.values.where(
        (r) => r.authorId == userId,
      ),
    );
  }

  @override
  Future<Review> createReview({
    required String bookingId,
    required int rating,
    required String text,
  }) async {
    final tables = _context.database.tables;
    final booking = tables.bookings[bookingId];
    _context.require(AppAction.writeReview, resourceOwnerId: booking?.clientId);
    if (booking == null) {
      throw RecordNotFoundException('booking', bookingId);
    }
    final user = _context.user!;
    final eligibility = ReviewRules.eligibility(
      booking: booking,
      userId: user.id,
      existingReviews: tables.reviews.values,
    );
    if (eligibility != ReviewEligibility.allowed) {
      throw ReviewNotAllowedException(eligibility);
    }
    _validate(rating, text);

    return _context.database.update((t) {
      final id = 'review-${t.nextCounter('review')}';
      final review = Review(
        id: id,
        bookingId: booking.id,
        organizationId: booking.organizationId,
        serviceId: booking.serviceId,
        serviceTitle: booking.serviceTitle,
        specialistId: booking.specialist.id,
        authorId: user.id,
        authorName: user.displayName,
        rating: rating,
        text: text.trim(),
        createdAt: _context.clock(),
      );
      t.reviews[id] = review;
      return review;
    });
  }

  @override
  Future<Review> updateReview(
    String reviewId, {
    required int rating,
    required String text,
  }) async {
    final review = _ownReview(reviewId);
    _validate(rating, text);
    return _save(
      review.copyWith(
        rating: rating,
        text: text.trim(),
        updatedAt: _context.clock(),
      ),
    );
  }

  @override
  Future<void> deleteReview(String reviewId) async {
    _ownReview(reviewId);
    await _context.database.update((t) => t.reviews.remove(reviewId));
  }

  @override
  Future<Review> replyToReview(String reviewId, String text) async {
    final review = _context.database.tables.reviews[reviewId];
    if (review == null) throw RecordNotFoundException('review', reviewId);
    _context.require(
      AppAction.replyToReview,
      organizationId: review.organizationId,
    );
    final issues = ReviewRules.validateReply(text);
    if (issues.isNotEmpty) throw ValidationException(issues);
    return _save(
      review.copyWith(
        reply: ReviewReply(text: text.trim(), createdAt: _context.clock()),
      ),
    );
  }

  Review _ownReview(String reviewId) {
    final review = _context.database.tables.reviews[reviewId];
    _context.require(
      AppAction.editOwnReview,
      resourceOwnerId: review?.authorId,
    );
    if (review == null) throw RecordNotFoundException('review', reviewId);
    return review;
  }

  void _validate(int rating, String text) {
    final issues = ReviewRules.validate(rating: rating, text: text);
    if (issues.isNotEmpty) throw ValidationException(issues);
  }

  Future<Review> _save(Review review) => _context.database.update((t) {
    t.reviews[review.id] = review;
    return review;
  });

  static List<Review> _sorted(Iterable<Review> reviews) =>
      reviews.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}

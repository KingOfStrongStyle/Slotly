import 'package:flutter_test/flutter_test.dart';
import 'package:slotly/data/local/local_context.dart';
import 'package:slotly/data/seed/demo_accounts.dart';
import 'package:slotly/data/seed/demo_catalog.dart';
import 'package:slotly/features/booking/domain/booking.dart';
import 'package:slotly/features/reviews/data/review_repository.dart';
import 'package:slotly/features/reviews/domain/rating_summary.dart';
import 'package:slotly/features/reviews/domain/review.dart';
import 'package:slotly/features/reviews/domain/review_rules.dart';

import '../../helpers/booking_fixtures.dart';
import '../../helpers/test_app.dart';

void main() {
  late TestData data;
  late LocalReviewRepository reviews;

  setUp(() async {
    data = await TestData.create();
    reviews = LocalReviewRepository(data.context);
    data.signInAs('aliya');
    await data.database.update((t) {
      for (final booking in [
        fixtureBooking(
          id: 'done',
          startAt: DateTime(2026, 10, 1, 12),
          status: BookingStatus.completed,
        ),
        fixtureBooking(id: 'upcoming', startAt: DateTime(2026, 10, 7, 12)),
        fixtureBooking(
          id: 'cancelled',
          startAt: DateTime(2026, 9, 30, 12),
          status: BookingStatus.cancelled,
        ),
      ]) {
        t.bookings[booking.id] = booking;
      }
    });
  });

  Matcher notAllowed(ReviewEligibility reason) => throwsA(
    isA<ReviewNotAllowedException>().having((e) => e.reason, 'reason', reason),
  );

  test('a customer reviews a completed own visit once', () async {
    final review = await reviews.createReview(
      bookingId: 'done',
      rating: 5,
      text: '  Отлично  ',
    );

    expect(review.authorId, clientAliyaId);
    expect(review.organizationId, orgNorth);
    expect(review.text, 'Отлично');
    expect(review.createdAt, testNow);
    expect(
      () => reviews.createReview(bookingId: 'done', rating: 4, text: ''),
      notAllowed(ReviewEligibility.alreadyReviewed),
    );
  });

  test('upcoming and cancelled visits cannot be reviewed', () {
    expect(
      () => reviews.createReview(bookingId: 'upcoming', rating: 5, text: ''),
      notAllowed(ReviewEligibility.notCompleted),
    );
    expect(
      () => reviews.createReview(bookingId: 'cancelled', rating: 5, text: ''),
      notAllowed(ReviewEligibility.notCompleted),
    );
  });

  test('rating and text are validated', () {
    expect(
      () => reviews.createReview(bookingId: 'done', rating: 0, text: ''),
      throwsA(isA<ValidationException<ReviewIssue>>()),
    );
    expect(
      () => reviews.createReview(
        bookingId: 'done',
        rating: 5,
        text: 'а' * (Review.maxTextLength + 1),
      ),
      throwsA(isA<ValidationException<ReviewIssue>>()),
    );
  });

  test('the author edits and deletes the review; rating follows', () async {
    final review = await reviews.createReview(
      bookingId: 'done',
      rating: 2,
      text: '',
    );
    expect(
      RatingSummary.of(await reviews.fetchOrganizationReviews(orgNorth))
          .average,
      2,
    );

    data.clock = testNow.add(const Duration(hours: 1));
    final updated = await reviews.updateReview(
      review.id,
      rating: 5,
      text: 'Передумала',
    );
    expect(updated.rating, 5);
    expect(updated.updatedAt, data.clock);
    expect(
      RatingSummary.of(await reviews.fetchOrganizationReviews(orgNorth))
          .average,
      5,
    );

    await reviews.deleteReview(review.id);
    expect(await reviews.fetchOrganizationReviews(orgNorth), isEmpty);
    expect(
      await reviews.createReview(bookingId: 'done', rating: 4, text: ''),
      isA<Review>(),
      reason: 'after deletion the visit can be reviewed again',
    );
  });

  test('the owner replies but the review itself does not change', () async {
    final review = await reviews.createReview(
      bookingId: 'done',
      rating: 3,
      text: 'Долго ждали',
    );
    data.signInAs('north');

    final replied = await reviews.replyToReview(review.id, 'Простите!');

    expect(replied.reply?.text, 'Простите!');
    expect(replied.rating, 3);
    expect(replied.text, 'Долго ждали');
    expect(
      () => reviews.replyToReview(review.id, '   '),
      throwsA(isA<ValidationException<ReviewIssue>>()),
    );
  });

  test('my reviews contain only reviews of the signed-in customer', () async {
    await reviews.createReview(bookingId: 'done', rating: 5, text: '');
    expect(await reviews.fetchMyReviews(), hasLength(1));
    data.signInAs('damir');
    expect(await reviews.fetchMyReviews(), isEmpty);
  });

  group('RatingSummary', () {
    Review review(int rating) => Review(
      id: 'r$rating${DateTime.now().microsecond}',
      bookingId: 'b',
      organizationId: orgNorth,
      serviceId: 's',
      serviceTitle: 's',
      specialistId: 'sp',
      authorId: 'a',
      authorName: 'a',
      rating: rating,
      text: '',
      createdAt: testNow,
    );

    test('average, count and distribution', () {
      final summary = RatingSummary.of([
        review(5),
        review(5),
        review(4),
        review(1),
      ]);
      expect(summary.count, 4);
      expect(summary.average, 3.75);
      expect(summary.countFor(5), 2);
      expect(summary.countFor(2), 0);
      expect(summary.shareFor(5), 0.5);
    });

    test('no reviews means no rating, not zero', () {
      expect(RatingSummary.empty.average, isNull);
      expect(RatingSummary.empty.isEmpty, isTrue);
      expect(RatingSummary.empty.shareFor(5), 0);
    });
  });
}

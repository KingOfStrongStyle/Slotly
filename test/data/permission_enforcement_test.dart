import 'package:flutter_test/flutter_test.dart';
import 'package:slotly/core/access/access_policy.dart';
import 'package:slotly/data/local/local_context.dart';
import 'package:slotly/data/seed/demo_accounts.dart';
import 'package:slotly/data/seed/demo_catalog.dart';
import 'package:slotly/features/analytics/data/analytics_repository.dart';
import 'package:slotly/features/analytics/domain/owner_analytics.dart';
import 'package:slotly/features/booking/data/local_booking_repository.dart';
import 'package:slotly/features/booking/domain/booking.dart';
import 'package:slotly/features/booking/domain/booking_repository.dart';
import 'package:slotly/features/business/data/business_repository.dart';
import 'package:slotly/features/business/data/photo_storage.dart';
import 'package:slotly/features/catalog/domain/service.dart';
import 'package:slotly/features/favorites/data/favorites_repository.dart';
import 'package:slotly/features/reviews/data/review_repository.dart';

import '../helpers/test_app.dart';

// Влад: то же самое, но вызовами репозиториев напрямую, мимо UI
void main() {
  late TestData data;
  late LocalBookingRepository bookings;
  late LocalReviewRepository reviews;
  late LocalFavoritesRepository favorites;
  late LocalBusinessRepository business;
  late LocalAnalyticsRepository analytics;

  final denied = throwsA(isA<AccessDeniedException>());

  setUp(() async {
    data = await TestData.create(withActivity: true);
    bookings = LocalBookingRepository(data.context);
    reviews = LocalReviewRepository(data.context);
    favorites = LocalFavoritesRepository(data.context);
    business = LocalBusinessRepository(data.context, MemoryPhotoStorage());
    analytics = LocalAnalyticsRepository(data.context);
  });

  Booking bookingOf(String clientId, {BookingStatus? status}) =>
      data.database.tables.bookings.values.firstWhere(
        (b) => b.clientId == clientId && (status == null || b.status == status),
      );

  String reviewIdOf(String orgId) => data.database.tables.reviews.values
      .firstWhere((r) => r.organizationId == orgId)
      .id;

  group('guest', () {
    setUp(() => data.signInAs(null));

    test('cannot read or change private data', () {
      expect(bookings.fetchBookings, denied);
      expect(() => bookings.fetchOrganizationBookings(orgNorth), denied);
      expect(() => favorites.toggle(orgNorth), denied);
      expect(() => analytics.fetch(orgNorth, AnalyticsPeriod.days7), denied);
      expect(reviews.fetchMyReviews, denied);
    });
  });

  group('client', () {
    setUp(() => data.signInAs('aliya'));

    test('cannot open owner analytics or bookings of a business', () {
      expect(() => analytics.fetch(orgNorth, AnalyticsPeriod.days30), denied);
      expect(() => bookings.fetchOrganizationBookings(orgNorth), denied);
    });

    test('cannot edit organizations, services, photos or reply', () {
      final organization = data.database.tables.organizations[orgNorth]!;
      final service = data.database.tables.services['svc-beard']!;
      expect(() => business.updateOrganization(organization), denied);
      expect(() => business.saveService(service), denied);
      expect(() => business.setServiceHidden(service.id, hidden: true), denied);
      expect(() => business.addPhoto(orgNorth, sourcePath: '/x.jpg'), denied);
      expect(() => reviews.replyToReview(reviewIdOf(orgNorth), 'ok'), denied);
    });

    test("cannot change another client's booking or review", () {
      final foreign = bookingOf(clientDamirId, status: BookingStatus.confirmed);
      expect(() => bookings.cancelBooking(foreign.id), denied);
      expect(
        () => bookings.rescheduleBooking(
          foreign.id,
          startAt: foreign.startAt,
          specialist: foreign.specialist,
        ),
        denied,
      );
      final foreignReview = data.database.tables.reviews.values.firstWhere(
        (r) => r.authorId != clientAliyaId,
      );
      expect(
        () => reviews.updateReview(foreignReview.id, rating: 1, text: ''),
        denied,
      );
      expect(() => reviews.deleteReview(foreignReview.id), denied);
      final foreignCompleted = bookingOf(
        clientZhannaId,
        status: BookingStatus.completed,
      );
      expect(
        () => reviews.createReview(
          bookingId: foreignCompleted.id,
          rating: 5,
          text: '',
        ),
        denied,
      );
    });

    test('sees only own bookings', () async {
      final own = await bookings.fetchBookings();
      expect(own, isNotEmpty);
      expect(own.every((b) => b.clientId == clientAliyaId), isTrue);
    });

    test("cannot check in by another client's ticket", () {
      final foreign = bookingOf(clientDamirId);
      expect(
        () => bookings.checkIn(foreign.ticketNumber),
        throwsA(isA<TicketNotFoundException>()),
      );
    });
  });

  group('owner', () {
    setUp(() => data.signInAs('north'));

    test('reads analytics and bookings only of the own organization', () async {
      final own = await bookings.fetchOrganizationBookings(orgNorth);
      expect(own.every((b) => b.organizationId == orgNorth), isTrue);
      await analytics.fetch(orgNorth, AnalyticsPeriod.days90);

      expect(() => bookings.fetchOrganizationBookings(orgWhiteLine), denied);
      expect(
        () => analytics.fetch(orgWhiteLine, AnalyticsPeriod.days90),
        denied,
      );
    });

    test('cannot change another organization', () {
      final other = data.database.tables.organizations[orgWhiteLine]!;
      final otherService = data.database.tables.services['svc-cleaning']!;
      final otherPhoto = data.database.tables.photos.values.firstWhere(
        (p) => p.organizationId == orgWhiteLine,
      );
      expect(() => business.updateOrganization(other), denied);
      expect(() => business.saveService(otherService), denied);
      expect(
        () => business.setServiceHidden(otherService.id, hidden: true),
        denied,
      );
      expect(
        () => business.addPhoto(orgWhiteLine, sourcePath: '/x.jpg'),
        denied,
      );
      expect(() => business.removePhoto(otherPhoto.id), denied);
      expect(() => business.movePhoto(otherPhoto.id, 0), denied);
      expect(() => business.fetchManagedServices(orgWhiteLine), denied);
      expect(
        () => reviews.replyToReview(reviewIdOf(orgWhiteLine), 'ok'),
        denied,
      );
    });

    test('cannot move a service of another business into the own one', () {
      final other = data.database.tables.services['svc-cleaning']!;
      final hijacked = Service(
        id: other.id,
        organizationId: orgNorth,
        title: 'Моя услуга',
        category: other.category,
        description: other.description,
        duration: other.duration,
        priceKzt: other.priceKzt,
        availableSpecialists: [data.database.tables.specialists['sp-arman']!],
        artworkVariant: 0,
      );
      expect(
        () => business.saveService(hijacked),
        throwsA(isA<RecordNotFoundException>()),
      );
      expect(
        data.database.tables.services[other.id]!.organizationId,
        orgWhiteLine,
      );
    });

    test('cannot assign a specialist of another business', () {
      final own = data.database.tables.services['svc-beard']!;
      final withForeign = own.copyWith(
        availableSpecialists: [data.database.tables.specialists['sp-saule']!],
      );
      expect(() => business.saveService(withForeign), denied);
    });

    test('cannot act as a customer', () {
      final completed = data.database.tables.bookings.values.firstWhere(
        (b) => b.organizationId == orgNorth && b.isCompleted,
      );
      expect(() => favorites.toggle(orgNorth), denied);
      expect(bookings.fetchBookings, denied);
      expect(
        () => reviews.createReview(
          bookingId: completed.id,
          rating: 5,
          text: 'Отличный барбершоп',
        ),
        denied,
      );
      final review = data.database.tables.reviews[reviewIdOf(orgNorth)]!;
      expect(
        () => reviews.updateReview(review.id, rating: 1, text: ''),
        denied,
      );
      expect(() => reviews.deleteReview(review.id), denied);
    });

    test('checks in tickets only of the own organization', () {
      final foreign = data.database.tables.bookings.values.firstWhere(
        (b) => b.organizationId == orgWhiteLine,
      );
      expect(
        () => bookings.checkIn(foreign.ticketNumber),
        throwsA(isA<TicketNotFoundException>()),
      );
      expect(() => bookings.completeBooking(foreign.id), denied);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:slotly/core/access/access_policy.dart';
import 'package:slotly/data/seed/demo_catalog.dart';
import 'package:slotly/features/analytics/data/analytics_repository.dart';
import 'package:slotly/features/analytics/domain/analytics_calculator.dart';
import 'package:slotly/features/analytics/domain/owner_analytics.dart';
import 'package:slotly/features/booking/domain/booking.dart';

import '../../helpers/booking_fixtures.dart';
import '../../helpers/test_app.dart';

void main() {
  late TestData data;
  late LocalAnalyticsRepository analytics;

  setUp(() async {
    data = await TestData.create(withActivity: true);
    analytics = LocalAnalyticsRepository(data.context);
    data.signInAs('north');
  });

  test('uses only records of the requested organization', () async {
    final result = await analytics.fetch(orgNorth, AnalyticsPeriod.days90);
    final t = data.database.tables;
    final expected = AnalyticsCalculator.calculate(
      period: AnalyticsPeriod.days90,
      now: testNow,
      bookings: t.bookings.values.where((b) => b.organizationId == orgNorth),
      reviews: t.reviews.values.where((r) => r.organizationId == orgNorth),
      favorites: t.favorites.values.where((f) => f.organizationId == orgNorth),
    );
    expect(result.bookings, expected.bookings);
    expect(result.bookings, greaterThan(0));
    final allBookings = t.bookings.values.where(
      (b) => !b.startAt.isAfter(testNow),
    );
    expect(result.bookings, lessThan(allBookings.length));
    final services = result.byService.map((i) => i.name).toSet();
    final northTitles = demoServices
        .where((s) => s.organizationId == orgNorth)
        .map((s) => s.title)
        .toSet();
    expect(northTitles.containsAll(services), isTrue);
  });

  test('demo data fills every period with numbers', () async {
    for (final period in AnalyticsPeriod.values) {
      final result = await analytics.fetch(orgNorth, period);
      expect(result.isEmpty, isFalse, reason: period.name);
    }
  });

  test('the cache is reused until the data changes', () async {
    final first = await analytics.fetch(orgNorth, AnalyticsPeriod.days7);
    expect(
      identical(await analytics.fetch(orgNorth, AnalyticsPeriod.days7), first),
      isTrue,
    );

    await data.database.update((t) {
      final booking = fixtureBooking(
        id: 'fresh',
        startAt: DateTime(2026, 10, 5, 8),
        status: BookingStatus.completed,
      );
      t.bookings[booking.id] = booking;
    });

    final second = await analytics.fetch(orgNorth, AnalyticsPeriod.days7);
    expect(identical(second, first), isFalse);
    expect(second.bookings, first.bookings + 1);
  });

  test('another owner cannot read the numbers', () {
    data.signInAs('whiteline');
    expect(
      () => analytics.fetch(orgNorth, AnalyticsPeriod.days7),
      throwsA(isA<AccessDeniedException>()),
    );
  });
}

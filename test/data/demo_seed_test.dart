import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:slotly/core/utils/clock.dart';
import 'package:slotly/data/local/app_database.dart';
import 'package:slotly/data/local/database_codec.dart';
import 'package:slotly/data/local/database_storage.dart';
import 'package:slotly/data/seed/demo_accounts.dart';
import 'package:slotly/data/seed/demo_catalog.dart';
import 'package:slotly/data/seed/demo_seed.dart';
import 'package:slotly/features/auth/domain/app_user.dart';
import 'package:slotly/features/booking/data/local_booking_repository.dart';
import 'package:slotly/features/booking/domain/booking.dart';

import '../helpers/test_app.dart';

void main() {
  final now = DateTime(2026, 10, 5, 9);

  Future<AppDatabase> seeded([MemoryDatabaseStorage? storage]) async {
    final database = await AppDatabase.open(storage ?? MemoryDatabaseStorage());
    await DemoSeed(clock: () => now).apply(database);
    return database;
  }

  test('creates the documented amount of demo data', () async {
    final t = (await seeded()).tables;
    final users = t.users.values;

    expect(t.organizations, hasLength(6));
    expect(users.where((u) => u.role == UserRole.owner), hasLength(2));
    expect(users.where((u) => u.role == UserRole.client), hasLength(4));
    expect(t.specialists.length, inInclusiveRange(8, 12));
    expect(t.services.length, inInclusiveRange(15, 25));
    expect(
      t.services.values.where((s) => s.hasPriceOptions).length,
      greaterThanOrEqualTo(3),
    );
    expect(t.bookings.length, inInclusiveRange(80, 150));
    expect(t.reviews.length, inInclusiveRange(30, 60));
    expect(t.favorites, isNotEmpty);
    expect(
      t.bookings.values.map((b) => b.status).toSet(),
      BookingStatus.values.toSet(),
    );
    for (final org in t.organizations.values) {
      final photos = t.photos.values.where((p) => p.organizationId == org.id);
      expect(photos.length, inInclusiveRange(1, 5));
    }
  });

  test('covers the demo scenarios', () async {
    final t = (await seeded()).tables;

    expect(
      t.reviews.values.where((r) => r.organizationId == orgFormula),
      isEmpty,
      reason: 'one organization without reviews',
    );
    expect(
      t.bookings.values.where(
        (b) =>
            b.clientId == clientDamirId && b.isActive && b.startAt.isAfter(now),
      ),
      isNotEmpty,
      reason: 'future bookings for reminders',
    );
    final reviewed = t.reviews.values.map((r) => r.bookingId).toSet();
    expect(
      t.bookings.values.where(
        (b) =>
            b.clientId == clientAliyaId &&
            b.isCompleted &&
            !reviewed.contains(b.id),
      ),
      isNotEmpty,
      reason: 'Aliya can write a review',
    );
    final history = t.bookings.values.where(
      (b) => b.startAt.isBefore(now.subtract(const Duration(days: 60))),
    );
    expect(history, isNotEmpty, reason: 'data for the 90-day chart');
  });

  test('a service of a specialist on vacation has no free slots', () async {
    final data = await TestData.create(withActivity: true, now: now);
    data.signInAs('aliya');
    final repository = LocalBookingRepository(data.context);
    final extraction = data.database.tables.services['svc-extraction']!;

    for (var day = 0; day < 14; day++) {
      final slots = await repository.fetchTimeSlots(
        service: extraction,
        specialist: extraction.availableSpecialists.single,
        day: now.dateOnly.add(Duration(days: day)),
      );
      expect(slots, isEmpty);
    }
  });

  test('specialists have different load', () async {
    final t = (await seeded()).tables;
    final counts = <String, int>{};
    for (final b in t.bookings.values) {
      counts[b.specialist.id] = (counts[b.specialist.id] ?? 0) + 1;
    }
    final values = counts.values.toList()..sort();
    expect(values.last, greaterThan(values.first * 3));
  });

  test('no specialist has overlapping active bookings', () async {
    final bookings = (await seeded()).tables.bookings.values
        .where((b) => !b.isCancelled)
        .toList();
    for (final a in bookings) {
      for (final b in bookings) {
        if (a.id == b.id || a.specialist != b.specialist) continue;
        expect(a.overlaps(b.startAt, b.endAt), isFalse, reason: '$a / $b');
      }
    }
  });

  test('running the seed again does not duplicate anything', () async {
    final storage = MemoryDatabaseStorage();
    final database = await seeded(storage);
    final counts = _counts(database);

    expect(await DemoSeed(clock: () => now).apply(database), isFalse);
    final reopened = await AppDatabase.open(storage);
    expect(
      await DemoSeed(clock: () => now.add(const Duration(days: 3)))
          .apply(reopened),
      isFalse,
    );

    expect(_counts(database), counts);
    expect(_counts(reopened), counts);
  });

  test('the same clock gives the same data', () async {
    final a = jsonEncode(
      DatabaseCodec.encode((await seeded()).tables)['bookings'],
    );
    final b = jsonEncode(
      DatabaseCodec.encode((await seeded()).tables)['bookings'],
    );
    expect(a, b);
  });

  test('demo data is visibly fictional', () async {
    for (final organization in demoOrganizations) {
      expect(organization.address, contains('(демо)'));
      expect(organization.phone, contains('000 00'));
    }
    for (final account in demoAccounts) {
      expect(account.password, endsWith('-demo'));
    }
  });

  test('ticket numbers continue after the demo bookings', () async {
    final data = await TestData.create(withActivity: true, now: now);
    data.signInAs('aliya');
    final maxTicket = data.database.tables.bookings.values
        .map((b) => int.parse(b.ticketNumber))
        .reduce((a, b) => a > b ? a : b);
    final t = data.database.tables;
    final next = t.nextCounter('ticket', start: 101);
    expect(next, maxTicket + 1);
  });
}

List<int> _counts(AppDatabase database) {
  final t = database.tables;
  return [
    t.users.length,
    t.organizations.length,
    t.services.length,
    t.bookings.length,
    t.reviews.length,
    t.favorites.length,
    t.photos.length,
  ];
}

import 'dart:math';

import '../../core/utils/clock.dart';
import '../../features/auth/data/password_hasher.dart';
import '../../features/booking/data/demo_schedule.dart';
import '../../features/booking/domain/booking.dart';
import '../../features/catalog/domain/organization.dart';
import '../../features/catalog/domain/service.dart';
import '../../features/favorites/domain/favorite.dart';
import '../../features/reviews/domain/review.dart';
import '../local/app_database.dart';
import '../local/database_tables.dart';
import 'demo_accounts.dart';
import 'demo_catalog.dart';

class DemoSeed {
  const DemoSeed({
    required this.clock,
    this.schedule = const DemoSchedule(),
    this.hasher = const PasswordHasher(),
    this.withActivity = true,
  });

  static const version = 1;
  static const historyDays = 90;
  static const futureDays = 14;
  static const _randomSeed = 20261005;

  final Clock clock;
  final DemoSchedule schedule;
  final PasswordHasher hasher;

  final bool withActivity;

  // Влад: seed только в пустую базу, повторный запуск ничего не дублирует.
  // Random с фиксированным зерном, даты от clock - в тестах данные всегда одни и те же
  Future<bool> apply(AppDatabase database) async {
    final settings = database.tables.settings;
    if (settings.seedVersion >= version || !database.tables.isEmpty) {
      return false;
    }
    await database.update(_populate);
    return true;
  }

  // Влад: рейтинги и цифры аналитики тут не задаём, они считаются из записей и отзывов
  void _populate(DatabaseTables t) {
    final random = Random(_randomSeed);
    final now = clock();
    _addAccounts(t, random);
    _addCatalog(t, now);
    if (withActivity) {
      _BookingGenerator(t, random, now, schedule).run();
      _addReviews(t, random, now);
      _addFavorites(t, now);
    }
    t.settings.seedVersion = version;
  }

  void _addAccounts(DatabaseTables t, Random random) {
    for (final account in demoAccounts) {
      final user = account.user;
      final salt = hasher.newSalt(random);
      t.users[user.id] = user;
      t.credentials[user.id] = StoredCredential(
        salt: salt,
        hash: hasher.hash(account.password, salt),
      );
    }
  }

  void _addCatalog(DatabaseTables t, DateTime now) {
    for (final organization in demoOrganizations) {
      t.organizations[organization.id] = organization;
      final count = switch (organization.id) {
        orgNorth => 4,
        orgFormula => 1,
        _ => 3,
      };
      for (var i = 0; i < count; i++) {
        final photo = BusinessPhoto(
          id: 'photo-${organization.id}-$i',
          organizationId: organization.id,
          position: i,
          addedAt: now.subtract(Duration(days: 120 - i)),
          illustrationVariant: (organization.artworkVariant + i) % 4,
        );
        t.photos[photo.id] = photo;
      }
    }
    for (final specialist in demoSpecialists) {
      t.specialists[specialist.id] = specialist;
    }
    for (final service in demoServices) {
      t.services[service.id] = service;
    }
  }

  void _addReviews(DatabaseTables t, Random random, DateTime now) {
    final completed = t.bookings.values.where((b) => b.isCompleted).toList()
      ..sort(Booking.compareByStartAt);
    final aliyaLatest = completed
        .where((b) => b.clientId == clientAliyaId)
        .toList()
        .reversed
        .take(2)
        .map((b) => b.id)
        .toSet();

    for (final booking in completed) {
      if (aliyaLatest.contains(booking.id)) continue;
      final profile = _reviewProfiles[booking.organizationId];
      if (profile == null || random.nextDouble() > profile.share) continue;

      final rating = _pickRating(random, profile.ratingWeights);
      final createdAt = _min(
        booking.endAt.add(Duration(hours: 1 + random.nextInt(40))),
        now.subtract(const Duration(minutes: 5)),
      );
      final texts = _reviewTexts[rating]!;
      final withText = random.nextDouble() < 0.75;
      final id = 'review-${t.nextCounter('review')}';
      final needsReply =
          booking.organizationId == orgNorth ||
          booking.organizationId == orgWhiteLine;
      final reply = needsReply && (rating <= 3 || random.nextDouble() < 0.25)
          ? ReviewReply(
              text: rating <= 3 ? _apologyReply : _thanksReply,
              createdAt: _min(
                createdAt.add(Duration(hours: 2 + random.nextInt(20))),
                now,
              ),
            )
          : null;
      t.reviews[id] = Review(
        id: id,
        bookingId: booking.id,
        organizationId: booking.organizationId,
        serviceId: booking.serviceId,
        serviceTitle: booking.serviceTitle,
        specialistId: booking.specialist.id,
        authorId: booking.clientId,
        authorName: booking.clientName,
        rating: rating,
        text: withText ? texts[random.nextInt(texts.length)] : '',
        createdAt: createdAt,
        reply: reply,
      );
    }
  }

  void _addFavorites(DatabaseTables t, DateTime now) {
    const favorites = [
      (clientAliyaId, orgNorth, 60),
      (clientAliyaId, orgLavanda, 20),
      (clientDamirId, orgWhiteLine, 10),
      (clientZhannaId, orgNorth, 5),
      (clientZhannaId, orgGarage, 40),
      (clientIlyaId, orgNorth, 2),
      (clientIlyaId, orgHealth, 80),
      (clientIlyaId, orgWhiteLine, 25),
    ];
    for (final (userId, organizationId, daysAgo) in favorites) {
      final favorite = Favorite(
        userId: userId,
        organizationId: organizationId,
        createdAt: now.subtract(Duration(days: daysAgo, hours: 3)),
      );
      t.favorites[favorite.key] = favorite;
    }
  }

  static int _pickRating(Random random, List<int> weights) {
    final total = weights.reduce((a, b) => a + b);
    var roll = random.nextInt(total);
    for (var stars = 1; stars <= 5; stars++) {
      roll -= weights[stars - 1];
      if (roll < 0) return stars;
    }
    return 5;
  }

  static DateTime _min(DateTime a, DateTime b) => a.isBefore(b) ? a : b;
}

class _BookingGenerator {
  _BookingGenerator(this.t, this.random, this.now, this.schedule);

  final DatabaseTables t;
  final Random random;
  final DateTime now;
  final DemoSchedule schedule;

  static const _dailyLoad = {
    orgNorth: 0.55,
    orgWhiteLine: 0.4,
    orgGarage: 0.22,
    orgLavanda: 0.18,
    orgHealth: 0.15,
    orgFormula: 0.06,
  };

  static const _specialistWeight = {
    'sp-daniyar': 3,
    'sp-arman': 2,
    'sp-saule': 3,
    'sp-erlan': 2,
    'sp-timur': 3,
    'sp-ruslan': 1,
  };

  static const _clientWeights = [
    (clientAliyaId, 'Алия Н.', 4),
    (clientZhannaId, 'Жанна Т.', 3),
    (clientIlyaId, 'Илья В.', 3),
    (clientDamirId, 'Дамир К.', 1),
  ];

  void run() {
    final today = now.dateOnly;
    _addScripted(today);
    for (
      var offset = -DemoSeed.historyDays;
      offset <= DemoSeed.futureDays;
      offset++
    ) {
      final day = today.add(Duration(days: offset));
      for (final MapEntry(key: organizationId, value: load)
          in _dailyLoad.entries) {
        final count = (load + random.nextDouble()).floor();
        for (var i = 0; i < count; i++) {
          _addRandomBooking(organizationId, day);
        }
      }
    }
  }

  void _addScripted(DateTime today) {
    const scripted = [
      ('svc-men-haircut', 'sp-arman', 1, 11, clientDamirId, 'Дамир К.', 0),
      (
        'svc-dental-consult',
        'sp-saule',
        3,
        15,
        clientDamirId,
        'Дамир К.',
        null,
      ),
      ('svc-manicure', 'sp-aliya', 2, 12, clientAliyaId, 'Алия Н.', 1),
    ];
    for (final (serviceId, specialistId, days, hour, clientId, name, option)
        in scripted) {
      final specialist = t.specialists[specialistId]!;
      var day = today.add(Duration(days: days));
      while (!specialist.worksOn(day)) {
        day = day.add(const Duration(days: 1));
      }
      _add(
        service: _service(serviceId),
        specialistId: specialistId,
        startAt: day.add(Duration(hours: hour)),
        clientId: clientId,
        clientName: name,
        option: option,
        status: BookingStatus.confirmed,
      );
    }
  }

  void _addRandomBooking(String organizationId, DateTime day) {
    final services = demoServices
        .where((s) => s.organizationId == organizationId)
        .toList();
    final service = services[random.nextInt(services.length)];
    final specialists = service.availableSpecialists
        .where((s) => s.worksOn(day))
        .toList();
    if (specialists.isEmpty) return;
    final specialist = _weightedSpecialist(specialists);
    final starts = schedule
        .startTimes(day, service.duration, specialist: specialist)
        .where((start) => !_isBusy(specialist, start, service.duration))
        .toList();
    if (starts.isEmpty) return;
    final (clientId, clientName, _) = _weightedClient();
    _add(
      service: service,
      specialistId: specialist.id,
      startAt: starts[random.nextInt(starts.length)],
      clientId: clientId,
      clientName: clientName,
      option: service.hasPriceOptions
          ? random.nextInt(service.priceOptions.length)
          : null,
    );
  }

  void _add({
    required Service service,
    required String specialistId,
    required DateTime startAt,
    required String clientId,
    required String clientName,
    int? option,
    BookingStatus? status,
  }) {
    final specialist = t.specialists[specialistId]!;
    if (_isBusy(specialist, startAt, service.duration)) return;
    final isPast = startAt.add(service.duration).isBefore(now);
    final roll = random.nextDouble();
    status ??= isPast
        ? (roll < 0.17 ? BookingStatus.cancelled : BookingStatus.completed)
        : (roll < 0.08 ? BookingStatus.cancelled : BookingStatus.confirmed);
    final createdAt = DemoSeed._min(
      startAt.subtract(Duration(days: 1 + random.nextInt(6), hours: 2)),
      now.subtract(const Duration(hours: 1)),
    );
    final priceOption = option == null ? null : service.priceOptions[option];
    final organization = t.organizations[service.organizationId]!;
    final id = 'booking-${t.nextCounter('booking')}';
    t.bookings[id] = Booking(
      id: id,
      ticketNumber: '${t.nextCounter('ticket', start: 101)}',
      clientId: clientId,
      clientName: clientName,
      organizationId: organization.id,
      organizationName: organization.name,
      serviceId: service.id,
      serviceTitle: service.title,
      specialist: specialist,
      startAt: startAt,
      duration: service.duration,
      priceKzt: priceOption?.priceKzt ?? service.priceKzt,
      priceLabel: priceOption?.label,
      comment: '',
      status: status,
      createdAt: createdAt,
      checkedInAt:
          status == BookingStatus.completed && random.nextDouble() < 0.7
          ? startAt.subtract(Duration(minutes: 5 + random.nextInt(15)))
          : null,
    );
  }

  bool _isBusy(Specialist specialist, DateTime start, Duration duration) {
    final end = start.add(duration);
    return t.bookings.values.any(
      (b) =>
          !b.isCancelled &&
          b.specialist.id == specialist.id &&
          b.overlaps(start, end),
    );
  }

  Specialist _weightedSpecialist(List<Specialist> specialists) {
    final weights = [for (final s in specialists) _specialistWeight[s.id] ?? 2];
    var roll = random.nextInt(weights.reduce((a, b) => a + b));
    for (var i = 0; i < specialists.length; i++) {
      roll -= weights[i];
      if (roll < 0) return specialists[i];
    }
    return specialists.last;
  }

  (String, String, int) _weightedClient() {
    final total = _clientWeights.fold(0, (sum, c) => sum + c.$3);
    var roll = random.nextInt(total);
    for (final client in _clientWeights) {
      roll -= client.$3;
      if (roll < 0) return client;
    }
    return _clientWeights.first;
  }

  static Service _service(String id) =>
      demoServices.firstWhere((s) => s.id == id);
}

class _ReviewProfile {
  const _ReviewProfile(this.share, this.ratingWeights);

  final double share;

  final List<int> ratingWeights;
}

const _reviewProfiles = {
  orgNorth: _ReviewProfile(0.55, [1, 1, 2, 8, 18]),
  orgWhiteLine: _ReviewProfile(0.6, [1, 2, 3, 9, 12]),
  orgGarage: _ReviewProfile(0.5, [2, 3, 5, 8, 6]),
  orgLavanda: _ReviewProfile(0.5, [0, 1, 1, 5, 10]),
  orgHealth: _ReviewProfile(0.4, [1, 1, 3, 6, 5]),
};

const _thanksReply = 'Спасибо за отзыв! Будем рады видеть вас снова.';
const _apologyReply =
    'Простите за неудобства. Передали замечание команде и пересмотрели '
    'расписание, чтобы такого не повторялось.';

const _reviewTexts = {
  5: [
    'Всё отлично, приду ещё.',
    'Приняли точно ко времени, результат понравился.',
    'Мастер внимательный, всё объяснил. Рекомендую.',
    'Быстро и аккуратно, удобно записываться через приложение.',
  ],
  4: [
    'Хорошо, но пришлось подождать минут десять.',
    'Результат понравился, но цена выше ожидаемой.',
    'В целом понравилось, приду ещё.',
  ],
  3: ['Нормально, без восторга.', 'Сделали, но почти ничего не объяснили.'],
  2: [
    'Начали почти на полчаса позже записи.',
    'За эти деньги хотелось большего.',
  ],
  1: [
    'Запись не нашли, пришлось долго ждать администратора.',
    'Не понравилось отношение к клиенту.',
  ],
};

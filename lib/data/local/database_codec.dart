import '../../features/auth/domain/app_user.dart';
import '../../features/booking/domain/booking.dart';
import '../../features/catalog/domain/organization.dart';
import '../../features/catalog/domain/service.dart';
import '../../features/favorites/domain/favorite.dart';
import '../../features/reviews/domain/review.dart';
import 'database_tables.dart';
import 'schema.dart';

abstract final class DatabaseCodec {
  static JsonMap encode(DatabaseTables t) => {
    'schemaVersion': latestSchemaVersion,
    'settings': _settings(t.settings),
    'users': [for (final u in t.users.values) _user(u)],
    'credentials': [
      for (final e in t.credentials.entries)
        {'userId': e.key, 'salt': e.value.salt, 'hash': e.value.hash},
    ],
    'organizations': [for (final o in t.organizations.values) _organization(o)],
    'specialists': [for (final s in t.specialists.values) _specialist(s)],
    'services': [for (final s in t.services.values) _service(s)],
    'photos': [for (final p in t.photos.values) _photo(p)],
    'bookings': [for (final b in t.bookings.values) _booking(b)],
    'reviews': [for (final r in t.reviews.values) _review(r)],
    'favorites': [for (final f in t.favorites.values) _favorite(f)],
  };

  static DatabaseTables decode(JsonMap data) {
    final t = DatabaseTables();
    _readSettings(t.settings, data['settings'] as JsonMap? ?? const {});
    for (final json in _list(data['users'])) {
      final user = _readUser(json);
      t.users[user.id] = user;
    }
    for (final json in _list(data['credentials'])) {
      t.credentials[json['userId']! as String] = StoredCredential(
        salt: json['salt']! as String,
        hash: json['hash']! as String,
      );
    }
    for (final json in _list(data['organizations'])) {
      final organization = _readOrganization(json);
      t.organizations[organization.id] = organization;
    }
    for (final json in _list(data['specialists'])) {
      final specialist = _readSpecialist(json);
      t.specialists[specialist.id] = specialist;
    }
    for (final json in _list(data['services'])) {
      final service = _readService(json, t.specialists);
      t.services[service.id] = service;
    }
    for (final json in _list(data['photos'])) {
      final photo = _readPhoto(json);
      t.photos[photo.id] = photo;
    }
    for (final json in _list(data['bookings'])) {
      final booking = _readBooking(json);
      t.bookings[booking.id] = booking;
    }
    for (final json in _list(data['reviews'])) {
      final review = _readReview(json);
      t.reviews[review.id] = review;
    }
    for (final json in _list(data['favorites'])) {
      final favorite = _readFavorite(json);
      t.favorites[favorite.key] = favorite;
    }
    return t;
  }

  static String date(DateTime value) => value.toUtc().toIso8601String();

  static DateTime readDate(Object? value) =>
      DateTime.parse(value! as String).toLocal();

  static DateTime? readOptionalDate(Object? value) =>
      value == null ? null : readDate(value);

  static Iterable<JsonMap> _list(Object? value) =>
      ((value as List?) ?? const []).cast<JsonMap>();

  static JsonMap _settings(DatabaseSettings s) => {
    'sessionUserId': s.sessionUserId,
    'darkTheme': s.darkTheme,
    'remindersEnabled': s.remindersEnabled,
    'seedVersion': s.seedVersion,
    'counters': s.counters,
  };

  static void _readSettings(DatabaseSettings s, JsonMap json) {
    s
      ..sessionUserId = json['sessionUserId'] as String?
      ..darkTheme = json['darkTheme'] as bool? ?? false
      ..remindersEnabled = json['remindersEnabled'] as bool? ?? true
      ..seedVersion = json['seedVersion'] as int? ?? 0;
    final counters = json['counters'] as Map<String, Object?>? ?? const {};
    s.counters.addAll(counters.map((k, v) => MapEntry(k, v! as int)));
  }

  static JsonMap _user(AppUser u) => {
    'id': u.id,
    'login': u.login,
    'displayName': u.displayName,
    'role': u.role.name,
    'organizationId': u.organizationId,
  };

  static AppUser _readUser(JsonMap json) => AppUser(
    id: json['id']! as String,
    login: json['login']! as String,
    displayName: json['displayName']! as String,
    role: UserRole.values.byName(json['role']! as String),
    organizationId: json['organizationId'] as String?,
  );

  static JsonMap _organization(Organization o) => {
    'id': o.id,
    'name': o.name,
    'category': o.category.name,
    'description': o.description,
    'address': o.address,
    'phone': o.phone,
    'artworkVariant': o.artworkVariant,
    'isPublished': o.isPublished,
  };

  static Organization _readOrganization(JsonMap json) => Organization(
    id: json['id']! as String,
    name: json['name']! as String,
    category: ServiceCategory.values.byName(json['category']! as String),
    description: json['description']! as String,
    address: json['address']! as String,
    phone: json['phone']! as String,
    artworkVariant: json['artworkVariant']! as int,
    isPublished: json['isPublished'] as bool? ?? true,
  );

  static JsonMap _specialist(Specialist s) => {
    'id': s.id,
    'organizationId': s.organizationId,
    'name': s.name,
    'role': s.role,
    'workingWeekdays': s.workingWeekdays.toList()..sort(),
  };

  static Specialist _readSpecialist(JsonMap json) => Specialist(
    id: json['id']! as String,
    organizationId: json['organizationId'] as String? ?? '',
    name: json['name']! as String,
    role: json['role']! as String,
    workingWeekdays: {
      for (final day in (json['workingWeekdays'] as List? ?? const []))
        day as int,
    },
  );

  static JsonMap _service(Service s) => {
    'id': s.id,
    'organizationId': s.organizationId,
    'title': s.title,
    'category': s.category.name,
    'description': s.description,
    'durationMinutes': s.duration.inMinutes,
    'priceKzt': s.priceKzt,
    'priceOptions': [
      for (final o in s.priceOptions)
        {'id': o.id, 'label': o.label, 'priceKzt': o.priceKzt},
    ],
    'specialistIds': [for (final sp in s.availableSpecialists) sp.id],
    'artworkVariant': s.artworkVariant,
    'isHidden': s.isHidden,
  };

  static Service _readService(
    JsonMap json,
    Map<String, Specialist> specialists,
  ) => Service(
    id: json['id']! as String,
    organizationId: json['organizationId'] as String? ?? '',
    title: json['title']! as String,
    category: ServiceCategory.values.byName(json['category']! as String),
    description: json['description']! as String,
    duration: Duration(minutes: json['durationMinutes']! as int),
    priceKzt: json['priceKzt']! as int,
    priceOptions: [
      for (final o in _list(json['priceOptions']))
        PriceOption(
          id: o['id']! as String,
          label: o['label']! as String,
          priceKzt: o['priceKzt']! as int,
        ),
    ],
    availableSpecialists: [
      for (final id in (json['specialistIds'] as List? ?? const []))
        ?specialists[id],
    ],
    artworkVariant: json['artworkVariant']! as int,
    isHidden: json['isHidden']! as bool,
  );

  static JsonMap _photo(BusinessPhoto p) => {
    'id': p.id,
    'organizationId': p.organizationId,
    'position': p.position,
    'addedAt': date(p.addedAt),
    'filePath': p.filePath,
    'illustrationVariant': p.illustrationVariant,
  };

  static BusinessPhoto _readPhoto(JsonMap json) => BusinessPhoto(
    id: json['id']! as String,
    organizationId: json['organizationId']! as String,
    position: json['position']! as int,
    addedAt: readDate(json['addedAt']),
    filePath: json['filePath'] as String?,
    illustrationVariant: json['illustrationVariant'] as int?,
  );

  static JsonMap _booking(Booking b) => {
    'id': b.id,
    'ticketNumber': b.ticketNumber,
    'clientId': b.clientId,
    'clientName': b.clientName,
    'organizationId': b.organizationId,
    'organizationName': b.organizationName,
    'serviceId': b.serviceId,
    'serviceTitle': b.serviceTitle,
    'specialist': _specialist(b.specialist),
    'startAt': date(b.startAt),
    'durationMinutes': b.duration.inMinutes,
    'priceKzt': b.priceKzt,
    'priceLabel': b.priceLabel,
    'comment': b.comment,
    'status': b.status.name,
    'createdAt': date(b.createdAt),
    'checkedInAt': b.checkedInAt == null ? null : date(b.checkedInAt!),
  };

  static Booking _readBooking(JsonMap json) => Booking(
    id: json['id']! as String,
    ticketNumber: json['ticketNumber']! as String,
    clientId: json['clientId']! as String,
    clientName: json['clientName']! as String,
    organizationId: json['organizationId']! as String,
    organizationName: json['organizationName']! as String,
    serviceId: json['serviceId']! as String,
    serviceTitle: json['serviceTitle']! as String,
    specialist: _readSpecialist(json['specialist']! as JsonMap),
    startAt: readDate(json['startAt']),
    duration: Duration(minutes: json['durationMinutes']! as int),
    priceKzt: json['priceKzt']! as int,
    priceLabel: json['priceLabel'] as String?,
    comment: json['comment']! as String,
    status: BookingStatus.values.byName(json['status']! as String),
    createdAt: readDate(json['createdAt']),
    checkedInAt: readOptionalDate(json['checkedInAt']),
  );

  static JsonMap _review(Review r) => {
    'id': r.id,
    'bookingId': r.bookingId,
    'organizationId': r.organizationId,
    'serviceId': r.serviceId,
    'serviceTitle': r.serviceTitle,
    'specialistId': r.specialistId,
    'authorId': r.authorId,
    'authorName': r.authorName,
    'rating': r.rating,
    'text': r.text,
    'createdAt': date(r.createdAt),
    'updatedAt': r.updatedAt == null ? null : date(r.updatedAt!),
    'reply': r.reply == null
        ? null
        : {'text': r.reply!.text, 'createdAt': date(r.reply!.createdAt)},
  };

  static Review _readReview(JsonMap json) {
    final reply = json['reply'] as JsonMap?;
    return Review(
      id: json['id']! as String,
      bookingId: json['bookingId']! as String,
      organizationId: json['organizationId']! as String,
      serviceId: json['serviceId']! as String,
      serviceTitle: json['serviceTitle']! as String,
      specialistId: json['specialistId']! as String,
      authorId: json['authorId']! as String,
      authorName: json['authorName']! as String,
      rating: json['rating']! as int,
      text: json['text']! as String,
      createdAt: readDate(json['createdAt']),
      updatedAt: readOptionalDate(json['updatedAt']),
      reply: reply == null
          ? null
          : ReviewReply(
              text: reply['text']! as String,
              createdAt: readDate(reply['createdAt']),
            ),
    );
  }

  static JsonMap _favorite(Favorite f) => {
    'userId': f.userId,
    'organizationId': f.organizationId,
    'createdAt': date(f.createdAt),
  };

  static Favorite _readFavorite(JsonMap json) => Favorite(
    userId: json['userId']! as String,
    organizationId: json['organizationId']! as String,
    createdAt: readDate(json['createdAt']),
  );
}

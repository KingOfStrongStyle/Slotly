import '../../features/auth/domain/app_user.dart';
import '../../features/booking/domain/booking.dart';
import '../../features/catalog/domain/organization.dart';
import '../../features/catalog/domain/service.dart';
import '../../features/favorites/domain/favorite.dart';
import '../../features/reviews/domain/review.dart';

/// Demo password stored as a salted hash. See `PasswordHasher`.
class StoredCredential {
  const StoredCredential({required this.salt, required this.hash});

  final String salt;
  final String hash;
}

/// Device-level values that are not business data.
class DatabaseSettings {
  String? sessionUserId;
  bool darkTheme = false;
  bool remindersEnabled = true;

  /// Version of the demo data set, so the seed runs exactly once.
  int seedVersion = 0;

  /// Counters for readable ids and ticket numbers ("booking-12", "143").
  final Map<String, int> counters = {};
}

/// All collections of the local database, keyed by id.
///
/// Only repositories change these maps, and only inside
/// `AppDatabase.update`, which persists the result and notifies listeners.
class DatabaseTables {
  final Map<String, AppUser> users = {};
  final Map<String, StoredCredential> credentials = {};
  final Map<String, Organization> organizations = {};
  final Map<String, Specialist> specialists = {};
  final Map<String, Service> services = {};
  final Map<String, BusinessPhoto> photos = {};
  final Map<String, Booking> bookings = {};
  final Map<String, Review> reviews = {};

  /// Keyed by [Favorite.key].
  final Map<String, Favorite> favorites = {};
  final DatabaseSettings settings = DatabaseSettings();

  bool get isEmpty => users.isEmpty && organizations.isEmpty;

  /// Next value of a named counter: 1, 2, 3…
  int nextCounter(String name, {int start = 1}) {
    final next = (settings.counters[name] ?? start - 1) + 1;
    settings.counters[name] = next;
    return next;
  }
}

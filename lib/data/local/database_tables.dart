import '../../features/auth/domain/app_user.dart';
import '../../features/booking/domain/booking.dart';
import '../../features/catalog/domain/organization.dart';
import '../../features/catalog/domain/service.dart';
import '../../features/favorites/domain/favorite.dart';
import '../../features/reviews/domain/review.dart';

class StoredCredential {
  const StoredCredential({required this.salt, required this.hash});

  final String salt;
  final String hash;
}

class DatabaseSettings {
  String? sessionUserId;
  bool darkTheme = false;
  bool remindersEnabled = true;

  int seedVersion = 0;

  final Map<String, int> counters = {};
}

class DatabaseTables {
  final Map<String, AppUser> users = {};
  final Map<String, StoredCredential> credentials = {};
  final Map<String, Organization> organizations = {};
  final Map<String, Specialist> specialists = {};
  final Map<String, Service> services = {};
  final Map<String, BusinessPhoto> photos = {};
  final Map<String, Booking> bookings = {};
  final Map<String, Review> reviews = {};

  final Map<String, Favorite> favorites = {};
  final DatabaseSettings settings = DatabaseSettings();

  bool get isEmpty => users.isEmpty && organizations.isEmpty;

  int nextCounter(String name, {int start = 1}) {
    final next = (settings.counters[name] ?? start - 1) + 1;
    settings.counters[name] = next;
    return next;
  }
}

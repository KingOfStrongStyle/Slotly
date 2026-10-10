import '../../catalog/domain/service.dart';

enum BookingStatus { confirmed, cancelled }

/// Whether a booking can be checked in at a given moment.
enum CheckInAvailability {
  available,
  alreadyCheckedIn,
  tooEarly,
  expired,
  cancelled,
}

class Booking {
  const Booking({
    required this.id,
    required this.ticketNumber,
    required this.serviceId,
    required this.serviceTitle,
    required this.specialist,
    required this.startAt,
    required this.duration,
    required this.comment,
    required this.status,
    required this.createdAt,
    this.checkedInAt,
  });

  /// Check-in opens this long before the visit and stays open until the
  /// visit ends.
  static const checkInOpensBefore = Duration(hours: 1);

  final String id;

  /// Short numeric code the customer shows or draws on arrival.
  final String ticketNumber;
  final String serviceId;

  /// Copied from the service at booking time, so the record stays readable
  /// even if the catalog entry is renamed later.
  final String serviceTitle;
  final Specialist specialist;
  final DateTime startAt;
  final Duration duration;

  /// Empty string when the customer left no comment.
  final String comment;
  final BookingStatus status;
  final DateTime createdAt;

  /// When the customer confirmed arrival; `null` until then.
  final DateTime? checkedInAt;

  DateTime get endAt => startAt.add(duration);

  DateTime get checkInOpensAt => startAt.subtract(checkInOpensBefore);

  bool get isActive => status == BookingStatus.confirmed;

  bool get isCheckedIn => checkedInAt != null;

  CheckInAvailability checkInAvailabilityAt(DateTime now) {
    if (!isActive) return CheckInAvailability.cancelled;
    if (isCheckedIn) return CheckInAvailability.alreadyCheckedIn;
    if (now.isBefore(checkInOpensAt)) return CheckInAvailability.tooEarly;
    if (!now.isBefore(endAt)) return CheckInAvailability.expired;
    return CheckInAvailability.available;
  }

  /// True if this booking and the interval `[start, end)` intersect.
  bool overlaps(DateTime start, DateTime end) =>
      startAt.isBefore(end) && start.isBefore(endAt);

  Booking copyWith({BookingStatus? status, DateTime? checkedInAt}) => Booking(
    id: id,
    ticketNumber: ticketNumber,
    serviceId: serviceId,
    serviceTitle: serviceTitle,
    specialist: specialist,
    startAt: startAt,
    duration: duration,
    comment: comment,
    status: status ?? this.status,
    createdAt: createdAt,
    checkedInAt: checkedInAt ?? this.checkedInAt,
  );

  /// Chronological order; ties are broken by id to keep the order stable.
  static int compareByStartAt(Booking a, Booking b) {
    final byTime = a.startAt.compareTo(b.startAt);
    return byTime != 0 ? byTime : a.id.compareTo(b.id);
  }

  @override
  String toString() =>
      'Booking($id, #$ticketNumber, $serviceTitle, $startAt, ${status.name})';
}

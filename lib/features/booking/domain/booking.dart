import '../../catalog/domain/service.dart';

/// `confirmed` — upcoming or not yet marked by the business;
/// `completed` — the business confirmed the visit took place;
/// `cancelled` — cancelled by the customer.
enum BookingStatus { confirmed, completed, cancelled }

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
    this.clientId = '',
    this.clientName = '',
    this.organizationId = '',
    this.organizationName = '',
    this.priceKzt = 0,
    this.priceLabel,
    this.checkedInAt,
  });

  /// Check-in opens this long before the visit and stays open until the
  /// visit ends.
  static const checkInOpensBefore = Duration(hours: 1);

  final String id;

  /// Short numeric code the customer shows or draws on arrival.
  final String ticketNumber;
  final String clientId;

  /// Copied at booking time so the business sees who is coming.
  final String clientName;
  final String organizationId;
  final String organizationName;
  final String serviceId;

  /// Copied from the service at booking time, so the record stays readable
  /// even if the catalog entry is renamed later.
  final String serviceTitle;
  final Specialist specialist;
  final DateTime startAt;
  final Duration duration;

  /// Price agreed at booking time, in tenge.
  final int priceKzt;

  /// Selected price option, for example "Длинные волосы".
  final String? priceLabel;

  /// Empty string when the customer left no comment.
  final String comment;
  final BookingStatus status;
  final DateTime createdAt;

  /// When the customer confirmed arrival; `null` until then.
  final DateTime? checkedInAt;

  DateTime get endAt => startAt.add(duration);

  DateTime get checkInOpensAt => startAt.subtract(checkInOpensBefore);

  /// Confirmed bookings occupy the specialist's time.
  bool get isActive => status == BookingStatus.confirmed;

  bool get isCompleted => status == BookingStatus.completed;

  bool get isCancelled => status == BookingStatus.cancelled;

  bool get isCheckedIn => checkedInAt != null;

  /// The customer may still move or cancel a visit that has not started.
  bool canBeChangedAt(DateTime now) =>
      isActive && !isCheckedIn && now.isBefore(startAt);

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

  Booking copyWith({
    BookingStatus? status,
    DateTime? checkedInAt,
    DateTime? startAt,
    Specialist? specialist,
    bool clearCheckIn = false,
  }) => Booking(
    id: id,
    ticketNumber: ticketNumber,
    clientId: clientId,
    clientName: clientName,
    organizationId: organizationId,
    organizationName: organizationName,
    serviceId: serviceId,
    serviceTitle: serviceTitle,
    specialist: specialist ?? this.specialist,
    startAt: startAt ?? this.startAt,
    duration: duration,
    priceKzt: priceKzt,
    priceLabel: priceLabel,
    comment: comment,
    status: status ?? this.status,
    createdAt: createdAt,
    checkedInAt: clearCheckIn ? null : checkedInAt ?? this.checkedInAt,
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

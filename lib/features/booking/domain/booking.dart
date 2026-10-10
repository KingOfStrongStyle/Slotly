import '../../catalog/domain/service.dart';

enum BookingStatus { confirmed, completed, cancelled }

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

  static const checkInOpensBefore = Duration(hours: 1);

  final String id;

  final String ticketNumber;
  final String clientId;

  final String clientName;
  final String organizationId;
  final String organizationName;
  final String serviceId;

  final String serviceTitle;
  final Specialist specialist;
  final DateTime startAt;
  final Duration duration;

  final int priceKzt;

  final String? priceLabel;

  final String comment;
  final BookingStatus status;
  final DateTime createdAt;

  final DateTime? checkedInAt;

  DateTime get endAt => startAt.add(duration);

  DateTime get checkInOpensAt => startAt.subtract(checkInOpensBefore);

  bool get isActive => status == BookingStatus.confirmed;

  bool get isCompleted => status == BookingStatus.completed;

  bool get isCancelled => status == BookingStatus.cancelled;

  bool get isCheckedIn => checkedInAt != null;

  bool canBeChangedAt(DateTime now) =>
      isActive && !isCheckedIn && now.isBefore(startAt);

  CheckInAvailability checkInAvailabilityAt(DateTime now) {
    if (!isActive) return CheckInAvailability.cancelled;
    if (isCheckedIn) return CheckInAvailability.alreadyCheckedIn;
    if (now.isBefore(checkInOpensAt)) return CheckInAvailability.tooEarly;
    if (!now.isBefore(endAt)) return CheckInAvailability.expired;
    return CheckInAvailability.available;
  }

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

  static int compareByStartAt(Booking a, Booking b) {
    final byTime = a.startAt.compareTo(b.startAt);
    return byTime != 0 ? byTime : a.id.compareTo(b.id);
  }

  @override
  String toString() =>
      'Booking($id, #$ticketNumber, $serviceTitle, $startAt, ${status.name})';
}

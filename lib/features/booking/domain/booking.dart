import '../../catalog/domain/service.dart';

enum BookingStatus { confirmed, cancelled }

class Booking {
  const Booking({
    required this.id,
    required this.serviceId,
    required this.serviceTitle,
    required this.specialist,
    required this.startAt,
    required this.duration,
    required this.comment,
    required this.status,
    required this.createdAt,
  });

  final String id;
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

  DateTime get endAt => startAt.add(duration);

  bool get isActive => status == BookingStatus.confirmed;

  /// True if this booking and the interval `[start, end)` intersect.
  bool overlaps(DateTime start, DateTime end) =>
      startAt.isBefore(end) && start.isBefore(endAt);

  Booking copyWith({BookingStatus? status}) => Booking(
    id: id,
    serviceId: serviceId,
    serviceTitle: serviceTitle,
    specialist: specialist,
    startAt: startAt,
    duration: duration,
    comment: comment,
    status: status ?? this.status,
    createdAt: createdAt,
  );

  /// Chronological order; ties are broken by id to keep the order stable.
  static int compareByStartAt(Booking a, Booking b) {
    final byTime = a.startAt.compareTo(b.startAt);
    return byTime != 0 ? byTime : a.id.compareTo(b.id);
  }

  @override
  String toString() => 'Booking($id, $serviceTitle, $startAt, ${status.name})';
}

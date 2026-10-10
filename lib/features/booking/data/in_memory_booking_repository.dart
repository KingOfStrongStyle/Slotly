import '../../../core/utils/clock.dart';
import '../../catalog/domain/service.dart';
import '../domain/booking.dart';
import '../domain/booking_repository.dart';
import '../domain/time_slot.dart';
import 'demo_schedule.dart';

/// [BookingRepository] that keeps bookings in memory for the current app
/// session. Data disappears when the process is closed.
class InMemoryBookingRepository implements BookingRepository {
  InMemoryBookingRepository({
    required this.clock,
    this.schedule = const DemoSchedule(),
    Iterable<Booking> initialBookings = const [],
  }) {
    for (final booking in initialBookings) {
      _bookings[booking.id] = booking;
      final ticket = int.tryParse(booking.ticketNumber);
      if (ticket != null && ticket > _lastTicket) _lastTicket = ticket;
    }
  }

  /// Tickets are numbered from 101: three digits are quick to draw and do
  /// not look like a queue position.
  static const firstTicketNumber = 101;

  final Clock clock;
  final DemoSchedule schedule;
  final Map<String, Booking> _bookings = {};
  int _lastId = 0;
  int _lastTicket = firstTicketNumber - 1;

  @override
  Future<List<Booking>> fetchBookings() async =>
      List.unmodifiable(_bookings.values);

  @override
  Future<List<TimeSlot>> fetchTimeSlots({
    required Service service,
    required Specialist specialist,
    required DateTime day,
  }) async => _slotsFor(service, specialist, day);

  @override
  Future<Booking> createBooking(BookingRequest request) async {
    final isAvailable = _slotsFor(
      request.service,
      request.specialist,
      request.startAt,
    ).any((slot) => slot.startAt == request.startAt && slot.isAvailable);
    if (!isAvailable) throw SlotUnavailableException(request.startAt);

    final booking = Booking(
      id: _generateId(),
      ticketNumber: '${++_lastTicket}',
      serviceId: request.service.id,
      serviceTitle: request.service.title,
      specialist: request.specialist,
      startAt: request.startAt,
      duration: request.service.duration,
      comment: request.comment,
      status: BookingStatus.confirmed,
      createdAt: clock(),
    );
    _bookings[booking.id] = booking;
    return booking;
  }

  @override
  Future<Booking> cancelBooking(String bookingId) async {
    final booking = _bookings[bookingId];
    if (booking == null) throw BookingNotFoundException(bookingId);
    final cancelled = booking.copyWith(status: BookingStatus.cancelled);
    _bookings[bookingId] = cancelled;
    return cancelled;
  }

  @override
  Future<Booking> checkIn(String ticketNumber) async {
    final booking = _bookings.values
        .where((b) => b.ticketNumber == ticketNumber)
        .firstOrNull;
    if (booking == null) throw TicketNotFoundException(ticketNumber);

    final now = clock();
    final availability = booking.checkInAvailabilityAt(now);
    if (availability != CheckInAvailability.available) {
      throw CheckInUnavailableException(booking, availability);
    }
    final checkedIn = booking.copyWith(checkedInAt: now);
    _bookings[booking.id] = checkedIn;
    return checkedIn;
  }

  List<TimeSlot> _slotsFor(
    Service service,
    Specialist specialist,
    DateTime day,
  ) {
    final earliestStart = clock().add(schedule.minimumLeadTime);
    return [
      for (final startAt in schedule.startTimes(day, service.duration))
        TimeSlot(
          startAt: startAt,
          isAvailable:
              !startAt.isBefore(earliestStart) &&
              !schedule.isTakenByOthers(specialist, startAt) &&
              !_hasOverlap(specialist, startAt, service.duration),
        ),
    ];
  }

  bool _hasOverlap(Specialist specialist, DateTime startAt, Duration length) {
    final endAt = startAt.add(length);
    return _bookings.values.any(
      (booking) =>
          booking.isActive &&
          booking.specialist == specialist &&
          booking.overlaps(startAt, endAt),
    );
  }

  String _generateId() {
    String id;
    do {
      id = 'booking-${++_lastId}';
    } while (_bookings.containsKey(id));
    return id;
  }
}

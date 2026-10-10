import '../../catalog/domain/service.dart';
import 'booking.dart';
import 'time_slot.dart';

/// Data needed to create a booking. Built from a complete `BookingDraft`.
class BookingRequest {
  const BookingRequest({
    required this.service,
    required this.specialist,
    required this.startAt,
    this.comment = '',
  });

  final Service service;
  final Specialist specialist;
  final DateTime startAt;
  final String comment;
}

/// Contract between the booking screens and the data source.
///
/// Today it is implemented by `InMemoryBookingRepository`. A future
/// `HttpBookingRepository` can implement the same methods on top of a REST
/// API without changes in the screens. Methods are asynchronous for the
/// same reason, even though the in-memory version answers immediately.
abstract interface class BookingRepository {
  /// Bookings of the current user in no particular order.
  Future<List<Booking>> fetchBookings();

  /// Start times of [day] for [service] with [specialist] and whether each
  /// one can still be booked.
  Future<List<TimeSlot>> fetchTimeSlots({
    required Service service,
    required Specialist specialist,
    required DateTime day,
  });

  /// Throws [SlotUnavailableException] if the time is no longer free.
  Future<Booking> createBooking(BookingRequest request);

  /// Marks the booking as cancelled. The record is kept, not deleted.
  /// Throws [BookingNotFoundException] for an unknown id.
  Future<Booking> cancelBooking(String bookingId);

  /// Confirms that the customer with [ticketNumber] has arrived.
  ///
  /// Throws [TicketNotFoundException] for an unknown number and
  /// [CheckInUnavailableException] when the booking cannot be checked in
  /// right now (see [Booking.checkInAvailabilityAt]).
  Future<Booking> checkIn(String ticketNumber);
}

class SlotUnavailableException implements Exception {
  const SlotUnavailableException(this.startAt);

  final DateTime startAt;

  @override
  String toString() => 'SlotUnavailableException($startAt)';
}

class BookingNotFoundException implements Exception {
  const BookingNotFoundException(this.bookingId);

  final String bookingId;

  @override
  String toString() => 'BookingNotFoundException($bookingId)';
}

class TicketNotFoundException implements Exception {
  const TicketNotFoundException(this.ticketNumber);

  final String ticketNumber;

  @override
  String toString() => 'TicketNotFoundException($ticketNumber)';
}

class CheckInUnavailableException implements Exception {
  const CheckInUnavailableException(this.booking, this.reason);

  final Booking booking;
  final CheckInAvailability reason;

  @override
  String toString() =>
      'CheckInUnavailableException(${booking.id}, ${reason.name})';
}

import 'package:flutter/foundation.dart';

import '../../catalog/domain/service.dart';
import 'booking.dart';
import 'time_slot.dart';

/// Data needed to create a booking. Built from a complete `BookingDraft`.
class BookingRequest {
  const BookingRequest({
    required this.service,
    required this.specialist,
    required this.startAt,
    this.priceOption,
    this.comment = '',
  });

  final Service service;
  final Specialist specialist;
  final DateTime startAt;

  /// Required when the service has a detailed price list.
  final PriceOption? priceOption;
  final String comment;

  int get priceKzt => priceOption?.priceKzt ?? service.priceKzt;
}

/// Contract between the booking screens and the data source.
///
/// Implemented by `LocalBookingRepository` today; an HTTP implementation
/// on top of a Django/DRF API can replace it without changes in screens.
/// Every method checks permissions itself, because hiding a button in the
/// UI is not protection.
abstract interface class BookingRepository {
  /// Fires after any change of bookings.
  Listenable get changes;

  /// Bookings of the signed-in customer in no particular order.
  Future<List<Booking>> fetchBookings();

  /// All bookings of [organizationId]; only its owner may read them.
  Future<List<Booking>> fetchOrganizationBookings(String organizationId);

  /// Start times of [day] for [service] with [specialist] and whether each
  /// one can still be booked. [ignoreBookingId] frees the time of the
  /// booking being moved.
  Future<List<TimeSlot>> fetchTimeSlots({
    required Service service,
    required Specialist specialist,
    required DateTime day,
    String? ignoreBookingId,
  });

  /// Throws [SlotUnavailableException] if the time is no longer free.
  Future<Booking> createBooking(BookingRequest request);

  /// Marks the booking as cancelled. The record is kept, not deleted.
  /// Throws [BookingNotFoundException] for an unknown id and
  /// [BookingLockedException] when the visit has started.
  Future<Booking> cancelBooking(String bookingId);

  /// Moves a booking to another time (and optionally specialist). Keeps the
  /// id and the ticket number.
  Future<Booking> rescheduleBooking(
    String bookingId, {
    required DateTime startAt,
    required Specialist specialist,
  });

  /// Confirms that the customer with [ticketNumber] has arrived. A customer
  /// checks in their own bookings, an owner checks in visitors of their
  /// organization at the reception desk.
  ///
  /// Throws [TicketNotFoundException] for a number outside the user's
  /// scope and [CheckInUnavailableException] when check-in is not possible
  /// right now (see [Booking.checkInAvailabilityAt]).
  Future<Booking> checkIn(String ticketNumber);

  /// Owner confirms that the visit took place; it can then be reviewed.
  Future<Booking> completeBooking(String bookingId);
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

/// The booking can no longer be changed: it has started, was checked in,
/// completed or cancelled.
class BookingLockedException implements Exception {
  const BookingLockedException(this.booking);

  final Booking booking;

  @override
  String toString() => 'BookingLockedException(${booking.id})';
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

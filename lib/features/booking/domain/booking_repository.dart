import 'package:flutter/foundation.dart';

import '../../catalog/domain/service.dart';
import 'booking.dart';
import 'time_slot.dart';

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

  final PriceOption? priceOption;
  final String comment;

  int get priceKzt => priceOption?.priceKzt ?? service.priceKzt;
}

abstract interface class BookingRepository {
  Listenable get changes;

  Future<List<Booking>> fetchBookings();

  Future<List<Booking>> fetchOrganizationBookings(String organizationId);

  Future<List<TimeSlot>> fetchTimeSlots({
    required Service service,
    required Specialist specialist,
    required DateTime day,
    String? ignoreBookingId,
  });

  Future<Booking> createBooking(BookingRequest request);

  Future<Booking> cancelBooking(String bookingId);

  Future<Booking> rescheduleBooking(
    String bookingId, {
    required DateTime startAt,
    required Specialist specialist,
  });

  Future<Booking> checkIn(String ticketNumber);

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

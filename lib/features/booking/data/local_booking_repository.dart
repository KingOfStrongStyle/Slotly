import 'package:flutter/foundation.dart';

import '../../../core/access/access_policy.dart';
import '../../../data/local/database_tables.dart';
import '../../../data/local/local_context.dart';
import '../../catalog/domain/service.dart';
import '../domain/booking.dart';
import '../domain/booking_repository.dart';
import '../domain/time_slot.dart';
import 'demo_schedule.dart';

/// [BookingRepository] on top of the local database.
class LocalBookingRepository implements BookingRepository {
  const LocalBookingRepository(
    this._context, {
    this.schedule = const DemoSchedule(),
  });

  /// Tickets are numbered from 101: three digits are quick to draw and do
  /// not look like a queue position.
  static const firstTicketNumber = 101;

  final LocalContext _context;
  final DemoSchedule schedule;

  DatabaseTables get _tables => _context.database.tables;

  @override
  Listenable get changes => _context.database;

  @override
  Future<List<Booking>> fetchBookings() async {
    _context.require(AppAction.viewOwnBookings);
    final userId = _context.user!.id;
    return [
      for (final booking in _tables.bookings.values)
        if (booking.clientId == userId) booking,
    ];
  }

  @override
  Future<List<Booking>> fetchOrganizationBookings(String organizationId) async {
    _context.require(
      AppAction.viewOrganizationBookings,
      organizationId: organizationId,
    );
    return [
      for (final booking in _tables.bookings.values)
        if (booking.organizationId == organizationId) booking,
    ];
  }

  @override
  Future<List<TimeSlot>> fetchTimeSlots({
    required Service service,
    required Specialist specialist,
    required DateTime day,
    String? ignoreBookingId,
  }) async {
    _context.require(AppAction.browseCatalog);
    return _slotsFor(service, specialist, day, ignoreBookingId);
  }

  @override
  Future<Booking> createBooking(BookingRequest request) async {
    _context.require(AppAction.createBooking);
    final user = _context.user!;
    final service = _tables.services[request.service.id];
    final organization = service == null
        ? null
        : _tables.organizations[service.organizationId];
    if (service == null || organization == null || service.isHidden) {
      throw RecordNotFoundException('service', request.service.id);
    }
    if (service.hasPriceOptions &&
        !service.priceOptions.contains(request.priceOption)) {
      throw ArgumentError.value(request.priceOption, 'priceOption');
    }
    if (!_isFree(service, request.specialist, request.startAt)) {
      throw SlotUnavailableException(request.startAt);
    }

    return _context.database.update((t) {
      final id = 'booking-${t.nextCounter('booking')}';
      final booking = Booking(
        id: id,
        ticketNumber: '${t.nextCounter('ticket', start: firstTicketNumber)}',
        clientId: user.id,
        clientName: user.displayName,
        organizationId: organization.id,
        organizationName: organization.name,
        serviceId: service.id,
        serviceTitle: service.title,
        specialist: request.specialist,
        startAt: request.startAt,
        duration: service.duration,
        priceKzt: request.priceKzt,
        priceLabel: request.priceOption?.label,
        comment: request.comment,
        status: BookingStatus.confirmed,
        createdAt: _context.clock(),
      );
      t.bookings[id] = booking;
      return booking;
    });
  }

  @override
  Future<Booking> cancelBooking(String bookingId) async {
    final booking = _ownBooking(bookingId);
    if (!booking.canBeChangedAt(_context.clock())) {
      throw BookingLockedException(booking);
    }
    return _save(booking.copyWith(status: BookingStatus.cancelled));
  }

  @override
  Future<Booking> rescheduleBooking(
    String bookingId, {
    required DateTime startAt,
    required Specialist specialist,
  }) async {
    final booking = _ownBooking(bookingId);
    if (!booking.canBeChangedAt(_context.clock())) {
      throw BookingLockedException(booking);
    }
    final service = _tables.services[booking.serviceId];
    if (service == null || !service.availableSpecialists.contains(specialist)) {
      throw RecordNotFoundException('service', booking.serviceId);
    }
    if (!_isFree(service, specialist, startAt, ignoreBookingId: bookingId)) {
      throw SlotUnavailableException(startAt);
    }
    return _save(booking.copyWith(startAt: startAt, specialist: specialist));
  }

  @override
  Future<Booking> checkIn(String ticketNumber) async {
    final user = _context.user;
    final Booking? booking;
    if (user != null && user.isOwner) {
      _context.require(
        AppAction.manageOrganizationBookings,
        organizationId: user.organizationId,
      );
      booking = _findByTicket(
        ticketNumber,
        (b) => b.organizationId == user.organizationId,
      );
    } else {
      _context.require(AppAction.checkInOwnBooking);
      booking = _findByTicket(ticketNumber, (b) => b.clientId == user!.id);
    }
    if (booking == null) throw TicketNotFoundException(ticketNumber);

    final now = _context.clock();
    final availability = booking.checkInAvailabilityAt(now);
    if (availability != CheckInAvailability.available) {
      throw CheckInUnavailableException(booking, availability);
    }
    return _save(booking.copyWith(checkedInAt: now));
  }

  @override
  Future<Booking> completeBooking(String bookingId) async {
    final booking = _tables.bookings[bookingId];
    if (booking == null) throw BookingNotFoundException(bookingId);
    _context.require(
      AppAction.manageOrganizationBookings,
      organizationId: booking.organizationId,
    );
    if (!booking.isActive || _context.clock().isBefore(booking.startAt)) {
      throw BookingLockedException(booking);
    }
    return _save(booking.copyWith(status: BookingStatus.completed));
  }

  /// A booking of the signed-in customer; others are reported as missing.
  Booking _ownBooking(String bookingId) {
    final booking = _tables.bookings[bookingId];
    _context.require(
      AppAction.changeOwnBooking,
      resourceOwnerId: booking?.clientId,
    );
    if (booking == null) throw BookingNotFoundException(bookingId);
    return booking;
  }

  Booking? _findByTicket(String number, bool Function(Booking) inScope) =>
      _tables.bookings.values
          .where((b) => b.ticketNumber == number && inScope(b))
          .firstOrNull;

  Future<Booking> _save(Booking booking) => _context.database.update((t) {
    t.bookings[booking.id] = booking;
    return booking;
  });

  bool _isFree(
    Service service,
    Specialist specialist,
    DateTime startAt, {
    String? ignoreBookingId,
  }) => _slotsFor(
    service,
    specialist,
    startAt,
    ignoreBookingId,
  ).any((slot) => slot.startAt == startAt && slot.isAvailable);

  List<TimeSlot> _slotsFor(
    Service service,
    Specialist specialist,
    DateTime day,
    String? ignoreBookingId,
  ) {
    final earliestStart = _context.clock().add(schedule.minimumLeadTime);
    return [
      for (final startAt in schedule.startTimes(
        day,
        service.duration,
        specialist: specialist,
      ))
        TimeSlot(
          startAt: startAt,
          isAvailable:
              !startAt.isBefore(earliestStart) &&
              !_hasOverlap(
                specialist,
                startAt,
                service.duration,
                ignoreBookingId,
              ),
        ),
    ];
  }

  bool _hasOverlap(
    Specialist specialist,
    DateTime startAt,
    Duration length,
    String? ignoreBookingId,
  ) {
    final endAt = startAt.add(length);
    return _tables.bookings.values.any(
      (booking) =>
          booking.id != ignoreBookingId &&
          booking.isActive &&
          booking.specialist == specialist &&
          booking.overlaps(startAt, endAt),
    );
  }
}

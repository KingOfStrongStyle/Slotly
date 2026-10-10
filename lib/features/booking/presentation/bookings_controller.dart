import 'package:flutter/foundation.dart';

import '../../catalog/domain/service.dart';
import '../domain/booking.dart';
import '../domain/booking_repository.dart';
import '../domain/time_slot.dart';

/// Bookings of the signed-in customer, shared by all customer screens.
///
/// Screens read [active], [past] and [cancelled] and call the actions;
/// they never change the list themselves. The controller reloads after any
/// change in the repository, so a booking changed on another screen (or by
/// the owner) is shown everywhere.
class BookingsController extends ChangeNotifier {
  BookingsController(this._repository) {
    _repository.changes.addListener(load);
  }

  final BookingRepository _repository;
  List<Booking> _bookings = const [];
  bool _isLoading = false;
  bool _hasLoadError = false;
  bool _isDisposed = false;

  bool get isLoading => _isLoading;
  bool get hasLoadError => _hasLoadError;
  List<Booking> get all => _bookings;

  /// Upcoming confirmed bookings, nearest first.
  List<Booking> get active =>
      _bookings.where((b) => b.isActive).toList()
        ..sort(Booking.compareByStartAt);

  /// Completed visits, latest first.
  List<Booking> get past =>
      _bookings.where((b) => b.isCompleted).toList()
        ..sort((a, b) => Booking.compareByStartAt(b, a));

  /// Cancelled bookings, latest first.
  List<Booking> get cancelled =>
      _bookings.where((b) => b.isCancelled).toList()
        ..sort((a, b) => Booking.compareByStartAt(b, a));

  Booking? byId(String id) => _bookings.where((b) => b.id == id).firstOrNull;

  Future<void> load() async {
    _isLoading = true;
    _hasLoadError = false;
    _notify();
    try {
      _bookings = await _repository.fetchBookings();
    } on Exception {
      _hasLoadError = true;
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  Future<List<TimeSlot>> fetchTimeSlots({
    required Service service,
    required Specialist specialist,
    required DateTime day,
    String? ignoreBookingId,
  }) => _repository.fetchTimeSlots(
    service: service,
    specialist: specialist,
    day: day,
    ignoreBookingId: ignoreBookingId,
  );

  /// Throws [SlotUnavailableException] if the slot was taken meanwhile.
  Future<Booking> book(BookingRequest request) =>
      _repository.createBooking(request);

  Future<Booking> reschedule(
    Booking booking, {
    required DateTime startAt,
    required Specialist specialist,
  }) => _repository.rescheduleBooking(
    booking.id,
    startAt: startAt,
    specialist: specialist,
  );

  /// Throws [TicketNotFoundException] or [CheckInUnavailableException]
  /// when the customer cannot be checked in.
  Future<Booking> checkIn(String ticketNumber) =>
      _repository.checkIn(ticketNumber);

  Future<void> cancel(String bookingId) => _repository.cancelBooking(bookingId);

  void _notify() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _repository.changes.removeListener(load);
    super.dispose();
  }
}

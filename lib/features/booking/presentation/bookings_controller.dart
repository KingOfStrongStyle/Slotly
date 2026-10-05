import 'package:flutter/foundation.dart';

import '../../catalog/domain/service.dart';
import '../domain/booking.dart';
import '../domain/booking_repository.dart';
import '../domain/time_slot.dart';

/// Shared state of the user's bookings for all screens.
///
/// Screens read [active] and [cancelled] and call [book] or [cancel]; they
/// never change the list themselves. The controller talks only to the
/// [BookingRepository] contract, so the data source can be replaced.
class BookingsController extends ChangeNotifier {
  BookingsController(this._repository);

  final BookingRepository _repository;
  List<Booking> _bookings = const [];
  bool _isLoading = false;
  bool _hasLoadError = false;

  bool get isLoading => _isLoading;
  bool get hasLoadError => _hasLoadError;

  /// Confirmed bookings, nearest first.
  List<Booking> get active =>
      _bookings.where((b) => b.isActive).toList()
        ..sort(Booking.compareByStartAt);

  /// Cancelled bookings, latest first.
  List<Booking> get cancelled =>
      _bookings.where((b) => !b.isActive).toList()
        ..sort((a, b) => Booking.compareByStartAt(b, a));

  Future<void> load() async {
    _isLoading = true;
    _hasLoadError = false;
    notifyListeners();
    try {
      _bookings = await _repository.fetchBookings();
    } on Exception {
      _hasLoadError = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<TimeSlot>> fetchTimeSlots({
    required Service service,
    required Specialist specialist,
    required DateTime day,
  }) => _repository.fetchTimeSlots(
    service: service,
    specialist: specialist,
    day: day,
  );

  /// Throws [SlotUnavailableException] if the slot was taken meanwhile.
  Future<Booking> book(BookingRequest request) async {
    final booking = await _repository.createBooking(request);
    _bookings = [..._bookings, booking];
    notifyListeners();
    return booking;
  }

  Future<void> cancel(String bookingId) async {
    final cancelled = await _repository.cancelBooking(bookingId);
    _bookings = [
      for (final booking in _bookings)
        booking.id == bookingId ? cancelled : booking,
    ];
    notifyListeners();
  }
}

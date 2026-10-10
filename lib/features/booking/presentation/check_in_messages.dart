import '../../../core/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../domain/booking.dart';
import '../domain/booking_repository.dart';

/// Explains why [BookingsController.checkIn] failed. Shared by the
/// handwritten check-in screen and the "Я на месте" button.
String checkInErrorMessage(Object error) => switch (error) {
  TicketNotFoundException(:final ticketNumber) => AppStrings.checkInNotFound(
    ticketNumber,
  ),
  CheckInUnavailableException(:final booking, :final reason) =>
    switch (reason) {
      CheckInAvailability.alreadyCheckedIn => AppStrings.checkInAlready(
        booking.ticketNumber,
        Formatters.time(booking.checkedInAt!),
      ),
      CheckInAvailability.tooEarly => AppStrings.checkInTooEarly(
        booking.ticketNumber,
        Formatters.dateTime(booking.checkInOpensAt),
      ),
      CheckInAvailability.expired => AppStrings.checkInExpired(
        booking.ticketNumber,
      ),
      CheckInAvailability.cancelled => AppStrings.checkInCancelled(
        booking.ticketNumber,
      ),
      CheckInAvailability.available => AppStrings.checkInFailed,
    },
  _ => AppStrings.checkInFailed,
};

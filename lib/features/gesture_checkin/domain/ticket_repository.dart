import 'ticket.dart';

/// Source of electronic queue tickets. A backend implementation can replace
/// `MockTicketRepository` without changes in the check-in screen.
abstract interface class TicketRepository {
  /// Returns `null` when there is no ticket with this number.
  Future<Ticket?> findByNumber(String number);
}

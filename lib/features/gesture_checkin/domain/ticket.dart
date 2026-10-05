enum TicketStatus { waiting, called, completed }

/// Electronic queue ticket that a customer confirms on arrival.
class Ticket {
  const Ticket({
    required this.number,
    required this.customerName,
    required this.serviceTitle,
    required this.status,
    required this.peopleAhead,
  });

  final String number;
  final String customerName;
  final String serviceTitle;
  final TicketStatus status;
  final int peopleAhead;
}

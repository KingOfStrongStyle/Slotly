import '../domain/ticket.dart';
import '../domain/ticket_repository.dart';

/// Demonstration queue. Customers are fictional.
const demoTickets = <Ticket>[
  Ticket(
    number: '7',
    customerName: 'Демо-клиент Б.',
    serviceTitle: 'Консультация стоматолога',
    status: TicketStatus.called,
    peopleAhead: 0,
  ),
  Ticket(
    number: '17',
    customerName: 'Демо-клиент А.',
    serviceTitle: 'Мужская стрижка',
    status: TicketStatus.waiting,
    peopleAhead: 2,
  ),
  Ticket(
    number: '42',
    customerName: 'Демо-клиент В.',
    serviceTitle: 'Замена моторного масла',
    status: TicketStatus.waiting,
    peopleAhead: 0,
  ),
  Ticket(
    number: '305',
    customerName: 'Демо-клиент Г.',
    serviceTitle: 'Приём терапевта',
    status: TicketStatus.completed,
    peopleAhead: 0,
  ),
];

class MockTicketRepository implements TicketRepository {
  const MockTicketRepository({this.tickets = demoTickets});

  final List<Ticket> tickets;

  @override
  Future<Ticket?> findByNumber(String number) async {
    for (final ticket in tickets) {
      if (ticket.number == number) return ticket;
    }
    return null;
  }
}

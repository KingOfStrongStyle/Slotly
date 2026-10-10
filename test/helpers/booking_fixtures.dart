import 'package:slotly/features/booking/domain/booking.dart';
import 'package:slotly/features/catalog/data/demo_services.dart';

/// Demo booking for widget tests. All values are fictional.
Booking fixtureBooking({
  required String id,
  required DateTime startAt,
  String ticketNumber = '101',
  String serviceId = 'svc-men-haircut',
  BookingStatus status = BookingStatus.confirmed,
}) {
  final service = demoServices.firstWhere((s) => s.id == serviceId);
  return Booking(
    id: id,
    ticketNumber: ticketNumber,
    serviceId: service.id,
    serviceTitle: service.title,
    specialist: service.availableSpecialists.first,
    startAt: startAt,
    duration: service.duration,
    comment: '',
    status: status,
    createdAt: DateTime(2026, 10, 1, 12),
  );
}

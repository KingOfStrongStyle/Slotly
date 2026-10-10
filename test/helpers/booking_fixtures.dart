import 'package:slotly/data/seed/demo_accounts.dart';
import 'package:slotly/data/seed/demo_catalog.dart';
import 'package:slotly/features/booking/domain/booking.dart';

/// Demo booking for widget tests. All values are fictional.
Booking fixtureBooking({
  required String id,
  required DateTime startAt,
  String ticketNumber = '101',
  String serviceId = 'svc-men-haircut',
  String clientId = clientAliyaId,
  BookingStatus status = BookingStatus.confirmed,
  DateTime? checkedInAt,
}) {
  final service = demoServices.firstWhere((s) => s.id == serviceId);
  final organization = demoOrganizations.firstWhere(
    (o) => o.id == service.organizationId,
  );
  return Booking(
    id: id,
    ticketNumber: ticketNumber,
    clientId: clientId,
    clientName: 'Алия Н.',
    organizationId: organization.id,
    organizationName: organization.name,
    serviceId: service.id,
    serviceTitle: service.title,
    specialist: service.availableSpecialists.first,
    startAt: startAt,
    duration: service.duration,
    priceKzt: service.priceKzt,
    comment: '',
    status: status,
    createdAt: DateTime(2026, 10, 1, 12),
    checkedInAt: checkedInAt,
  );
}

import 'package:flutter_test/flutter_test.dart';
import 'package:slotly/features/booking/domain/booking.dart';
import 'package:slotly/features/catalog/domain/service.dart';

Booking _booking(String id, DateTime startAt) => Booking(
  id: id,
  serviceId: 'svc',
  serviceTitle: 'Стрижка',
  specialist: const Specialist(id: 'sp', name: 'Мастер', role: 'Барбер'),
  startAt: startAt,
  duration: const Duration(minutes: 45),
  comment: '',
  status: BookingStatus.confirmed,
  createdAt: DateTime(2026, 10, 1),
);

void main() {
  test('compareByStartAt sorts chronologically with stable ties', () {
    final late = _booking('b', DateTime(2026, 10, 7, 12));
    final early = _booking('c', DateTime(2026, 10, 6, 10));
    final sameTime = _booking('a', DateTime(2026, 10, 7, 12));

    final sorted = [late, early, sameTime]..sort(Booking.compareByStartAt);

    expect(sorted.map((b) => b.id), ['c', 'a', 'b']);
  });

  test('copyWith changes status and keeps other fields', () {
    final booking = _booking('a', DateTime(2026, 10, 7, 12));
    final cancelled = booking.copyWith(status: BookingStatus.cancelled);

    expect(cancelled.isActive, isFalse);
    expect(cancelled.id, booking.id);
    expect(cancelled.startAt, booking.startAt);
    expect(booking.isActive, isTrue);
  });

  test('overlaps uses half-open intervals', () {
    final booking = _booking('a', DateTime(2026, 10, 7, 12));

    expect(booking.endAt, DateTime(2026, 10, 7, 12, 45));
    expect(
      booking.overlaps(
        DateTime(2026, 10, 7, 12, 30),
        DateTime(2026, 10, 7, 13),
      ),
      isTrue,
    );
    expect(
      booking.overlaps(
        DateTime(2026, 10, 7, 12, 45),
        DateTime(2026, 10, 7, 14),
      ),
      isFalse,
      reason: 'a slot may start exactly when the previous one ends',
    );
    expect(
      booking.overlaps(DateTime(2026, 10, 7, 11), DateTime(2026, 10, 7, 12)),
      isFalse,
    );
  });
}

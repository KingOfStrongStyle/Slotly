import 'package:flutter_test/flutter_test.dart';
import 'package:slotly/data/seed/demo_catalog.dart';
import 'package:slotly/features/booking/domain/booking_draft.dart';
import 'package:slotly/features/booking/domain/time_slot.dart';

void main() {
  final service = demoServices.firstWhere((s) => s.id == 'svc-beard');
  final withOptions = demoServices.firstWhere((s) => s.id == 'svc-men-haircut');
  final specialist = service.availableSpecialists.first;
  final day = DateTime(2026, 10, 6);
  final freeSlot = TimeSlot(
    startAt: DateTime(2026, 10, 6, 12),
    isAvailable: true,
  );

  test('an empty draft lists every missing field', () {
    final draft = BookingDraft(service: service);

    expect(draft.issues, [
      BookingDraftIssue.specialistMissing,
      BookingDraftIssue.dateMissing,
      BookingDraftIssue.timeMissing,
    ]);
    expect(draft.isComplete, isFalse);
    expect(draft.toRequest, throwsStateError);
  });

  test('a complete draft produces a request with a trimmed comment', () {
    final draft = BookingDraft(service: service)
        .withSpecialist(specialist)
        .withDay(day)
        .withSlot(freeSlot)
        .withComment('  Нужна парковка  ');

    expect(draft.isComplete, isTrue);
    final request = draft.toRequest();
    expect(request.startAt, freeSlot.startAt);
    expect(request.specialist, specialist);
    expect(request.comment, 'Нужна парковка');
  });

  test('changing specialist or day resets the selected time', () {
    final draft = BookingDraft(service: service)
        .withSpecialist(specialist)
        .withDay(day)
        .withSlot(freeSlot);

    expect(
      draft.withSpecialist(service.availableSpecialists.last).slot,
      isNull,
    );
    expect(draft.withDay(DateTime(2026, 10, 7, 15)).slot, isNull);
    expect(draft.withDay(DateTime(2026, 10, 7, 15)).day, DateTime(2026, 10, 7));
  });

  test('an unavailable slot is never accepted', () {
    final draft = BookingDraft(service: service)
        .withSpecialist(specialist)
        .withDay(day)
        .withSlot(
          TimeSlot(startAt: DateTime(2026, 10, 6, 13), isAvailable: false),
        );

    expect(draft.issues, [BookingDraftIssue.timeUnavailable]);
    expect(draft.toRequest, throwsStateError);
  });

  test('comment longer than the limit is an issue', () {
    final draft = BookingDraft(service: service)
        .withSpecialist(specialist)
        .withDay(day)
        .withSlot(freeSlot)
        .withComment('a' * (BookingDraft.maxCommentLength + 1));

    expect(draft.issues, [BookingDraftIssue.commentTooLong]);
  });

  test('a service with a price list needs a chosen option', () {
    final draft = BookingDraft(service: withOptions)
        .withSpecialist(withOptions.availableSpecialists.first)
        .withDay(day)
        .withSlot(freeSlot);
    expect(draft.issues, [BookingDraftIssue.priceOptionMissing]);

    final option = withOptions.priceOptions.last;
    final complete = draft.withPriceOption(option);
    expect(complete.isComplete, isTrue);
    final request = complete.toRequest();
    expect(request.priceOption, option);
    expect(request.priceKzt, option.priceKzt);
  });

  test('the chosen option survives changing specialist and day', () {
    final option = withOptions.priceOptions.first;
    final draft = BookingDraft(service: withOptions)
        .withPriceOption(option)
        .withSpecialist(withOptions.availableSpecialists.last)
        .withDay(day.add(const Duration(days: 1)));
    expect(draft.priceOption, option);
  });
}

import '../../catalog/domain/service.dart';
import 'booking_repository.dart';
import 'time_slot.dart';

enum BookingDraftIssue {
  priceOptionMissing,
  specialistMissing,
  dateMissing,
  timeMissing,
  timeUnavailable,
  commentTooLong,
}

class BookingDraft {
  const BookingDraft({
    required this.service,
    this.specialist,
    this.day,
    this.slot,
    this.priceOption,
    this.comment = '',
  });

  static const maxCommentLength = 200;

  final Service service;
  final Specialist? specialist;
  final DateTime? day;
  final TimeSlot? slot;

  final PriceOption? priceOption;
  final String comment;

  BookingDraft withSpecialist(Specialist value) => BookingDraft(
    service: service,
    specialist: value,
    day: day,
    priceOption: priceOption,
    comment: comment,
  );

  BookingDraft withDay(DateTime value) => BookingDraft(
    service: service,
    specialist: specialist,
    day: DateTime(value.year, value.month, value.day),
    priceOption: priceOption,
    comment: comment,
  );

  BookingDraft withSlot(TimeSlot? value) => BookingDraft(
    service: service,
    specialist: specialist,
    day: day,
    slot: value,
    priceOption: priceOption,
    comment: comment,
  );

  BookingDraft withPriceOption(PriceOption value) => BookingDraft(
    service: service,
    specialist: specialist,
    day: day,
    slot: slot,
    priceOption: value,
    comment: comment,
  );

  BookingDraft withComment(String value) => BookingDraft(
    service: service,
    specialist: specialist,
    day: day,
    slot: slot,
    priceOption: priceOption,
    comment: value,
  );

  List<BookingDraftIssue> get issues {
    final slot = this.slot;
    return [
      if (service.hasPriceOptions && priceOption == null)
        BookingDraftIssue.priceOptionMissing,
      if (specialist == null) BookingDraftIssue.specialistMissing,
      if (day == null) BookingDraftIssue.dateMissing,
      if (slot == null) BookingDraftIssue.timeMissing,
      if (slot != null && !slot.isAvailable) BookingDraftIssue.timeUnavailable,
      if (comment.trim().length > maxCommentLength)
        BookingDraftIssue.commentTooLong,
    ];
  }

  bool get isComplete => issues.isEmpty;

  BookingRequest toRequest() {
    final specialist = this.specialist;
    final slot = this.slot;
    if (!isComplete || specialist == null || slot == null) {
      throw StateError('Booking draft is incomplete: $issues');
    }
    return BookingRequest(
      service: service,
      specialist: specialist,
      startAt: slot.startAt,
      priceOption: priceOption,
      comment: comment.trim(),
    );
  }
}

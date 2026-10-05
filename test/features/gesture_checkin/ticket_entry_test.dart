import 'package:flutter_test/flutter_test.dart';
import 'package:slotly/features/gesture_checkin/data/mock_ticket_repository.dart';
import 'package:slotly/features/gesture_checkin/data/symbol_templates.dart';
import 'package:slotly/features/gesture_checkin/domain/gesture_template.dart';
import 'package:slotly/features/gesture_checkin/domain/ticket.dart';
import 'package:slotly/features/gesture_checkin/domain/ticket_entry.dart';

GestureRecognitionResult accepted(String label) =>
    GestureRecognitionResult(label: label, confidence: 0.9, isAccepted: true);

void main() {
  const empty = TicketEntry(finishSymbol: finishSymbol);

  group('TicketEntry', () {
    test('appends recognized digits', () {
      final (one, outcome) = empty.apply(accepted('1'));
      final (seventeen, _) = one.apply(accepted('7'));

      expect(outcome, TicketEntryOutcome.digitAdded);
      expect(seventeen.number, '17');
      expect(seventeen.isCompleted, isFalse);
    });

    test('S completes a non-empty number', () {
      final (entry, _) = empty.apply(accepted('4'));
      final (completed, outcome) = entry.apply(accepted(finishSymbol));

      expect(outcome, TicketEntryOutcome.completed);
      expect(completed.isCompleted, isTrue);
      expect(completed.number, '4');
    });

    test('S on an empty number is refused', () {
      final (entry, outcome) = empty.apply(accepted(finishSymbol));

      expect(outcome, TicketEntryOutcome.numberEmpty);
      expect(entry.isCompleted, isFalse);
    });

    test('low confidence result does not change the number', () {
      const rejected = GestureRecognitionResult(
        label: '5',
        confidence: 0.3,
        isAccepted: false,
      );
      final (entry, outcome) = empty.apply(rejected);

      expect(outcome, TicketEntryOutcome.notRecognized);
      expect(entry.number, isEmpty);
    });

    test('number length is limited', () {
      var entry = empty;
      for (var i = 0; i < TicketEntry.maxDigits; i++) {
        (entry, _) = entry.apply(accepted('9'));
      }
      final (same, outcome) = entry.apply(accepted('1'));

      expect(outcome, TicketEntryOutcome.numberTooLong);
      expect(same.number, '9999');
    });

    test('backspace and clear', () {
      final (entry, _) = empty.apply(accepted('3'));
      final (longer, _) = entry.apply(accepted('5'));

      expect(longer.removeLastDigit().number, '3');
      expect(empty.removeLastDigit().number, isEmpty);
      expect(longer.cleared().number, isEmpty);
    });
  });

  group('MockTicketRepository', () {
    const repository = MockTicketRepository();

    test('finds a demo ticket by number', () async {
      final ticket = await repository.findByNumber('17');

      expect(ticket, isNotNull);
      expect(ticket!.status, TicketStatus.waiting);
      expect(ticket.peopleAhead, 2);
    });

    test('returns null for an unknown number', () async {
      expect(await repository.findByNumber('9999'), isNull);
      expect(await repository.findByNumber('017'), isNull);
    });

    test('demo tickets have unique numbers', () {
      final numbers = demoTickets.map((t) => t.number).toSet();
      expect(numbers.length, demoTickets.length);
    });
  });
}

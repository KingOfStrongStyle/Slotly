import 'gesture_template.dart';

enum TicketEntryOutcome {
  digitAdded,
  completed,
  notRecognized,
  numberTooLong,
  numberEmpty,
}

class TicketEntry {
  const TicketEntry({
    this.number = '',
    this.isCompleted = false,
    required this.finishSymbol,
  });

  static const maxDigits = 4;

  final String number;
  final bool isCompleted;
  final String finishSymbol;

  (TicketEntry, TicketEntryOutcome) apply(GestureRecognitionResult result) {
    final label = result.label;
    if (!result.isAccepted || label == null) {
      return (this, TicketEntryOutcome.notRecognized);
    }
    if (label == finishSymbol) {
      if (number.isEmpty) return (this, TicketEntryOutcome.numberEmpty);
      return (_copy(isCompleted: true), TicketEntryOutcome.completed);
    }
    if (number.length >= maxDigits) {
      return (this, TicketEntryOutcome.numberTooLong);
    }
    return (_copy(number: '$number$label'), TicketEntryOutcome.digitAdded);
  }

  TicketEntry removeLastDigit() => number.isEmpty
      ? this
      : _copy(number: number.substring(0, number.length - 1));

  TicketEntry cleared() => TicketEntry(finishSymbol: finishSymbol);

  TicketEntry _copy({String? number, bool? isCompleted}) => TicketEntry(
    number: number ?? this.number,
    isCompleted: isCompleted ?? this.isCompleted,
    finishSymbol: finishSymbol,
  );
}

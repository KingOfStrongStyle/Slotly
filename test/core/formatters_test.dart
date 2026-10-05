import 'package:flutter_test/flutter_test.dart';
import 'package:slotly/core/utils/clock.dart';
import 'package:slotly/core/utils/formatters.dart';

void main() {
  group('Formatters.price', () {
    test('groups thousands with non-breaking spaces', () {
      expect(Formatters.price(500), '500\u00A0₸');
      expect(Formatters.price(5000), '5\u00A0000\u00A0₸');
      expect(Formatters.price(150000), '150\u00A0000\u00A0₸');
      expect(Formatters.price(1250000), '1\u00A0250\u00A0000\u00A0₸');
    });
  });

  group('Formatters.duration', () {
    test('formats minutes, hours and mixed values', () {
      expect(Formatters.duration(const Duration(minutes: 45)), '45\u00A0мин');
      expect(Formatters.duration(const Duration(hours: 2)), '2\u00A0ч');
      expect(Formatters.duration(const Duration(minutes: 90)), '1\u00A0ч 30\u00A0мин');
    });
  });

  group('Formatters dates', () {
    final value = DateTime(2026, 10, 5, 9, 7, 3);

    test('formats time with leading zeros', () {
      expect(Formatters.time(value), '09:07');
      expect(Formatters.timeWithSeconds(value), '09:07:03');
    });

    test('uses Russian weekday and genitive month', () {
      expect(Formatters.dayWithWeekday(value), 'пн, 5\u00A0октября');
      expect(Formatters.dateTime(value), 'пн, 5\u00A0октября, 09:07');
    });
  });

  group('DateOnly', () {
    test('drops time and compares days', () {
      final value = DateTime(2026, 10, 5, 23, 59);
      expect(value.dateOnly, DateTime(2026, 10, 5));
      expect(value.isSameDay(DateTime(2026, 10, 5, 1)), isTrue);
      expect(value.isSameDay(DateTime(2026, 10, 6)), isFalse);
    });
  });
}

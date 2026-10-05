import 'package:flutter_test/flutter_test.dart';
import 'package:slotly/features/gesture_checkin/data/symbol_templates.dart';
import 'package:slotly/features/gesture_checkin/domain/gesture_classifier.dart';
import 'package:slotly/features/gesture_checkin/domain/gesture_point.dart';

import '../../helpers/gesture_shapes.dart';

void main() {
  final classifier = GestureClassifier(templates: symbolTemplates);
  const labels = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'S'];

  group('normalize', () {
    test('centers the bounding box and scales the longer side to 1', () {
      final points = GestureClassifier.normalize([
        lineStroke(100, 200, 300, 200),
        lineStroke(100, 250, 300, 250),
      ], sampleSize: 32);

      final xs = points.map((p) => p.x);
      final ys = points.map((p) => p.y);
      expect(xs.reduce((a, b) => a < b ? a : b), closeTo(-0.5, 1e-9));
      expect(xs.reduce((a, b) => a > b ? a : b), closeTo(0.5, 1e-9));
      expect(ys.reduce((a, b) => a < b ? a : b), closeTo(-0.125, 1e-9));
      expect(ys.reduce((a, b) => a > b ? a : b), closeTo(0.125, 1e-9));
    });

    test('keeps proportions: a vertical line stays thin', () {
      final points = GestureClassifier.normalize([
        lineStroke(40, 0, 40, 90),
      ], sampleSize: 16);

      expect(points.every((p) => p.x == 0), isTrue);
      expect(points.first.y, closeTo(-0.5, 1e-9));
      expect(points.last.y, closeTo(0.5, 1e-9));
    });

    test('a single dot does not divide by zero', () {
      final points = GestureClassifier.normalize([
        [const GesturePoint(10, 10)],
      ], sampleSize: 8);

      expect(points, hasLength(8));
      expect(points.every((p) => p == const GesturePoint(0, 0)), isTrue);
    });
  });

  group('resample', () {
    test('returns a fixed number of evenly spaced points', () {
      final slow = [
        for (var i = 0; i <= 100; i++) GesturePoint(i.toDouble(), 0),
      ];
      final fast = [const GesturePoint(0, 0), const GesturePoint(100, 0)];

      for (final stroke in [slow, fast]) {
        final points = GestureClassifier.resample([stroke], 11);
        expect(points, hasLength(11));
        for (var i = 0; i < points.length; i++) {
          expect(points[i].x, closeTo(i * 10, 1e-6));
        }
      }
    });

    test('does not invent points in the gap between strokes', () {
      final points = GestureClassifier.resample([
        lineStroke(0, 0, 10, 0),
        lineStroke(90, 0, 100, 0),
      ], 20);

      expect(points, hasLength(20));
      expect(points.where((p) => p.x > 10.5 && p.x < 89.5), isEmpty);
    });
  });

  group('cloudDistance', () {
    test('is zero for identical clouds and symmetric', () {
      final a = GestureClassifier.normalize(
        symbolTemplates[0].strokes,
        sampleSize: 48,
      );
      final b = GestureClassifier.normalize(
        symbolTemplates[1].strokes,
        sampleSize: 48,
      );

      expect(GestureClassifier.cloudDistance(a, a), 0);
      expect(
        GestureClassifier.cloudDistance(a, b),
        GestureClassifier.cloudDistance(b, a),
      );
    });
  });

  group('recognize', () {
    test('templates cover digits 0-9 and S', () {
      expect(symbolTemplates.map((t) => t.label).toSet(), labels.toSet());
    });

    test('every template recognizes itself with full confidence', () {
      for (final template in symbolTemplates) {
        final result = classifier.recognize(template.strokes);
        expect(result.label, template.label);
        expect(result.isAccepted, isTrue);
        expect(result.confidence, closeTo(1, 1e-9));
      }
    });

    test('recognizes moved, scaled, rotated and noisy copies', () {
      final variants =
          <String, List<GestureStroke> Function(List<GestureStroke>)>{
            'screen coordinates': (s) =>
                distort(s, scale: 2.4, offsetX: 120, offsetY: 300),
            'rotated +8°': (s) => distort(s, rotationDegrees: 8),
            'rotated -8°': (s) => distort(s, rotationDegrees: -8),
            'wider': (s) => distort(s, stretchX: 1.2),
            'narrower': (s) => distort(s, stretchX: 0.85),
            'noisy': (s) => distort(s, noise: 4, seed: 7),
            'drawn backwards': (s) => distort(s, reversed: true),
            'combined': (s) => distort(
              s,
              rotationDegrees: 6,
              stretchX: 1.1,
              noise: 3,
              scale: 3,
            ),
          };

      for (final template in symbolTemplates) {
        for (final entry in variants.entries) {
          final result = classifier.recognize(entry.value(template.strokes));
          expect(
            result.label,
            template.label,
            reason: '${template.label}: ${entry.key}',
          );
          expect(
            result.isAccepted,
            isTrue,
            reason: '${template.label}: ${entry.key} -> $result',
          );
        }
      }
    });

    test('recognizes S as the finishing symbol', () {
      final s = symbolTemplates.firstWhere((t) => t.label == finishSymbol);
      final result = classifier.recognize(
        distort(s.strokes, rotationDegrees: -5, scale: 2, noise: 2),
      );

      expect(result.label, finishSymbol);
      expect(result.isAccepted, isTrue);
    });

    test('stroke order of a two-stroke 4 does not matter', () {
      final four = symbolTemplates.firstWhere((t) => t.label == '4');
      final swapped = [four.strokes[1], four.strokes[0]];

      final result = classifier.recognize(swapped);
      expect(result.label, '4');
      expect(result.isAccepted, isTrue);
    });

    test('rejects shapes that are not digits or S', () {
      final unknown = {
        'horizontal line': [lineStroke(0, 50, 100, 50)],
        'triangle': [
          [
            ...lineStroke(50, 0, 100, 90),
            ...lineStroke(100, 90, 0, 90),
            ...lineStroke(0, 90, 50, 0),
          ],
        ],
        'cross': [lineStroke(0, 0, 100, 100), lineStroke(100, 0, 0, 100)],
        'zigzag': [
          [
            ...lineStroke(0, 0, 25, 100),
            ...lineStroke(25, 100, 50, 0),
            ...lineStroke(50, 0, 75, 100),
            ...lineStroke(75, 100, 100, 0),
          ],
        ],
        'plus': [lineStroke(50, 0, 50, 100), lineStroke(0, 50, 100, 50)],
      };

      for (final entry in unknown.entries) {
        final result = classifier.recognize(entry.value);
        expect(result.isAccepted, isFalse, reason: '${entry.key}: $result');
        expect(result.confidence, lessThan(classifier.acceptThreshold));
      }
    });

    test('a tap or a tiny stroke is rejected without a label', () {
      final tap = classifier.recognize([
        [const GesturePoint(5, 5)],
      ]);
      final tiny = classifier.recognize([lineStroke(0, 0, 8, 8)]);
      final empty = classifier.recognize(const []);

      for (final result in [tap, tiny, empty]) {
        expect(result.label, isNull);
        expect(result.isAccepted, isFalse);
        expect(result.confidence, 0);
      }
    });
  });
}

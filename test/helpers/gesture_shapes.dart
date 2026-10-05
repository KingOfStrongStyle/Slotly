import 'dart:math' as math;

import 'package:slotly/features/gesture_checkin/domain/gesture_point.dart';

/// Straight stroke from (x1, y1) to (x2, y2).
GestureStroke lineStroke(double x1, double y1, double x2, double y2) => [
  for (var i = 0; i <= 12; i++)
    GesturePoint(x1 + (x2 - x1) * i / 12, y1 + (y2 - y1) * i / 12),
];

/// Rotates, stretches, shifts and scales strokes, adds deterministic noise
/// and can reverse the drawing order, imitating a real hand-drawn copy.
List<GestureStroke> distort(
  List<GestureStroke> strokes, {
  double rotationDegrees = 0,
  double stretchX = 1,
  double scale = 1,
  double offsetX = 0,
  double offsetY = 0,
  double noise = 0,
  bool reversed = false,
  int seed = 1,
}) {
  final random = math.Random(seed);
  final angle = rotationDegrees * math.pi / 180;
  var result = [
    for (final stroke in strokes)
      [
        for (final p in stroke)
          GesturePoint(
            (p.x * stretchX * math.cos(angle) - p.y * math.sin(angle)) * scale +
                offsetX +
                (random.nextDouble() - 0.5) * noise,
            (p.x * stretchX * math.sin(angle) + p.y * math.cos(angle)) * scale +
                offsetY +
                (random.nextDouble() - 0.5) * noise,
          ),
      ],
  ];
  if (reversed) {
    result = [for (final stroke in result.reversed) stroke.reversed.toList()];
  }
  return result;
}

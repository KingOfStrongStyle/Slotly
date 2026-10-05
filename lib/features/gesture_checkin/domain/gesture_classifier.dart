import 'dart:math' as math;

import 'gesture_point.dart';
import 'gesture_template.dart';

/// Template matching recognizer for hand-drawn digits and letters.
///
/// Algorithm:
/// 1. Take the bounding box of all strokes.
/// 2. Move its center to (0, 0).
/// 3. Scale uniformly so that the longer side equals 1. Uniform scaling
///    keeps proportions, so a thin "1" does not turn into a square.
/// 4. Resample the path to [sampleSize] points evenly spaced along its
///    length, so fast and slow drawing give the same number of points.
/// 5. Compare with every template. For each drawn point find the closest
///    template point and average these distances; do the same from the
///    template to the drawing and take the larger of the two averages.
///    Stroke order and direction do not matter, and a drawing that covers
///    only part of a template (a "3" against an "8") is penalized.
/// 6. Convert the smallest distance into confidence and reject the result
///    when it is below [acceptThreshold].
///
/// Thresholds were chosen on the bundled templates: distorted copies
/// (rotated by up to 12°, stretched by 20 %, with noise) stay below 0.09,
/// unrelated shapes (line, triangle, cross, zigzag) are above 0.099.
class GestureClassifier {
  GestureClassifier({
    required List<GestureTemplate> templates,
    this.sampleSize = 48,
    this.maxDistance = 0.2,
    this.acceptThreshold = 0.55,
    this.minPathLength = 30,
  }) : _templates = [
         for (final template in templates)
           (
             label: template.label,
             points: normalize(template.strokes, sampleSize: sampleSize),
           ),
       ];

  /// Points per normalized gesture.
  final int sampleSize;

  /// Distance at which confidence drops to zero (in normalized units).
  final double maxDistance;

  /// Minimal confidence to accept a result.
  final double acceptThreshold;

  /// Shorter input (in screen pixels) is treated as an accidental touch.
  final double minPathLength;

  final List<({String label, List<GesturePoint> points})> _templates;

  GestureRecognitionResult recognize(List<GestureStroke> strokes) {
    if (pathLength(strokes) < minPathLength) {
      return const GestureRecognitionResult(
        label: null,
        confidence: 0,
        isAccepted: false,
      );
    }

    final input = normalize(strokes, sampleSize: sampleSize);
    String? bestLabel;
    var bestDistance = double.infinity;
    for (final template in _templates) {
      final distance = cloudDistance(input, template.points);
      if (distance < bestDistance) {
        bestDistance = distance;
        bestLabel = template.label;
      }
    }

    final confidence = (1 - bestDistance / maxDistance).clamp(0.0, 1.0);
    return GestureRecognitionResult(
      label: bestLabel,
      confidence: confidence,
      isAccepted: confidence >= acceptThreshold,
    );
  }

  /// Steps 1–4 of the algorithm. Returns an empty list for empty input.
  static List<GesturePoint> normalize(
    List<GestureStroke> strokes, {
    required int sampleSize,
  }) {
    final points = [for (final stroke in strokes) ...stroke];
    if (points.isEmpty) return const [];

    final minX = points.map((p) => p.x).reduce(math.min);
    final maxX = points.map((p) => p.x).reduce(math.max);
    final minY = points.map((p) => p.y).reduce(math.min);
    final maxY = points.map((p) => p.y).reduce(math.max);
    final centerX = (minX + maxX) / 2;
    final centerY = (minY + maxY) / 2;
    final size = math.max(maxX - minX, maxY - minY);
    // A single dot has zero size; keep it at the origin instead of dividing
    // by zero.
    final scale = size == 0 ? 1.0 : 1 / size;

    final normalized = [
      for (final stroke in strokes)
        [
          for (final p in stroke)
            GesturePoint((p.x - centerX) * scale, (p.y - centerY) * scale),
        ],
    ];
    return resample(normalized, sampleSize);
  }

  /// Places [count] points at equal distances along the strokes.
  ///
  /// Gaps between strokes (finger lifted) are not part of the path, so no
  /// points are invented in the air between two strokes.
  static List<GesturePoint> resample(List<GestureStroke> strokes, int count) {
    final nonEmpty = strokes.where((s) => s.isNotEmpty).toList();
    if (nonEmpty.isEmpty) return const [];
    final total = pathLength(nonEmpty);
    if (total == 0 || count < 2) {
      return List.filled(count, nonEmpty.first.first);
    }

    final interval = total / (count - 1);
    final result = <GesturePoint>[nonEmpty.first.first];
    var carried = 0.0;
    for (final stroke in nonEmpty) {
      for (var i = 1; i < stroke.length; i++) {
        var from = stroke[i - 1];
        final to = stroke[i];
        var segment = from.distanceTo(to);
        while (carried + segment >= interval && result.length < count) {
          final t = (interval - carried) / segment;
          final point = GesturePoint(
            from.x + t * (to.x - from.x),
            from.y + t * (to.y - from.y),
          );
          result.add(point);
          segment -= interval - carried;
          from = point;
          carried = 0;
        }
        carried += segment;
      }
    }
    // Floating point rounding may leave the last point out.
    while (result.length < count) {
      result.add(nonEmpty.last.last);
    }
    return result;
  }

  /// Distance between two point clouds: the larger of the two directed mean
  /// nearest-point distances.
  static double cloudDistance(List<GesturePoint> a, List<GesturePoint> b) {
    if (a.isEmpty || b.isEmpty) return double.infinity;
    return math.max(_directedDistance(a, b), _directedDistance(b, a));
  }

  static double _directedDistance(
    List<GesturePoint> from,
    List<GesturePoint> to,
  ) {
    var sum = 0.0;
    for (final p in from) {
      var nearest = double.infinity;
      for (final q in to) {
        final d = p.distanceTo(q);
        if (d < nearest) nearest = d;
      }
      sum += nearest;
    }
    return sum / from.length;
  }

  static double pathLength(List<GestureStroke> strokes) {
    var length = 0.0;
    for (final stroke in strokes) {
      for (var i = 1; i < stroke.length; i++) {
        length += stroke[i - 1].distanceTo(stroke[i]);
      }
    }
    return length;
  }
}

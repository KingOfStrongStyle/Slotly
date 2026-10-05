import 'dart:math' as math;

/// A point of a hand-drawn stroke. Pure Dart, so the recognizer does not
/// depend on Flutter and can be unit-tested directly.
class GesturePoint {
  const GesturePoint(this.x, this.y);

  final double x;
  final double y;

  double distanceTo(GesturePoint other) =>
      math.sqrt(math.pow(x - other.x, 2) + math.pow(y - other.y, 2));

  @override
  bool operator ==(Object other) =>
      other is GesturePoint && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => '(${x.toStringAsFixed(2)}, ${y.toStringAsFixed(2)})';
}

/// One continuous movement of the finger, from touch down to touch up.
typedef GestureStroke = List<GesturePoint>;

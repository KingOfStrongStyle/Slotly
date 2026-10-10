import 'dart:math' as math;

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

typedef GestureStroke = List<GesturePoint>;

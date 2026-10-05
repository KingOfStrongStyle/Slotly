import 'gesture_point.dart';

/// Reference drawing of one symbol.
///
/// A symbol may have several templates (for example "1" with and without the
/// top flag); all of them share the same [label].
class GestureTemplate {
  const GestureTemplate({required this.label, required this.strokes});

  final String label;
  final List<GestureStroke> strokes;
}

class GestureRecognitionResult {
  const GestureRecognitionResult({
    required this.label,
    required this.confidence,
    required this.isAccepted,
  });

  /// Best matching label, or `null` when the input was too short to compare.
  final String? label;

  /// 0.0 … 1.0, where 1.0 means the drawing matches the template exactly.
  final double confidence;
  final bool isAccepted;

  int get confidencePercent => (confidence * 100).round();

  @override
  String toString() =>
      'GestureRecognitionResult($label, $confidencePercent%, '
      '${isAccepted ? 'accepted' : 'rejected'})';
}

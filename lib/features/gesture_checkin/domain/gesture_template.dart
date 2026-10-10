import 'gesture_point.dart';

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

  final String? label;

  final double confidence;
  final bool isAccepted;

  int get confidencePercent => (confidence * 100).round();

  @override
  String toString() =>
      'GestureRecognitionResult($label, $confidencePercent%, '
      '${isAccepted ? 'accepted' : 'rejected'})';
}

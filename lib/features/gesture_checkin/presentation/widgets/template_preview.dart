import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/gesture_point.dart';
import '../../domain/gesture_template.dart';

class TemplatePreview extends StatelessWidget {
  const TemplatePreview({super.key, required this.template});

  final GestureTemplate template;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox.expand(
      child: CustomPaint(
        painter: _TemplatePainter(
          strokes: template.strokes,
          color: colors.onSurface,
          startColor: colors.primary,
        ),
      ),
    );
  }
}

class _TemplatePainter extends CustomPainter {
  _TemplatePainter({
    required this.strokes,
    required this.color,
    required this.startColor,
  });

  final List<GestureStroke> strokes;
  final Color color;
  final Color startColor;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width, size.height) / 100 * 0.8;
    final dx = (size.width - 100 * scale) / 2;
    final dy = (size.height - 100 * scale) / 2;
    Offset map(GesturePoint p) => Offset(dx + p.x * scale, dy + p.y * scale);

    final ink = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2, size.shortestSide / 24)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      final path = Path()..moveTo(map(stroke.first).dx, map(stroke.first).dy);
      for (final p in stroke.skip(1)) {
        path.lineTo(map(p).dx, map(p).dy);
      }
      canvas
        ..drawPath(path, ink)
        ..drawCircle(
          map(stroke.first),
          math.max(3, size.shortestSide / 16),
          Paint()..color = startColor,
        );
    }
  }

  @override
  bool shouldRepaint(_TemplatePainter oldDelegate) =>
      strokes != oldDelegate.strokes ||
      color != oldDelegate.color ||
      startColor != oldDelegate.startColor;
}

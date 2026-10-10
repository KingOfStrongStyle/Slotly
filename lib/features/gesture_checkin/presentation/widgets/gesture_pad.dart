import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/app_strings.dart';
import '../../domain/gesture_point.dart';

class GesturePadController extends ChangeNotifier {
  final List<List<Offset>> _strokes = [];

  List<List<Offset>> get strokes => List.unmodifiable(_strokes);
  bool get isEmpty => _strokes.isEmpty;

  void startStroke(Offset point) {
    _strokes.add([point]);
    notifyListeners();
  }

  void extendStroke(Offset point) {
    if (_strokes.isEmpty) return;
    _strokes.last.add(point);
    notifyListeners();
  }

  void undoStroke() {
    if (_strokes.isEmpty) return;
    _strokes.removeLast();
    notifyListeners();
  }

  void clear() {
    if (_strokes.isEmpty) return;
    _strokes.clear();
    notifyListeners();
  }

  List<GestureStroke> toGestureStrokes() => [
    for (final stroke in _strokes)
      [for (final p in stroke) GesturePoint(p.dx, p.dy)],
  ];
}

class GesturePad extends StatelessWidget {
  const GesturePad({
    super.key,
    required this.controller,
    this.hasError = false,
    this.onStrokeEnd,
  });

  final GesturePadController controller;
  final bool hasError;
  final VoidCallback? onStrokeEnd;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: AppStrings.checkInPadLabel,
      child: AspectRatio(
        aspectRatio: 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppRadii.l),
            border: Border.all(
              color: hasError ? colors.error : colors.outline,
              width: hasError ? 3 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.l),
            child: GestureDetector(
              key: const ValueKey('gesture-pad'),
              dragStartBehavior: DragStartBehavior.down,
              onPanStart: (details) =>
                  controller.startStroke(details.localPosition),
              onPanUpdate: (details) =>
                  controller.extendStroke(details.localPosition),
              onPanEnd: (_) => onStrokeEnd?.call(),
              child: CustomPaint(
                painter: _StrokesPainter(
                  controller: controller,
                  strokeColor: colors.primary,
                  guideColor: colors.outlineVariant,
                ),
                child: ListenableBuilder(
                  listenable: controller,
                  builder: (context, _) => controller.isEmpty
                      ? Center(
                          child: Text(
                            AppStrings.checkInPadHint,
                            style: TextStyle(color: colors.onSurfaceVariant),
                          ),
                        )
                      : const SizedBox.expand(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StrokesPainter extends CustomPainter {
  _StrokesPainter({
    required this.controller,
    required this.strokeColor,
    required this.guideColor,
  }) : super(repaint: controller);

  final GesturePadController controller;
  final Color strokeColor;
  final Color guideColor;

  @override
  void paint(Canvas canvas, Size size) {
    final guide = Paint()
      ..color = guideColor
      ..strokeWidth = 1;
    canvas
      ..drawLine(
        Offset(size.width / 2, 0),
        Offset(size.width / 2, size.height),
        guide,
      )
      ..drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        guide,
      );

    final ink = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final dot = Paint()..color = strokeColor;
    for (final stroke in controller.strokes) {
      if (stroke.length == 1) {
        canvas.drawCircle(stroke.first, 4, dot);
        continue;
      }
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (final point in stroke.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, ink);
    }
  }

  @override
  bool shouldRepaint(_StrokesPainter oldDelegate) =>
      controller != oldDelegate.controller ||
      strokeColor != oldDelegate.strokeColor ||
      guideColor != oldDelegate.guideColor;
}

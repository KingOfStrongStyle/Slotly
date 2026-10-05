import 'package:flutter/material.dart';

/// Slotly brand mark: a 2x2 grid of time slots, one of them booked.
///
/// Drawn in code so the same geometry can be reproduced in the SVG files of
/// the design prototype (`design/assets/slotly-logo.svg`).
class SlotlyLogo extends StatelessWidget {
  const SlotlyLogo({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Логотип Slotly',
      image: true,
      child: CustomPaint(
        size: Size.square(size),
        painter: _SlotlyLogoPainter(
          background: colors.primary,
          slot: colors.onPrimary,
          bookedSlot: colors.primaryContainer,
          check: colors.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _SlotlyLogoPainter extends CustomPainter {
  _SlotlyLogoPainter({
    required this.background,
    required this.slot,
    required this.bookedSlot,
    required this.check,
  });

  final Color background;
  final Color slot;
  final Color bookedSlot;
  final Color check;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 100;
    final backgroundRect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(26 * unit),
    );
    canvas.drawRRect(backgroundRect, Paint()..color = background);

    const cellSize = 28.0;
    const origins = [Offset(19, 19), Offset(53, 19), Offset(19, 53)];
    final freePaint = Paint()..color = slot.withValues(alpha: 0.38);
    for (final origin in origins) {
      canvas.drawRRect(_cell(origin, cellSize, unit), freePaint);
    }

    canvas.drawRRect(
      _cell(const Offset(53, 53), cellSize, unit),
      Paint()..color = bookedSlot,
    );
    final checkPath = Path()
      ..moveTo(60 * unit, 67 * unit)
      ..lineTo(65 * unit, 72 * unit)
      ..lineTo(74 * unit, 62 * unit);
    canvas.drawPath(
      checkPath,
      Paint()
        ..color = check
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4 * unit
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  RRect _cell(Offset origin, double cellSize, double unit) =>
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          origin.dx * unit,
          origin.dy * unit,
          cellSize * unit,
          cellSize * unit,
        ),
        Radius.circular(7 * unit),
      );

  @override
  bool shouldRepaint(_SlotlyLogoPainter oldDelegate) =>
      background != oldDelegate.background ||
      slot != oldDelegate.slot ||
      bookedSlot != oldDelegate.bookedSlot ||
      check != oldDelegate.check;
}

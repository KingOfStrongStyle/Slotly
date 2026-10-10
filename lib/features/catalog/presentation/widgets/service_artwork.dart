import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../domain/service.dart';
import '../service_category_style.dart';

class ServiceArtwork extends StatelessWidget {
  const ServiceArtwork({
    super.key,
    required this.service,
    this.iconSize = 32,
    this.borderRadius = AppRadii.m,
  });

  final Service service;
  final double iconSize;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (background, foreground) = switch (service.artworkVariant % 3) {
      0 => (colors.primaryContainer, colors.onPrimaryContainer),
      1 => (colors.secondaryContainer, colors.onSecondaryContainer),
      _ => (colors.tertiaryContainer, colors.onTertiaryContainer),
    };

    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: CustomPaint(
          painter: _CirclesPainter(
            background: background,
            circles: foreground.withValues(alpha: 0.12),
            variant: service.artworkVariant % 3,
          ),
          child: Center(
            child: Icon(
              service.category.icon,
              size: iconSize,
              color: foreground,
            ),
          ),
        ),
      ),
    );
  }
}

class _CirclesPainter extends CustomPainter {
  _CirclesPainter({
    required this.background,
    required this.circles,
    required this.variant,
  });

  final Color background;
  final Color circles;
  final int variant;

  static const _layouts = [
    [(0.15, 0.2, 0.35), (0.95, 0.9, 0.45)],
    [(0.9, 0.15, 0.4), (0.1, 0.95, 0.3)],
    [(0.5, -0.05, 0.4), (0.85, 0.95, 0.3), (0.05, 0.6, 0.2)],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    final side = size.shortestSide;
    final paint = Paint()..color = circles;
    for (final (x, y, r) in _layouts[variant]) {
      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        r * side,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_CirclesPainter oldDelegate) =>
      background != oldDelegate.background ||
      circles != oldDelegate.circles ||
      variant != oldDelegate.variant;
}

import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/app_strings.dart';
import '../../domain/organization.dart';
import '../../domain/service.dart';
import '../service_category_style.dart';

/// Shows a business photo: a file added by the owner or a built-in
/// illustration of the demo data.
///
/// Files are decoded at the size they are displayed ([cacheWidth]), so a
/// 12-megapixel photo does not take 48 MB of memory in a list. A missing
/// or broken file shows a placeholder instead of an error.
class BusinessPhotoView extends StatelessWidget {
  const BusinessPhotoView({
    super.key,
    required this.photo,
    required this.category,
    this.fit = BoxFit.cover,
    this.decodeWidth,
  });

  final BusinessPhoto? photo;
  final ServiceCategory category;
  final BoxFit fit;

  /// Width in logical pixels the image is shown at; null keeps the full
  /// resolution (used by the zoomable gallery).
  final double? decodeWidth;

  @override
  Widget build(BuildContext context) {
    final path = photo?.filePath;
    if (path == null) {
      return _Illustration(
        category: category,
        variant: photo?.illustrationVariant ?? 0,
      );
    }
    final ratio = MediaQuery.devicePixelRatioOf(context);
    return Image.file(
      File(path),
      fit: fit,
      cacheWidth: decodeWidth == null ? null : (decodeWidth! * ratio).round(),
      errorBuilder: (context, _, _) => const _Unavailable(),
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colors.surfaceContainerHighest,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_outlined, color: colors.onSurfaceVariant),
            Text(
              AppStrings.photoUnavailable,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// Calm geometric illustration: a tinted surface, a few large shapes and
/// the category icon. Four variants make neighbouring photos differ.
class _Illustration extends StatelessWidget {
  const _Illustration({required this.category, required this.variant});

  final ServiceCategory category;
  final int variant;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (background, foreground) = switch (variant % 4) {
      0 => (colors.primaryContainer, colors.onPrimaryContainer),
      1 => (colors.secondaryContainer, colors.onSecondaryContainer),
      2 => (colors.tertiaryContainer, colors.onTertiaryContainer),
      _ => (colors.surfaceContainerHighest, colors.onSurfaceVariant),
    };
    // ClipRect: the large circles must not paint outside the photo box.
    return ExcludeSemantics(
      child: ClipRect(
        child: CustomPaint(
          painter: _ShapesPainter(
            background: background,
            shapes: foreground.withValues(alpha: 0.10),
            variant: variant % 4,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) => Center(
              child: Icon(
                category.icon,
                size: constraints.biggest.shortestSide * 0.3,
                color: foreground.withValues(alpha: 0.85),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShapesPainter extends CustomPainter {
  _ShapesPainter({
    required this.background,
    required this.shapes,
    required this.variant,
  });

  final Color background;
  final Color shapes;
  final int variant;

  // Circle centers and radii as fractions of width/height/shortest side.
  static const _layouts = [
    [(0.12, 0.25, 0.55), (0.92, 0.95, 0.6)],
    [(0.85, 0.1, 0.5), (0.1, 0.9, 0.45)],
    [(0.5, -0.1, 0.6), (0.95, 0.8, 0.35), (0.05, 0.65, 0.3)],
    [(0.3, 1.0, 0.65), (0.9, 0.2, 0.4)],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    final side = size.shortestSide;
    final paint = Paint()..color = shapes;
    for (final (x, y, r) in _layouts[variant]) {
      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        r * side,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ShapesPainter oldDelegate) =>
      background != oldDelegate.background ||
      shapes != oldDelegate.shapes ||
      variant != oldDelegate.variant;
}

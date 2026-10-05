import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../app/theme.dart';

/// Horizontal padding that keeps content readable on wide screens: phones get
/// the regular gutter, tablets and landscape phones get a centered column.
double responsiveGutter(double availableWidth) =>
    math.max(AppSpacing.l, (availableWidth - AppSpacing.maxContentWidth) / 2);

/// Centers a regular (non-sliver) child and limits its width.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
        child: child,
      ),
    );
  }
}

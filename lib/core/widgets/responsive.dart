import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../app/theme.dart';

double responsiveGutter(double availableWidth) =>
    math.max(AppSpacing.l, (availableWidth - AppSpacing.maxContentWidth) / 2);

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

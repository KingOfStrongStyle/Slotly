import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../gesture_log.dart';

typedef GestureEventCallback = void Function(GestureKind kind, String message);

/// Rounded surface with a hint line that hosts one gesture demonstration.
class ZoneFrame extends StatelessWidget {
  const ZoneFrame({
    super.key,
    required this.hint,
    required this.child,
    this.highlighted = false,
  });

  final String hint;
  final Widget child;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: highlighted
              ? colors.secondaryContainer
              : colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadii.l),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.l,
                AppSpacing.m,
                AppSpacing.l,
                0,
              ),
              child: Text(
                hint,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

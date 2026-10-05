import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/app_strings.dart';
import '../../../core/utils/formatters.dart';

enum GestureKind {
  tap,
  doubleTap,
  longPress,
  horizontalDrag,
  verticalDrag,
  scale,
}

class GestureLogEntry {
  const GestureLogEntry({
    required this.kind,
    required this.message,
    required this.occurredAt,
  });

  final GestureKind kind;
  final String message;
  final DateTime occurredAt;
}

extension GestureKindIcon on GestureKind {
  IconData get icon => switch (this) {
    GestureKind.tap => Icons.touch_app_outlined,
    GestureKind.doubleTap => Icons.favorite_border,
    GestureKind.longPress => Icons.more_horiz,
    GestureKind.horizontalDrag => Icons.swap_horiz,
    GestureKind.verticalDrag => Icons.swap_vert,
    GestureKind.scale => Icons.pinch_outlined,
  };
}

/// Newest-first list of recognized gestures.
class GestureLogView extends StatelessWidget {
  const GestureLogView({super.key, required this.entries});

  final List<GestureLogEntry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Text(
            AppStrings.gestureLabLogEmpty,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[entries.length - 1 - index];
        return ListTile(
          dense: true,
          leading: Icon(entry.kind.icon),
          title: Text(entry.message),
          trailing: Text(Formatters.timeWithSeconds(entry.occurredAt)),
        );
      },
    );
  }
}

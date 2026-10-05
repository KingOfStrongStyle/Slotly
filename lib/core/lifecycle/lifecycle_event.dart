import 'dart:ui' show AppLifecycleState;

import '../app_strings.dart';

/// One entry of the lifecycle journal shown on the diagnostics screen.
class LifecycleEvent {
  const LifecycleEvent({
    required this.sequenceNumber,
    required this.state,
    required this.occurredAt,
    this.isInitial = false,
  });

  /// 1-based position in the journal since the last clear.
  final int sequenceNumber;
  final AppLifecycleState state;
  final DateTime occurredAt;

  /// True for the state that was already active when logging started.
  final bool isInitial;

  String get readableDescription {
    final description = describeLifecycleState(state);
    return isInitial
        ? '${AppStrings.lifecycleLaunchPrefix}$description'
        : description;
  }
}

String lifecycleStateTitle(AppLifecycleState state) => switch (state) {
  AppLifecycleState.resumed => AppStrings.lifecycleResumedTitle,
  AppLifecycleState.inactive => AppStrings.lifecycleInactiveTitle,
  AppLifecycleState.hidden => AppStrings.lifecycleHiddenTitle,
  AppLifecycleState.paused => AppStrings.lifecyclePausedTitle,
  AppLifecycleState.detached => AppStrings.lifecycleDetachedTitle,
};

String describeLifecycleState(AppLifecycleState state) => switch (state) {
  AppLifecycleState.resumed => AppStrings.lifecycleResumedDescription,
  AppLifecycleState.inactive => AppStrings.lifecycleInactiveDescription,
  AppLifecycleState.hidden => AppStrings.lifecycleHiddenDescription,
  AppLifecycleState.paused => AppStrings.lifecyclePausedDescription,
  AppLifecycleState.detached => AppStrings.lifecycleDetachedDescription,
};

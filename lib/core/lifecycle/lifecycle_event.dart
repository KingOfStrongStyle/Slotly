import 'dart:ui' show AppLifecycleState;

import '../app_strings.dart';

class LifecycleEvent {
  const LifecycleEvent({
    required this.sequenceNumber,
    required this.state,
    required this.occurredAt,
    this.isInitial = false,
  });

  final int sequenceNumber;
  final AppLifecycleState state;
  final DateTime occurredAt;

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

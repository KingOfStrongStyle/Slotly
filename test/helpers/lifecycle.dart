import 'dart:ui' show AppLifecycleState;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sends a lifecycle change through the real platform channel, exactly like
/// the Android embedder does. The framework then generates the intermediate
/// states (for example `resumed -> paused` becomes inactive, hidden, paused).
Future<void> sendPlatformLifecycle(
  WidgetTester tester,
  AppLifecycleState state,
) async {
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    SystemChannels.lifecycle.name,
    SystemChannels.lifecycle.codec.encodeMessage(state.toString()),
    (_) {},
  );
}

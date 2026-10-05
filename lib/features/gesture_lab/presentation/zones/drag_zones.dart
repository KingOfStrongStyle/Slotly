import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/app_strings.dart';
import '../gesture_log.dart';
import 'zone_frame.dart';

const _knobSize = 56.0;

/// Horizontal drag: the knob follows the finger, the zone shows the
/// direction and, after release, the fling velocity.
class HorizontalDragZone extends StatefulWidget {
  const HorizontalDragZone({super.key, required this.onEvent});

  final GestureEventCallback onEvent;

  @override
  State<HorizontalDragZone> createState() => _HorizontalDragZoneState();
}

class _HorizontalDragZoneState extends State<HorizontalDragZone> {
  double _offset = 0;
  bool _dragging = false;
  String? _direction;
  int? _velocity;

  void _onEnd(DragEndDetails details) {
    final direction = _offset >= 0
        ? AppStrings.gestureDirectionRight
        : AppStrings.gestureDirectionLeft;
    final velocity = details.velocity.pixelsPerSecond.dx.abs().round();
    setState(() {
      _dragging = false;
      _direction = direction;
      _velocity = velocity;
      _offset = 0;
    });
    widget.onEvent(
      GestureKind.horizontalDrag,
      AppStrings.gestureLogHorizontal(direction, velocity),
    );
  }

  @override
  Widget build(BuildContext context) {
    final direction = _direction;
    final velocity = _velocity;
    return ZoneFrame(
      hint: AppStrings.gestureHorizontalHint,
      highlighted: _dragging,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxOffset = math.max(
            0.0,
            (constraints.maxWidth - _knobSize) / 2,
          );
          return GestureDetector(
            key: const ValueKey('horizontal-drag-area'),
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (_) => setState(() => _dragging = true),
            onHorizontalDragUpdate: (details) => setState(() {
              _offset = (_offset + details.delta.dx).clamp(
                -maxOffset,
                maxOffset,
              );
              _direction = details.delta.dx >= 0
                  ? AppStrings.gestureDirectionRight
                  : AppStrings.gestureDirectionLeft;
            }),
            onHorizontalDragEnd: _onEnd,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: _knobSize,
                  child: AnimatedAlign(
                    duration: _dragging
                        ? Duration.zero
                        : const Duration(milliseconds: 250),
                    curve: Curves.easeOutBack,
                    alignment: Alignment(
                      maxOffset == 0 ? 0 : _offset / maxOffset,
                      0,
                    ),
                    child: const _Knob(icon: Icons.swap_horiz),
                  ),
                ),
                if (direction != null)
                  Text(AppStrings.gestureDirection(direction)),
                if (velocity != null)
                  Text(AppStrings.gestureVelocity(velocity)),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Vertical drag: shows how far the finger moved since the drag started.
class VerticalDragZone extends StatefulWidget {
  const VerticalDragZone({super.key, required this.onEvent});

  final GestureEventCallback onEvent;

  @override
  State<VerticalDragZone> createState() => _VerticalDragZoneState();
}

class _VerticalDragZoneState extends State<VerticalDragZone> {
  double _distance = 0;
  bool _dragging = false;

  void _onEnd(DragEndDetails details) {
    final direction = _distance >= 0
        ? AppStrings.gestureDirectionDown
        : AppStrings.gestureDirectionUp;
    final distance = _distance.abs().round();
    setState(() => _dragging = false);
    widget.onEvent(
      GestureKind.verticalDrag,
      AppStrings.gestureLogVertical(direction, distance),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ZoneFrame(
      hint: AppStrings.gestureVerticalHint,
      highlighted: _dragging,
      child: GestureDetector(
        key: const ValueKey('vertical-drag-area'),
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: (_) => setState(() {
          _dragging = true;
          _distance = 0;
        }),
        onVerticalDragUpdate: (details) =>
            setState(() => _distance += details.delta.dy),
        onVerticalDragEnd: _onEnd,
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Guarded: with very large text the area can be smaller than the knob.
                  final maxOffset = math.max(
                    0.0,
                    (constraints.maxHeight - _knobSize) / 2,
                  );
                  final visualOffset = _distance.clamp(-maxOffset, maxOffset);
                  return Align(
                    alignment: Alignment(
                      0,
                      maxOffset <= 0 ? 0 : visualOffset / maxOffset,
                    ),
                    child: const _Knob(icon: Icons.swap_vert),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                AppStrings.gestureOffset(_distance.round()),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Knob extends StatelessWidget {
  const _Knob({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: _knobSize,
      height: _knobSize,
      decoration: BoxDecoration(color: colors.primary, shape: BoxShape.circle),
      child: Icon(icon, color: colors.onPrimary),
    );
  }
}

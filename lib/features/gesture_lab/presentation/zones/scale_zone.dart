import 'package:flutter/material.dart';

import '../../../../core/app_strings.dart';
import '../../../../core/widgets/slotly_logo.dart';
import '../gesture_log.dart';
import 'zone_frame.dart';

class ScaleZone extends StatefulWidget {
  const ScaleZone({super.key, required this.onEvent});

  static const minScale = 0.5;
  static const maxScale = 3.0;

  final GestureEventCallback onEvent;

  @override
  State<ScaleZone> createState() => _ScaleZoneState();
}

class _ScaleZoneState extends State<ScaleZone> {
  double _scale = 1;
  double _scaleAtStart = 1;
  bool _scaling = false;

  String get _formattedScale => _scale.toStringAsFixed(1).replaceAll('.', ',');

  void _onEnd(ScaleEndDetails details) {
    setState(() => _scaling = false);
    if ((_scale - _scaleAtStart).abs() < 0.05) return;
    widget.onEvent(
      GestureKind.scale,
      AppStrings.gestureLogScale(_formattedScale),
    );
  }

  void _reset() {
    setState(() => _scale = 1);
    widget.onEvent(GestureKind.scale, AppStrings.gestureLogScaleReset);
  }

  @override
  Widget build(BuildContext context) {
    return ZoneFrame(
      hint: AppStrings.gestureScaleHint,
      highlighted: _scaling,
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              key: const ValueKey('scale-area'),
              behavior: HitTestBehavior.opaque,
              onScaleStart: (_) => setState(() {
                _scaling = true;
                _scaleAtStart = _scale;
              }),
              onScaleUpdate: (details) => setState(() {
                _scale = (_scaleAtStart * details.scale).clamp(
                  ScaleZone.minScale,
                  ScaleZone.maxScale,
                );
              }),
              onScaleEnd: _onEnd,
              child: ClipRect(
                child: Center(
                  child: Transform.scale(
                    scale: _scale,
                    child: const SlotlyLogo(size: 72),
                  ),
                ),
              ),
            ),
          ),
          Text(AppStrings.gestureScale(_formattedScale)),
          TextButton(
            onPressed: _scale == 1 ? null : _reset,
            child: const Text(AppStrings.gestureScaleReset),
          ),
        ],
      ),
    );
  }
}

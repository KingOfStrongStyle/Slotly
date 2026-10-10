import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/app_strings.dart';
import '../../../core/utils/clock.dart';
import 'gesture_log.dart';
import 'zones/drag_zones.dart';
import 'zones/scale_zone.dart';
import 'zones/tap_zone.dart';

class GestureLabScreen extends StatefulWidget {
  const GestureLabScreen({super.key, required this.clock});

  final Clock clock;

  @override
  State<GestureLabScreen> createState() => _GestureLabScreenState();
}

class _GestureLabScreenState extends State<GestureLabScreen>
    with SingleTickerProviderStateMixin {
  static const _maxLogEntries = 50;

  late final TabController _tabs = TabController(length: 4, vsync: this)
    ..addListener(() => setState(() {}));
  final List<GestureLogEntry> _log = [];

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _record(GestureKind kind, String message) {
    setState(() {
      _log.add(
        GestureLogEntry(
          kind: kind,
          message: message,
          occurredAt: widget.clock(),
        ),
      );
      if (_log.length > _maxLogEntries) _log.removeAt(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final zones = [
      TapZone(onEvent: _record),
      HorizontalDragZone(onEvent: _record),
      VerticalDragZone(onEvent: _record),
      ScaleZone(onEvent: _record),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.gestureLabTitle),
        actions: [
          IconButton(
            tooltip: AppStrings.gestureLabClearLog,
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: _log.isEmpty ? null : () => setState(_log.clear),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(
              icon: Icon(Icons.touch_app_outlined),
              text: AppStrings.gestureZoneTaps,
            ),
            Tab(
              icon: Icon(Icons.swap_horiz),
              text: AppStrings.gestureZoneHorizontal,
            ),
            Tab(
              icon: Icon(Icons.swap_vert),
              text: AppStrings.gestureZoneVertical,
            ),
            Tab(
              icon: Icon(Icons.pinch_outlined),
              text: AppStrings.gestureZoneScale,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: IndexedStack(index: _tabs.index, children: zones),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.l,
              AppSpacing.s,
              AppSpacing.l,
              0,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                AppStrings.gestureLabLogTitle,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          ),
          Expanded(flex: 2, child: GestureLogView(entries: _log)),
        ],
      ),
    );
  }
}

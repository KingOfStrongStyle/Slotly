import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/app_strings.dart';
import '../gesture_log.dart';
import 'zone_frame.dart';

enum _CardAction { toggleSelection, toggleFavorite, reset }

class TapZone extends StatefulWidget {
  const TapZone({super.key, required this.onEvent});

  final GestureEventCallback onEvent;

  @override
  State<TapZone> createState() => _TapZoneState();
}

class _TapZoneState extends State<TapZone> {
  bool _selected = false;
  bool _favorite = false;

  void _toggleSelection() {
    setState(() => _selected = !_selected);
    widget.onEvent(
      GestureKind.tap,
      _selected ? AppStrings.gestureLogTap : AppStrings.gestureLogTapUnselect,
    );
  }

  void _toggleFavorite() {
    setState(() => _favorite = !_favorite);
    widget.onEvent(
      GestureKind.doubleTap,
      _favorite
          ? AppStrings.gestureLogDoubleTapOn
          : AppStrings.gestureLogDoubleTapOff,
    );
  }

  Future<void> _openMenu() async {
    widget.onEvent(GestureKind.longPress, AppStrings.gestureLogLongPress);
    final action = await showModalBottomSheet<_CardAction>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                AppStrings.gestureMenuTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: Text(
                _selected
                    ? AppStrings.gestureMenuUnselect
                    : AppStrings.gestureMenuSelect,
              ),
              onTap: () =>
                  Navigator.of(context).pop(_CardAction.toggleSelection),
            ),
            ListTile(
              leading: const Icon(Icons.favorite_border),
              title: Text(
                _favorite
                    ? AppStrings.gestureMenuUnfavorite
                    : AppStrings.gestureMenuFavorite,
              ),
              onTap: () =>
                  Navigator.of(context).pop(_CardAction.toggleFavorite),
            ),
            ListTile(
              leading: const Icon(Icons.restart_alt),
              title: const Text(AppStrings.gestureMenuReset),
              onTap: () => Navigator.of(context).pop(_CardAction.reset),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case _CardAction.toggleSelection:
        _toggleSelection();
      case _CardAction.toggleFavorite:
        _toggleFavorite();
      case _CardAction.reset:
        setState(() {
          _selected = false;
          _favorite = false;
        });
        widget.onEvent(
          GestureKind.longPress,
          AppStrings.gestureLogMenuAction(AppStrings.gestureMenuReset),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return ZoneFrame(
      hint: AppStrings.gestureCardHint,
      child: Center(
        child: GestureDetector(
          onTap: _toggleSelection,
          onDoubleTap: _toggleFavorite,
          onLongPress: _openMenu,
          child: AnimatedContainer(
            key: const ValueKey('gesture-card'),
            duration: const Duration(milliseconds: 200),
            width: 240,
            padding: const EdgeInsets.all(AppSpacing.l),
            decoration: BoxDecoration(
              color: _selected ? colors.primaryContainer : colors.surface,
              borderRadius: BorderRadius.circular(AppRadii.l),
              border: Border.all(
                color: _selected ? colors.primary : colors.outlineVariant,
                width: _selected ? 3 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  scale: _favorite ? 1.25 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _favorite ? Icons.favorite : Icons.favorite_border,
                    size: 40,
                    color: _favorite ? colors.error : colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.s),
                Text(
                  AppStrings.gestureCardTitle,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _selected
                      ? AppStrings.gestureCardSelected
                      : AppStrings.gestureCardNotSelected,
                ),
                if (_favorite) const Text(AppStrings.gestureCardFavorite),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

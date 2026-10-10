import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/app_strings.dart';
import '../../../../core/utils/clock.dart';

/// Horizontal strip with the next [days] dates starting from [today].
class DateSelector extends StatelessWidget {
  const DateSelector({
    super.key,
    required this.today,
    required this.selected,
    required this.onSelected,
    this.days = 14,
  });

  final DateTime today;
  final DateTime? selected;
  final ValueChanged<DateTime> onSelected;
  final int days;

  @override
  Widget build(BuildContext context) {
    final start = today.dateOnly;
    final dates = [
      for (var offset = 0; offset < days; offset++)
        DateTime(start.year, start.month, start.day + offset),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (offset, day) in dates.indexed)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.s),
              child: _DayOption(
                key: ValueKey('day-$offset'),
                day: day,
                offset: offset,
                isSelected: selected?.isSameDay(day) ?? false,
                onSelected: onSelected,
              ),
            ),
        ],
      ),
    );
  }
}

class _DayOption extends StatelessWidget {
  const _DayOption({
    super.key,
    required this.day,
    required this.offset,
    required this.isSelected,
    required this.onSelected,
  });

  final DateTime day;
  final int offset;
  final bool isSelected;
  final ValueChanged<DateTime> onSelected;

  String get _caption => switch (offset) {
    0 => AppStrings.bookingToday,
    1 => AppStrings.bookingTomorrow,
    _ => AppStrings.weekdaysShort[day.weekday - 1],
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final foreground = isSelected ? colors.onPrimary : colors.onSurface;
    final month = AppStrings.monthsGenitive[day.month - 1];

    return Semantics(
      button: true,
      selected: isSelected,
      label: '$_caption, ${day.day} $month',
      excludeSemantics: true,
      child: Material(
        color: isSelected ? colors.primary : colors.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.m),
          side: BorderSide(
            color: isSelected ? colors.primary : colors.outlineVariant,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.m),
          onTap: () => onSelected(day),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 68, minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.m,
                vertical: AppSpacing.s,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _caption,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: foreground,
                    ),
                  ),
                  Text(
                    '${day.day}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: foreground,
                    ),
                  ),
                  Text(
                    month.substring(0, 3),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: foreground,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

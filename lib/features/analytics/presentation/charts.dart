import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/app_strings.dart';
import '../domain/owner_analytics.dart';

/// Card with a title, a chart and a "table" toggle. The table is the text
/// alternative of the chart: the same numbers without relying on bar
/// lengths or colors.
class ChartCard extends StatefulWidget {
  const ChartCard({
    super.key,
    required this.title,
    required this.chart,
    required this.rows,
    this.footer,
  });

  final String title;
  final Widget chart;

  /// Label and value of each table row.
  final List<(String, String)> rows;
  final Widget? footer;

  @override
  State<ChartCard> createState() => _ChartCardState();
}

class _ChartCardState extends State<ChartCard> {
  bool _showTable = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.l,
          AppSpacing.s,
          AppSpacing.s,
          AppSpacing.l,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      widget.title,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: _showTable
                      ? AppStrings.chartShowChart
                      : AppStrings.chartShowTable,
                  icon: Icon(
                    _showTable ? Icons.bar_chart : Icons.table_rows_outlined,
                  ),
                  onPressed: () => setState(() => _showTable = !_showTable),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.s),
              child: _showTable ? _Table(rows: widget.rows) : widget.chart,
            ),
            if (widget.footer case final footer?)
              Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.s,
                  right: AppSpacing.s,
                ),
                child: footer,
              ),
          ],
        ),
      ),
    );
  }
}

class _Table extends StatelessWidget {
  const _Table({required this.rows});

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (rows.isEmpty) return const Text(AppStrings.chartNoData);
    return Table(
      columnWidths: const {1: IntrinsicColumnWidth()},
      children: [
        TableRow(
          children: [
            Text(
              AppStrings.chartColumnPeriod,
              style: theme.textTheme.labelMedium,
            ),
            Text(
              AppStrings.chartColumnValue,
              style: theme.textTheme.labelMedium,
            ),
          ],
        ),
        for (final (label, value) in rows)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text(label, style: theme.textTheme.bodySmall),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// Vertical bars over time, one series in the brand color.
///
/// Tap a bar to see its exact value above the chart (the touch version of
/// a hover tooltip). The whole chart has one semantics label with the total
/// and the maximum; the table view lists every value.
class TimeBarChart extends StatefulWidget {
  const TimeBarChart({
    super.key,
    required this.title,
    required this.buckets,
    required this.labelOf,
    this.height = 140,
  });

  final String title;
  final List<TimeBucket> buckets;

  /// Human label of a bucket: "пн, 6 окт." or "30 сен – 6 окт".
  final String Function(TimeBucket bucket) labelOf;
  final double height;

  @override
  State<TimeBarChart> createState() => _TimeBarChartState();
}

class _TimeBarChartState extends State<TimeBarChart> {
  int? _selected;

  @override
  void didUpdateWidget(TimeBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.buckets.length != widget.buckets.length) _selected = null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final buckets = widget.buckets;
    final maxValue = buckets.fold<num>(0, (m, b) => math.max(m, b.value));
    final total = buckets.fold<num>(0, (sum, b) => sum + b.value);
    final selected = _selected;
    final muted = theme.textTheme.labelSmall?.copyWith(
      color: colors.onSurfaceVariant,
    );
    final peak = buckets.isEmpty
        ? null
        : buckets.reduce((a, b) => b.value > a.value ? b : a);

    return Semantics(
      label: AppStrings.chartSummary(
        widget.title,
        total.round(),
        peak == null ? '0' : '${peak.value} (${widget.labelOf(peak)})',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 20,
            child: Text(
              selected == null
                  ? AppStrings.chartTapHint
                  : AppStrings.chartBarValue(
                      widget.labelOf(buckets[selected]),
                      buckets[selected].value,
                    ),
              style: selected == null ? muted : theme.textTheme.labelMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            height: widget.height,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final gap = buckets.length > 20 ? 1.0 : 2.0;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (var i = 0; i < buckets.length; i++)
                            Expanded(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => setState(
                                  () => _selected = _selected == i ? null : i,
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: gap / 2,
                                  ),
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: _Bar(
                                      fraction: maxValue == 0
                                          ? 0
                                          : buckets[i].value / maxValue,
                                      height: constraints.maxHeight,
                                      color: selected == null || selected == i
                                          ? colors.primary
                                          : colors.primary.withValues(
                                              alpha: 0.35,
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                // Recessive single axis: only the maximum and zero.
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${maxValue.round()}', style: muted),
                    Text('0', style: muted),
                  ],
                ),
              ],
            ),
          ),
          Container(height: 1, color: colors.outlineVariant),
          const SizedBox(height: AppSpacing.xs),
          if (buckets.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.labelOf(buckets.first), style: muted),
                Text(widget.labelOf(buckets.last), style: muted),
              ],
            ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.fraction,
    required this.height,
    required this.color,
  });

  final double fraction;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // A zero value keeps a 2 px stub so the day is visibly "nothing".
    final barHeight = fraction == 0 ? 2.0 : math.max(4.0, fraction * height);
    return AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 200),
      height: barHeight,
      decoration: BoxDecoration(
        color: fraction == 0
            ? Theme.of(context).colorScheme.outlineVariant
            : color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      ),
    );
  }
}

/// Horizontal bars with the label on the left and the value on the right
/// (direct labels), longest first. Shows at most [maxItems]; the rest is
/// folded into "Остальные".
class RankedBars extends StatelessWidget {
  const RankedBars({super.key, required this.items, this.maxItems = 5});

  final List<NamedCount> items;
  final int maxItems;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (items.isEmpty) return const Text(AppStrings.chartNoData);
    final shown = items.take(maxItems).toList();
    final rest = items.skip(maxItems).fold(0, (sum, i) => sum + i.count);
    if (rest > 0) shown.add(NamedCount(AppStrings.chartOther, rest));
    final maxCount = shown.map((i) => i.count).reduce(math.max);
    return Column(
      children: [
        for (final item in shown)
          Semantics(
            label: AppStrings.chartBarValue(item.name, item.count),
            excludeSemantics: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: theme.textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text('${item.count}', style: theme.textTheme.labelMedium),
                    ],
                  ),
                  const SizedBox(height: 2),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      height: 8,
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: item.count / maxCount,
                        child: ColoredBox(
                          color: item.name == AppStrings.chartOther
                              ? theme.colorScheme.outline
                              : theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// One stacked bar split by category with a legend that repeats every
/// value as text, so identity never depends on color alone.
class StackedShareBar extends StatelessWidget {
  const StackedShareBar({super.key, required this.parts});

  /// Label, value and color of each part, in a fixed order.
  final List<(String, int, Color)> parts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = parts.fold(0, (sum, p) => sum + p.$2);
    if (total == 0) return const Text(AppStrings.chartNoData);
    final visible = [
      for (final part in parts)
        if (part.$2 > 0) part,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 16,
            // Stretch: a ColoredBox without a child would get zero height.
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < visible.length; i++) ...[
                  // 2 px surface gap between segments.
                  if (i > 0) const SizedBox(width: 2),
                  Expanded(
                    flex: visible[i].$2,
                    child: ColoredBox(color: visible[i].$3),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        Wrap(
          spacing: AppSpacing.l,
          runSpacing: AppSpacing.s,
          children: [
            for (final (label, value, color) in parts)
              Semantics(
                label: AppStrings.chartBarValue(label, value),
                excludeSemantics: true,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '$label: $value (${(value * 100 / total).round()} %)',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

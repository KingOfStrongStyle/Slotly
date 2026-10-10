import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/app_strings.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/rating_badge.dart';
import '../../../core/widgets/responsive.dart';
import '../../booking/domain/booking.dart';
import '../data/analytics_repository.dart';
import '../domain/owner_analytics.dart';
import 'charts.dart';

/// Owner dashboard: KPI tiles and charts for one organization.
///
/// The period filter changes every number on the screen at once, because
/// they all come from one `OwnerAnalytics` result.
class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({
    super.key,
    required this.organizationId,
    required this.organizationName,
    required this.analytics,
  });

  final String organizationId;
  final String organizationName;
  final AnalyticsRepository analytics;

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  AnalyticsPeriod _period = AnalyticsPeriod.days30;
  OwnerAnalytics? _data;
  Object? _error;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    widget.analytics.changes.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    widget.analytics.changes.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final requestId = ++_requestId;
    try {
      final data = await widget.analytics.fetch(widget.organizationId, _period);
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _data = data;
        _error = null;
      });
    } on Exception catch (error) {
      if (!mounted || requestId != _requestId) return;
      setState(() => _error = error);
    }
  }

  void _selectPeriod(AnalyticsPeriod period) {
    setState(() => _period = period);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return LayoutBuilder(
      builder: (context, constraints) {
        final gutter = responsiveGutter(constraints.maxWidth);
        return CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(AppStrings.dashboardTitle),
                  Text(
                    widget.organizationName,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(gutter, 0, gutter, AppSpacing.m),
              sliver: SliverToBoxAdapter(
                child: Semantics(
                  label: AppStrings.periodLabel,
                  child: SegmentedButton<AnalyticsPeriod>(
                    segments: [
                      for (final period in AnalyticsPeriod.values)
                        ButtonSegment(
                          value: period,
                          label: Text(AppStrings.periodDays(period.days)),
                        ),
                    ],
                    selected: {_period},
                    showSelectedIcon: false,
                    onSelectionChanged: (value) => _selectPeriod(value.single),
                  ),
                ),
              ),
            ),
            if (data == null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _error == null
                    ? const Center(child: CircularProgressIndicator())
                    : EmptyState(
                        icon: Icons.cloud_off,
                        title: AppStrings.dashboardLoadError,
                        message: AppStrings.bookingsLoadErrorMessage,
                        actionLabel: AppStrings.bookingRetry,
                        onAction: _load,
                      ),
              )
            else if (data.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.insights_outlined,
                  title: AppStrings.dashboardEmptyTitle,
                  message: AppStrings.dashboardEmptyMessage,
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(gutter, 0, gutter, AppSpacing.xl),
                sliver: SliverList.list(children: _content(context, data)),
              ),
          ],
        );
      },
    );
  }

  List<Widget> _content(BuildContext context, OwnerAnalytics data) {
    final theme = Theme.of(context);
    final palette = SlotlyColors.of(context).chart;
    final rate = data.cancellationRate;
    final average = data.averageRating;
    final overall = data.overallRating;
    String bucketLabel(TimeBucket bucket) => _bucketLabel(bucket, data.period);
    List<(String, String)> rows(List<TimeBucket> buckets) => [
      for (final bucket in buckets.reversed)
        (bucketLabel(bucket), '${bucket.value}'),
    ];
    const gap = SizedBox(height: AppSpacing.m);

    return [
      _KpiGrid(
        tiles: [
          _Kpi(AppStrings.kpiBookings, '${data.bookings}'),
          _Kpi(AppStrings.kpiCompleted, '${data.completed}'),
          _Kpi(
            AppStrings.kpiCancelled,
            '${data.cancelled}',
            rate == null
                ? null
                : AppStrings.kpiCancellationRate(_percent(rate)),
          ),
          _Kpi(
            AppStrings.kpiRating,
            average == null ? AppStrings.kpiNoData : formatRating(average),
            overall == null
                ? null
                : AppStrings.kpiOverallRating(formatRating(overall)),
          ),
          _Kpi(AppStrings.kpiNewReviews, '${data.newReviews}'),
          _Kpi(AppStrings.kpiFavorites, '${data.favoritesAdded}'),
        ],
      ),
      gap,
      Card(
        child: Column(
          children: [
            _TopRow(
              icon: Icons.person_outline,
              title: AppStrings.kpiTopSpecialist,
              value: data.topSpecialist,
            ),
            const Divider(height: 1),
            _TopRow(
              icon: Icons.star_outline,
              title: AppStrings.kpiTopService,
              value: data.topService,
            ),
          ],
        ),
      ),
      gap,
      ChartCard(
        title: data.period.groupsByWeek
            ? AppStrings.chartBookingsWeekly
            : AppStrings.chartBookingsDaily,
        rows: rows(data.bookingsSeries),
        chart: TimeBarChart(
          title: AppStrings.chartBookingsDaily,
          buckets: data.bookingsSeries,
          labelOf: bucketLabel,
        ),
      ),
      gap,
      ChartCard(
        title: AppStrings.chartStatuses,
        rows: [
          for (final (label, value, _) in _statusParts(data, palette))
            (label, '$value'),
        ],
        chart: StackedShareBar(parts: _statusParts(data, palette)),
      ),
      gap,
      ChartCard(
        title: AppStrings.chartBySpecialist,
        rows: [for (final i in data.bySpecialist) (i.name, '${i.count}')],
        chart: RankedBars(items: data.bySpecialist),
      ),
      gap,
      ChartCard(
        title: AppStrings.chartByService,
        rows: [for (final i in data.byService) (i.name, '${i.count}')],
        chart: RankedBars(items: data.byService),
      ),
      gap,
      ChartCard(
        title: AppStrings.chartReviews,
        rows: rows(data.reviewsSeries),
        chart: TimeBarChart(
          title: AppStrings.chartReviews,
          buckets: data.reviewsSeries,
          labelOf: bucketLabel,
          height: 100,
        ),
      ),
      gap,
      ChartCard(
        title: AppStrings.chartFavorites,
        rows: rows(data.favoritesSeries),
        chart: TimeBarChart(
          title: AppStrings.chartFavorites,
          buckets: data.favoritesSeries,
          labelOf: bucketLabel,
          height: 100,
        ),
      ),
      gap,
      Text(
        AppStrings.dashboardFormulaNote,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    ];
  }

  static List<(String, int, Color)> _statusParts(
    OwnerAnalytics data,
    List<Color> palette,
  ) => [
    (
      AppStrings.statusCompleted,
      data.statusCounts[BookingStatus.completed]!,
      palette[0],
    ),
    (
      AppStrings.statusConfirmed,
      data.statusCounts[BookingStatus.confirmed]!,
      palette[1],
    ),
    (
      AppStrings.statusCancelled,
      data.statusCounts[BookingStatus.cancelled]!,
      palette[2],
    ),
  ];
}

String _percent(double share) => '${(share * 100).round()} %';

String _shortDate(DateTime day) =>
    '${day.day} ${AppStrings.monthsGenitive[day.month - 1].substring(0, 3)}';

String _bucketLabel(TimeBucket bucket, AnalyticsPeriod period) =>
    period.groupsByWeek
    ? '${_shortDate(bucket.start)} – ${_shortDate(bucket.end)}'
    : '${AppStrings.weekdaysShort[bucket.start.weekday - 1]}, '
          '${_shortDate(bucket.start)}';

class _Kpi {
  const _Kpi(this.label, this.value, [this.note]);

  final String label;
  final String value;
  final String? note;
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.tiles});

  final List<_Kpi> tiles;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 520 ? 3 : 2;
        final width =
            (constraints.maxWidth - AppSpacing.m * (columns - 1)) / columns;
        return Wrap(
          spacing: AppSpacing.m,
          runSpacing: AppSpacing.m,
          children: [
            for (final tile in tiles)
              SizedBox(
                width: width,
                child: _KpiTile(tile: tile),
              ),
          ],
        );
      },
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({required this.tile});

  final _Kpi tile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return MergeSemantics(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tile.label, style: muted),
              const SizedBox(height: AppSpacing.xs),
              Text(
                tile.value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(tile.note ?? ' ', style: muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopRow extends StatelessWidget {
  const _TopRow({required this.icon, required this.title, required this.value});

  final IconData icon;
  final String title;
  final NamedCount? value;

  @override
  Widget build(BuildContext context) {
    final value = this.value;
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(
        value == null
            ? AppStrings.kpiNoData
            : AppStrings.kpiTopValue(value.name, value.count),
      ),
    );
  }
}

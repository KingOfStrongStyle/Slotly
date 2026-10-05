import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/app_strings.dart';
import '../../../core/lifecycle/lifecycle_event.dart';
import '../../../core/lifecycle/lifecycle_logger.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/responsive.dart';

/// Lab 1: shows the current lifecycle state and the numbered journal.
class DiagnosticsScreen extends StatelessWidget {
  const DiagnosticsScreen({super.key, required this.logger});

  final LifecycleLogger logger;

  void _clear(BuildContext context) {
    logger.clear();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text(AppStrings.diagnosticsCleared)),
      );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: logger,
      builder: (context, _) {
        // Newest first: the latest transition is what the user just caused.
        final events = logger.events.reversed.toList();
        return Scaffold(
          appBar: AppBar(
            title: const Text(AppStrings.diagnosticsTitle),
            actions: [
              IconButton(
                tooltip: AppStrings.diagnosticsClear,
                icon: const Icon(Icons.delete_sweep_outlined),
                onPressed: events.isEmpty ? null : () => _clear(context),
              ),
            ],
          ),
          body: ResponsiveCenter(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.l),
                  sliver: SliverToBoxAdapter(
                    child: _CurrentStateCard(state: logger.currentState),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      AppStrings.diagnosticsJournal,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                if (events.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: EmptyState(
                        icon: Icons.history_toggle_off,
                        title: AppStrings.diagnosticsEmptyTitle,
                        message: AppStrings.diagnosticsEmptyMessage,
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                    sliver: SliverList.builder(
                      itemCount: events.length,
                      itemBuilder: (context, index) =>
                          _EventTile(event: events[index]),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CurrentStateCard extends StatelessWidget {
  const _CurrentStateCard({required this.state});

  final AppLifecycleState? state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = this.state;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.diagnosticsCurrentState,
              style: theme.textTheme.labelMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              state == null
                  ? AppStrings.diagnosticsUnknownState
                  : '${state.name} · ${lifecycleStateTitle(state)}',
              style: theme.textTheme.titleLarge,
            ),
            if (state != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(describeLifecycleState(state)),
            ],
            const SizedBox(height: AppSpacing.m),
            Text(
              AppStrings.diagnosticsHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final LifecycleEvent event;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: colors.secondaryContainer,
        foregroundColor: colors.onSecondaryContainer,
        child: Text('#${event.sequenceNumber}'),
      ),
      title: Text('${event.state.name} · ${lifecycleStateTitle(event.state)}'),
      subtitle: Text(event.readableDescription),
      trailing: Text(Formatters.timeWithSeconds(event.occurredAt)),
      isThreeLine: true,
    );
  }
}

import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/section_title.dart';
import '../data/reminder_service.dart';
import '../domain/reminder_planner.dart';
import 'reminder_coordinator.dart';

/// Settings and status of local reminders: the switch, the Android
/// permission, and the list of reminders planned for upcoming bookings.
/// The list doubles as a manual test aid.
class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key, required this.coordinator});

  final ReminderCoordinator coordinator;

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  int? _pendingInSystem;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    await widget.coordinator.refreshPermission();
    final pending = await widget.coordinator.service.pendingIds();
    if (mounted) setState(() => _pendingInSystem = pending.length);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final coordinator = widget.coordinator;
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.remindersTitle)),
      body: ListenableBuilder(
        listenable: coordinator,
        builder: (context, _) {
          final permission = coordinator.permission;
          final muted = theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          );
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
            children: [
              ResponsiveCenter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SwitchListTile(
                      secondary: const Icon(
                        Icons.notifications_active_outlined,
                      ),
                      title: const Text(AppStrings.remindersEnabled),
                      subtitle: const Text(AppStrings.remindersEnabledHint),
                      value: coordinator.isEnabled,
                      onChanged: (value) async {
                        await coordinator.setEnabled(value);
                        await _refresh();
                      },
                    ),
                    ListTile(
                      leading: Icon(
                        permission == ReminderPermission.granted
                            ? Icons.check_circle_outline
                            : Icons.notifications_off_outlined,
                        color: permission == ReminderPermission.denied
                            ? theme.colorScheme.error
                            : null,
                      ),
                      title: const Text(AppStrings.remindersPermission),
                      subtitle: Text(switch (permission) {
                        ReminderPermission.granted =>
                          AppStrings.remindersPermissionGranted,
                        ReminderPermission.denied =>
                          AppStrings.remindersPermissionDenied,
                        ReminderPermission.unknown =>
                          AppStrings.remindersPermissionUnknown,
                      }),
                    ),
                    if (permission != ReminderPermission.granted)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.l,
                        ),
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await coordinator.requestPermission();
                            await _refresh();
                          },
                          icon: const Icon(Icons.notifications_outlined),
                          label: const Text(
                            AppStrings.remindersRequestPermission,
                          ),
                        ),
                      ),
                    const SectionTitle(AppStrings.remindersPlanned),
                    if (coordinator.planned.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.l,
                        ),
                        child: Text(
                          AppStrings.remindersPlannedEmpty,
                          style: muted,
                        ),
                      )
                    else
                      for (final reminder in coordinator.planned)
                        ListTile(
                          leading: const Icon(Icons.alarm),
                          title: Text(Formatters.dateTime(reminder.fireAt)),
                          subtitle: Text(
                            '${_kindLabel(reminder.kind)} · ${reminder.body}',
                          ),
                        ),
                    if (_pendingInSystem case final count?)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.l,
                          AppSpacing.s,
                          AppSpacing.l,
                          0,
                        ),
                        child: Text(
                          AppStrings.remindersPendingInSystem(count),
                          style: muted,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.l),
                      child: Text(AppStrings.remindersLocalNote, style: muted),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _kindLabel(ReminderKind kind) => switch (kind) {
    ReminderKind.dayBefore => AppStrings.reminderKindDayBefore,
    ReminderKind.morning => AppStrings.reminderKindMorning,
    ReminderKind.hourBefore => AppStrings.reminderKindHourBefore,
  };
}

import 'package:flutter/material.dart';

import '../../../app/app_controller.dart';
import '../../../app/theme.dart';
import '../../../core/app_strings.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/section_title.dart';
import '../../../core/widgets/slotly_logo.dart';

/// "Профиль" tab: demo user, local settings and links to the lab tools.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.appController,
    required this.onOpenDiagnostics,
  });

  final AppController appController;
  final VoidCallback onOpenDiagnostics;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appController,
      builder: (context, _) => LayoutBuilder(
        builder: (context, constraints) {
          final gutter = responsiveGutter(constraints.maxWidth);
          return CustomScrollView(
            slivers: [
              const SliverAppBar(
                pinned: true,
                title: Text(AppStrings.profileTitle),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(gutter, 0, gutter, AppSpacing.xl),
                sliver: SliverList.list(
                  children: [
                    const _UserHeader(),
                    const SectionTitle(AppStrings.profileSettingsSection),
                    SwitchListTile(
                      secondary: const Icon(Icons.dark_mode_outlined),
                      title: const Text(AppStrings.profileDarkTheme),
                      subtitle: const Text(AppStrings.profileDarkThemeHint),
                      value: appController.isDarkMode,
                      onChanged: appController.setDarkMode,
                    ),
                    SwitchListTile(
                      secondary: const Icon(Icons.notifications_outlined),
                      title: const Text(AppStrings.profileNotifications),
                      subtitle: const Text(AppStrings.profileNotificationsHint),
                      value: appController.demoNotificationsEnabled,
                      onChanged: appController.setDemoNotifications,
                    ),
                    const SectionTitle(AppStrings.profileToolsSection),
                    ListTile(
                      leading: const Icon(Icons.monitor_heart_outlined),
                      title: const Text(AppStrings.diagnosticsTitle),
                      subtitle: const Text(AppStrings.profileDiagnosticsHint),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: onOpenDiagnostics,
                    ),
                    const SectionTitle(AppStrings.profileAboutSection),
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text(AppStrings.profileAbout),
                      subtitle: const Text(AppStrings.appVersionLabel),
                      onTap: () => showAboutDialog(
                        context: context,
                        applicationName: AppStrings.appName,
                        applicationVersion: AppStrings.appVersion,
                        applicationIcon: const SlotlyLogo(size: 48),
                        children: const [Text(AppStrings.profileAboutText)],
                      ),
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
}

class _UserHeader extends StatelessWidget {
  const _UserHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: theme.colorScheme.primaryContainer,
              foregroundColor: theme.colorScheme.onPrimaryContainer,
              child: const Text(AppStrings.profileDemoUserInitials),
            ),
            const SizedBox(width: AppSpacing.l),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.profileDemoUserName,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    AppStrings.profileDemoUserNote,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

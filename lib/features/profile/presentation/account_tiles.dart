import 'package:flutter/material.dart';

import '../../../app/app_controller.dart';
import '../../../app/theme.dart';
import '../../../core/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/section_title.dart';
import '../../../core/widgets/slotly_logo.dart';
import '../../auth/domain/app_user.dart';

/// Pieces of the profile shared by the customer and the owner shells.
abstract final class AccountTiles {
  static Widget userHeader(BuildContext context, AppUser user) {
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
              child: Text(Formatters.initials(user.displayName)),
            ),
            const SizedBox(width: AppSpacing.l),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.displayName, style: theme.textTheme.titleMedium),
                  Text(
                    '${user.isOwner ? AppStrings.roleOwner : AppStrings.roleClient}'
                    ' · ${AppStrings.profileSignedInAs} ${user.login}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    AppStrings.profileDemoAccountNote,
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

  static Widget darkTheme(AppController controller) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => SwitchListTile(
      secondary: const Icon(Icons.dark_mode_outlined),
      title: const Text(AppStrings.profileDarkTheme),
      subtitle: const Text(AppStrings.profileDarkThemeHint),
      value: controller.isDarkMode,
      onChanged: controller.setDarkMode,
    ),
  );

  static List<Widget> developerTools({
    required VoidCallback onOpenDiagnostics,
    required VoidCallback onOpenGestureLab,
  }) => [
    const SectionTitle(AppStrings.profileDevSection),
    ListTile(
      leading: const Icon(Icons.monitor_heart_outlined),
      title: const Text(AppStrings.diagnosticsTitle),
      subtitle: const Text(AppStrings.profileDiagnosticsHint),
      trailing: const Icon(Icons.chevron_right),
      onTap: onOpenDiagnostics,
    ),
    ListTile(
      leading: const Icon(Icons.gesture),
      title: const Text(AppStrings.gestureLabTitle),
      subtitle: const Text(AppStrings.profileGestureLabHint),
      trailing: const Icon(Icons.chevron_right),
      onTap: onOpenGestureLab,
    ),
  ];

  static List<Widget> about(BuildContext context) => [
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
  ];

  static Widget signOut(BuildContext context, VoidCallback onSignOut) =>
      ListTile(
        leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
        title: Text(
          AppStrings.signOut,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        onTap: onSignOut,
      );
}

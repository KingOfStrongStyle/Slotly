import 'package:flutter/material.dart';

import '../../../app/app_controller.dart';
import '../../../app/theme.dart';
import '../../../core/app_strings.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/section_title.dart';
import '../../auth/domain/app_user.dart';
import 'account_tiles.dart';

/// "Профиль" tab of the customer: account, settings, developer tools and
/// sign-out.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.user,
    required this.appController,
    required this.onOpenReminders,
    required this.onOpenDiagnostics,
    required this.onOpenGestureLab,
    required this.onSignOut,
  });

  final AppUser user;
  final AppController appController;
  final VoidCallback onOpenReminders;
  final VoidCallback onOpenDiagnostics;
  final VoidCallback onOpenGestureLab;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
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
                  AccountTiles.userHeader(context, user),
                  const SectionTitle(AppStrings.profileSettingsSection),
                  AccountTiles.darkTheme(appController),
                  ListTile(
                    leading: const Icon(Icons.notifications_outlined),
                    title: const Text(AppStrings.profileReminders),
                    subtitle: const Text(AppStrings.profileRemindersHint),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: onOpenReminders,
                  ),
                  ...AccountTiles.developerTools(
                    onOpenDiagnostics: onOpenDiagnostics,
                    onOpenGestureLab: onOpenGestureLab,
                  ),
                  ...AccountTiles.about(context),
                  const SizedBox(height: AppSpacing.m),
                  AccountTiles.signOut(context, onSignOut),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

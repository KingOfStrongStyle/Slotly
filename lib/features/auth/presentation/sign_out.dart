import 'package:flutter/material.dart';

import '../../../core/app_strings.dart';
import 'session_controller.dart';

Future<void> confirmSignOut(
  BuildContext context,
  SessionController session,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.logout),
      title: const Text(AppStrings.signOutConfirmTitle),
      content: const Text(AppStrings.signOutConfirmMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(AppStrings.signOutCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text(AppStrings.signOut),
        ),
      ],
    ),
  );
  if (confirmed == true) await session.signOut();
}

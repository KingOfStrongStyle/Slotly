import 'package:flutter/material.dart';

import '../../../../core/app_strings.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/booking.dart';

Future<bool> showCancelBookingDialog(
  BuildContext context,
  Booking booking,
) async {
  final colors = Theme.of(context).colorScheme;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: Icon(Icons.event_busy, color: colors.error),
      title: const Text(AppStrings.cancelDialogTitle),
      content: Text(
        AppStrings.cancelDialogMessage(
          booking.serviceTitle,
          Formatters.dateTime(booking.startAt),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(AppStrings.cancelDialogKeep),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: colors.error,
            foregroundColor: colors.onError,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text(AppStrings.cancelDialogConfirm),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

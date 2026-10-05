import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/app_strings.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/info_row.dart';
import '../../domain/booking.dart';

enum BookingAction { details, cancel }

/// Opened by a tap: main information about the booking.
Future<void> showBookingDetailsSheet(
  BuildContext context,
  Booking booking, {
  VoidCallback? onCancel,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) {
      final theme = Theme.of(context);
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            0,
            AppSpacing.xl,
            AppSpacing.l,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.bookingDetailsTitle,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.m),
              InfoRow(
                icon: Icons.storefront_outlined,
                label: AppStrings.confirmService,
                value: booking.serviceTitle,
              ),
              InfoRow(
                icon: Icons.person_outline,
                label: AppStrings.confirmSpecialist,
                value: '${booking.specialist.name}, ${booking.specialist.role}',
              ),
              InfoRow(
                icon: Icons.calendar_today_outlined,
                label: AppStrings.confirmDate,
                value: Formatters.dayWithWeekday(booking.startAt),
              ),
              InfoRow(
                icon: Icons.schedule,
                label: AppStrings.confirmTime,
                value: Formatters.timeRange(booking.startAt, booking.endAt),
              ),
              InfoRow(
                icon: booking.isActive
                    ? Icons.check_circle_outline
                    : Icons.cancel_outlined,
                label: AppStrings.bookingDetailsStatus,
                value: booking.isActive
                    ? AppStrings.bookingStatusConfirmed
                    : AppStrings.bookingStatusCancelled,
              ),
              if (booking.comment.isNotEmpty)
                InfoRow(
                  icon: Icons.notes,
                  label: AppStrings.confirmComment,
                  value: booking.comment,
                ),
              InfoRow(
                icon: Icons.history,
                label: AppStrings.bookingDetailsCreatedAt,
                value: Formatters.dateTime(booking.createdAt),
              ),
              if (onCancel != null) ...[
                const SizedBox(height: AppSpacing.l),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    onCancel();
                  },
                  icon: const Icon(Icons.event_busy),
                  label: const Text(AppStrings.bookingActionCancel),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

/// Opened by a long press: list of actions for the booking.
Future<BookingAction?> showBookingActionsSheet(
  BuildContext context,
  Booking booking,
) {
  return showModalBottomSheet<BookingAction>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final colors = Theme.of(context).colorScheme;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                AppStrings.bookingActionsTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: Text(
                '${booking.serviceTitle}, '
                '${Formatters.dateTime(booking.startAt)}',
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text(AppStrings.bookingActionDetails),
              onTap: () => Navigator.of(context).pop(BookingAction.details),
            ),
            if (booking.isActive)
              ListTile(
                leading: Icon(Icons.event_busy, color: colors.error),
                title: Text(
                  AppStrings.bookingActionCancel,
                  style: TextStyle(color: colors.error),
                ),
                onTap: () => Navigator.of(context).pop(BookingAction.cancel),
              ),
          ],
        ),
      );
    },
  );
}

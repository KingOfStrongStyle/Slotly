import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/app_strings.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/info_row.dart';
import '../../domain/booking.dart';

enum BookingAction { details, reschedule, cancel, review }

/// Opened by a tap: everything about the booking and the buttons for each
/// available action. These buttons are the accessible alternative to the
/// swipe and long-press gestures.
///
/// [onCheckIn] is passed only while check-in is open; otherwise
/// [checkInAvailability] explains when it will be possible.
Future<void> showBookingDetailsSheet(
  BuildContext context,
  Booking booking, {
  CheckInAvailability? checkInAvailability,
  VoidCallback? onCheckIn,
  VoidCallback? onReschedule,
  VoidCallback? onCancel,
  VoidCallback? onWriteReview,
  VoidCallback? onComplete,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) {
      final theme = Theme.of(context);
      void run(VoidCallback action) {
        Navigator.of(context).pop();
        action();
      }

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
                icon: Icons.confirmation_number_outlined,
                label: AppStrings.bookingTicket,
                value: booking.ticketNumber,
              ),
              if (booking.organizationName.isNotEmpty)
                InfoRow(
                  icon: Icons.storefront_outlined,
                  label: AppStrings.bookingDetailsPlace,
                  value: booking.organizationName,
                ),
              InfoRow(
                icon: Icons.content_cut,
                label: AppStrings.confirmService,
                value: booking.priceLabel == null
                    ? booking.serviceTitle
                    : '${booking.serviceTitle} · ${booking.priceLabel}',
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
              if (booking.priceKzt > 0)
                InfoRow(
                  icon: Icons.payments_outlined,
                  label: AppStrings.bookingDetailsPrice,
                  value: Formatters.price(booking.priceKzt),
                ),
              InfoRow(
                icon: _statusIcon(booking),
                label: AppStrings.bookingDetailsStatus,
                value: bookingStatusText(booking),
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
              if (checkInAvailability == CheckInAvailability.tooEarly &&
                  onCheckIn == null) ...[
                const SizedBox(height: AppSpacing.s),
                Text(
                  AppStrings.bookingCheckInOpensAt(
                    Formatters.dateTime(booking.checkInOpensAt),
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.l),
              if (onCheckIn != null)
                _SheetButton.primary(
                  icon: Icons.how_to_reg,
                  label: AppStrings.bookingCheckInAction,
                  onPressed: () => run(onCheckIn),
                ),
              if (onComplete != null)
                _SheetButton.primary(
                  icon: Icons.task_alt,
                  label: AppStrings.ownerBookingComplete,
                  onPressed: () => run(onComplete),
                ),
              if (onWriteReview != null)
                _SheetButton.primary(
                  icon: Icons.rate_review_outlined,
                  label: AppStrings.reviewWrite,
                  onPressed: () => run(onWriteReview),
                ),
              if (onReschedule != null)
                _SheetButton.outlined(
                  icon: Icons.update,
                  label: AppStrings.bookingActionReschedule,
                  onPressed: () => run(onReschedule),
                ),
              if (onCancel != null)
                _SheetButton.outlined(
                  icon: Icons.event_busy,
                  label: AppStrings.bookingActionCancel,
                  color: theme.colorScheme.error,
                  onPressed: () => run(onCancel),
                ),
            ],
          ),
        ),
      );
    },
  );
}

class _SheetButton extends StatelessWidget {
  const _SheetButton.primary({
    required this.icon,
    required this.label,
    required this.onPressed,
  }) : filled = true,
       color = null;

  const _SheetButton.outlined({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  }) : filled = false;

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool filled;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: filled
          ? FilledButton.icon(
              onPressed: onPressed,
              icon: Icon(icon),
              label: Text(label),
            )
          : OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: color),
              onPressed: onPressed,
              icon: Icon(icon),
              label: Text(label),
            ),
    );
  }
}

IconData _statusIcon(Booking booking) => switch (booking.status) {
  BookingStatus.cancelled => Icons.cancel_outlined,
  BookingStatus.completed => Icons.task_alt,
  BookingStatus.confirmed =>
    booking.isCheckedIn ? Icons.how_to_reg : Icons.check_circle_outline,
};

String bookingStatusText(Booking booking) {
  switch (booking.status) {
    case BookingStatus.cancelled:
      return AppStrings.bookingStatusCancelled;
    case BookingStatus.completed:
      return AppStrings.bookingStatusCompleted;
    case BookingStatus.confirmed:
      final checkedInAt = booking.checkedInAt;
      return checkedInAt == null
          ? AppStrings.bookingStatusConfirmed
          : AppStrings.bookingCheckedInAt(Formatters.time(checkedInAt));
  }
}

/// Opened by a long press: the same actions as the details sheet, as a
/// short menu.
Future<BookingAction?> showBookingActionsSheet(
  BuildContext context,
  Booking booking, {
  required bool canChange,
  required bool canReview,
}) {
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
            if (canReview)
              ListTile(
                leading: const Icon(Icons.rate_review_outlined),
                title: const Text(AppStrings.reviewWrite),
                onTap: () => Navigator.of(context).pop(BookingAction.review),
              ),
            if (canChange)
              ListTile(
                leading: const Icon(Icons.update),
                title: const Text(AppStrings.bookingActionReschedule),
                onTap: () =>
                    Navigator.of(context).pop(BookingAction.reschedule),
              ),
            if (canChange)
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

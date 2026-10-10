import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/app_strings.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/booking.dart';

/// One booking: date badge, service, time, specialist and ticket number.
///
/// [subtitle] replaces the place name (the owner sees the client instead);
/// [trailing] holds an inline action such as "Оставить отзыв".
class BookingTile extends StatelessWidget {
  const BookingTile({
    super.key,
    required this.booking,
    required this.onTap,
    this.onLongPress,
    this.trailing,
    this.note,
    this.subtitle,
  });

  final Booking booking;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Widget? trailing;
  final String? note;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final details =
        '${Formatters.timeRange(booking.startAt, booking.endAt)} · '
        '${booking.specialist.name} · '
        '${AppStrings.bookingTicketShort(booking.ticketNumber)}';
    final place = subtitle ?? booking.organizationName;
    final (statusText, statusColor) = switch (booking.status) {
      BookingStatus.cancelled => (
        AppStrings.bookingStatusCancelled,
        colors.error,
      ),
      BookingStatus.completed => (
        note ?? AppStrings.bookingStatusCompleted,
        SlotlyColors.of(context).success,
      ),
      BookingStatus.confirmed when booking.isCheckedIn => (
        AppStrings.bookingStatusCheckedIn,
        colors.primary,
      ),
      BookingStatus.confirmed => (null, null),
    };

    return Card(
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Row(
            children: [
              _DateBadge(date: booking.startAt, isActive: booking.isActive),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.serviceTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        decoration: booking.isCancelled
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    if (place.isNotEmpty)
                      Text(
                        place,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      details,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    if (statusText != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        statusText,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: statusColor,
                        ),
                      ),
                    ],
                    if (trailing case final action?)
                      Align(alignment: Alignment.centerLeft, child: action),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateBadge extends StatelessWidget {
  const _DateBadge({required this.date, required this.isActive});

  final DateTime date;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final background = isActive
        ? colors.primaryContainer
        : colors.surfaceContainerHighest;
    final foreground = isActive
        ? colors.onPrimaryContainer
        : colors.onSurfaceVariant;
    return Container(
      constraints: const BoxConstraints(minWidth: 56),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s,
        vertical: AppSpacing.s,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.m),
      ),
      child: Column(
        children: [
          Text(
            '${date.day}',
            style: theme.textTheme.titleLarge?.copyWith(color: foreground),
          ),
          Text(
            AppStrings.monthsGenitive[date.month - 1].substring(0, 3),
            style: theme.textTheme.labelSmall?.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}

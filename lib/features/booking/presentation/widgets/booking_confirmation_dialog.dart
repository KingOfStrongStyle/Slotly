import 'package:flutter/material.dart';

import '../../../../core/app_strings.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/info_row.dart';
import '../../domain/booking_repository.dart';

/// Shows the booking summary and resolves to `true` only when the user
/// presses "Подтвердить". Dismissing the dialog means "not confirmed".
Future<bool> showBookingConfirmationDialog(
  BuildContext context,
  BookingRequest request,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.event_available),
      title: const Text(AppStrings.confirmTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InfoRow(
              icon: Icons.storefront_outlined,
              label: AppStrings.confirmService,
              value: request.service.title,
            ),
            InfoRow(
              icon: Icons.person_outline,
              label: AppStrings.confirmSpecialist,
              value: request.specialist.name,
            ),
            InfoRow(
              icon: Icons.calendar_today_outlined,
              label: AppStrings.confirmDate,
              value: Formatters.dayWithWeekday(request.startAt),
            ),
            InfoRow(
              icon: Icons.schedule,
              label: AppStrings.confirmTime,
              value: Formatters.timeRange(
                request.startAt,
                request.startAt.add(request.service.duration),
              ),
            ),
            InfoRow(
              icon: Icons.payments_outlined,
              label: AppStrings.confirmPrice,
              value: Formatters.price(request.service.priceKzt),
            ),
            if (request.comment.isNotEmpty)
              InfoRow(
                icon: Icons.notes,
                label: AppStrings.confirmComment,
                value: request.comment,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(AppStrings.confirmEdit),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text(AppStrings.confirmSubmit),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

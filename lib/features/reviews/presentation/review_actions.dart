import 'package:flutter/material.dart';

import '../../../core/app_strings.dart';
import '../../booking/domain/booking.dart';
import '../data/review_repository.dart';
import '../domain/review.dart';
import 'review_form_sheet.dart';

/// Shared flows for writing, editing and deleting a review, used from the
/// booking list and from the reviews screen. Each shows the result in a
/// SnackBar.

Future<void> writeReview(
  BuildContext context,
  ReviewRepository reviews,
  Booking booking,
) async {
  final input = await showReviewForm(
    context,
    subtitle: '${booking.organizationName} · ${booking.serviceTitle}',
  );
  if (input == null || !context.mounted) return;
  await _run(
    context,
    () => reviews.createReview(
      bookingId: booking.id,
      rating: input.rating,
      text: input.text,
    ),
    AppStrings.reviewPublished,
  );
}

Future<void> editReview(
  BuildContext context,
  ReviewRepository reviews,
  Review review,
) async {
  final input = await showReviewForm(
    context,
    subtitle: review.serviceTitle,
    initial: review,
  );
  if (input == null || !context.mounted) return;
  await _run(
    context,
    () =>
        reviews.updateReview(review.id, rating: input.rating, text: input.text),
    AppStrings.reviewUpdated,
  );
}

Future<void> deleteReview(
  BuildContext context,
  ReviewRepository reviews,
  Review review,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text(AppStrings.reviewDeleteConfirmTitle),
      content: const Text(AppStrings.reviewDeleteConfirmMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(AppStrings.reviewKeep),
        ),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text(AppStrings.reviewDeleteConfirm),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  await _run(
    context,
    () => reviews.deleteReview(review.id),
    AppStrings.reviewDeleted,
  );
}

Future<void> _run(
  BuildContext context,
  Future<Object?> Function() action,
  String success,
) async {
  final messenger = ScaffoldMessenger.of(context);
  String message;
  try {
    await action();
    message = success;
  } on ReviewNotAllowedException {
    message = AppStrings.reviewNotAllowed;
  } on Exception {
    message = AppStrings.reviewFailed;
  }
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

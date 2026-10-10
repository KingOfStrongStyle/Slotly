import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../features/reviews/domain/rating_summary.dart';
import '../app_strings.dart';

class RatingBadge extends StatelessWidget {
  const RatingBadge({super.key, required this.summary, this.compact = false});

  final RatingSummary summary;

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final average = summary.average;
    if (average == null) {
      return Text(AppStrings.ratingNoReviews, style: muted);
    }
    final value = formatRating(average);
    return Semantics(
      label: AppStrings.ratingLabel(value, summary.count),
      excludeSemantics: true,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Icon(
            Icons.star_rounded,
            size: 18,
            color: SlotlyColors.of(context).rating,
          ),
          const SizedBox(width: 2),
          Text(
            value,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            compact
                ? '(${summary.count})'
                : '· ${AppStrings.reviewsCount(summary.count)}',
            style: muted,
          ),
        ],
      ),
    );
  }
}

String formatRating(double value) =>
    value.toStringAsFixed(1).replaceAll('.', ',');

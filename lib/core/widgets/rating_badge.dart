import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../features/reviews/domain/rating_summary.dart';
import '../app_strings.dart';

/// "★ 4.6 · 18 отзывов" or "Нет отзывов". One semantics label for the
/// whole badge, so TalkBack reads it as a phrase.
class RatingBadge extends StatelessWidget {
  const RatingBadge({super.key, required this.summary, this.compact = false});

  final RatingSummary summary;

  /// Compact form shows the count without the word "отзывов".
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
      // Wrap instead of Row: with a large font the count moves to the next
      // line instead of overflowing.
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

/// `4.56` -> `4,6`: one decimal with a Russian comma.
String formatRating(double value) =>
    value.toStringAsFixed(1).replaceAll('.', ',');

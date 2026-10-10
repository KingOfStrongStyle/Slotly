import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/rating_badge.dart';
import '../domain/rating_summary.dart';
import '../domain/review.dart';

/// Five stars, filled up to [rating]. Decorative: the caller provides the
/// text alternative.
class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.rating, this.size = 16});

  final int rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = SlotlyColors.of(context).rating;
    final empty = Theme.of(context).colorScheme.outlineVariant;
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var star = 1; star <= Review.maxRating; star++)
            Icon(
              star <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
              size: size,
              color: star <= rating ? color : empty,
            ),
        ],
      ),
    );
  }
}

/// Average, count and a horizontal bar per star. Bars are plain widgets,
/// and every row has a text label, so the numbers are readable without
/// colors and by TalkBack.
class RatingDistribution extends StatelessWidget {
  const RatingDistribution({super.key, required this.summary});

  final RatingSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final average = summary.average;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                average == null ? '—' : formatRating(average),
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              StarRow(rating: (average ?? 0).round()),
              const SizedBox(height: AppSpacing.xs),
              Text(
                AppStrings.reviewsCount(summary.count),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.l),
        Expanded(
          child: Column(
            children: [
              for (var stars = Review.maxRating; stars >= 1; stars--)
                _StarBar(
                  stars: stars,
                  count: summary.countFor(stars),
                  share: summary.shareFor(stars),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StarBar extends StatelessWidget {
  const _StarBar({
    required this.stars,
    required this.count,
    required this.share,
  });

  final int stars;
  final int count;
  final double share;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelMedium;
    return Semantics(
      label: AppStrings.starsCountLabel(stars, count),
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(width: 28, child: Text('$stars', style: labelStyle)),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 8,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(
                        color: theme.colorScheme.surfaceContainerHighest,
                      ),
                      FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: share,
                        child: ColoredBox(
                          color: SlotlyColors.of(context).rating,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 32,
              child: Text(
                '$count',
                textAlign: TextAlign.end,
                style: labelStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One review. When [onEdit] and [onDelete] are given (own review), a long
/// press and the "⋮" button open the same action menu. [onReply] is the
/// owner's action.
class ReviewTile extends StatelessWidget {
  const ReviewTile({
    super.key,
    required this.review,
    this.isOwn = false,
    this.onEdit,
    this.onDelete,
    this.onReply,
  });

  final Review review;
  final bool isOwn;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onReply;

  bool get _hasMenu => onEdit != null || onDelete != null;

  Future<void> _openMenu(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                AppStrings.reviewActions,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (onEdit != null)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text(AppStrings.reviewEdit),
                onTap: () => Navigator.of(context).pop('edit'),
              ),
            if (onDelete != null)
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  AppStrings.reviewDelete,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () => Navigator.of(context).pop('delete'),
              ),
          ],
        ),
      ),
    );
    switch (action) {
      case 'edit':
        onEdit?.call();
      case 'delete':
        onDelete?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final reply = review.reply;
    final date = Formatters.dayWithWeekday(
      review.updatedAt ?? review.createdAt,
    );
    return Card(
      child: InkWell(
        onLongPress: _hasMenu ? () => _openMenu(context) : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.l,
            AppSpacing.m,
            AppSpacing.s,
            AppSpacing.m,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isOwn
                              ? '${review.authorName} · ${AppStrings.reviewYours}'
                              : review.authorName,
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 2),
                        Semantics(
                          label: AppStrings.reviewStarSemantics(review.rating),
                          child: StarRow(rating: review.rating),
                        ),
                      ],
                    ),
                  ),
                  if (_hasMenu)
                    IconButton(
                      tooltip: AppStrings.reviewActions,
                      icon: const Icon(Icons.more_vert),
                      onPressed: () => _openMenu(context),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.s),
                child: Text(
                  '${review.serviceTitle} · $date'
                  '${review.updatedAt != null ? ' · ${AppStrings.reviewEdited}' : ''}',
                  style: muted,
                ),
              ),
              if (review.text.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s),
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.s),
                  child: Text(review.text, style: theme.textTheme.bodyMedium),
                ),
              ],
              if (reply != null) ...[
                const SizedBox(height: AppSpacing.m),
                Container(
                  margin: const EdgeInsets.only(right: AppSpacing.s),
                  padding: const EdgeInsets.all(AppSpacing.m),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(AppRadii.m),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.reviewOwnerReply,
                        style: theme.textTheme.labelMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(reply.text, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
              if (onReply != null && reply == null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: onReply,
                    icon: const Icon(Icons.reply),
                    label: const Text(AppStrings.ownerReviewReply),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

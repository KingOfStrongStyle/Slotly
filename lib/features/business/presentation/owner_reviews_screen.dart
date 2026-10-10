import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/app_strings.dart';
import '../../../core/state/live_query.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/responsive.dart';
import '../../reviews/data/review_repository.dart';
import '../../reviews/domain/rating_summary.dart';
import '../../reviews/domain/review.dart';
import '../../reviews/domain/review_rules.dart';
import '../../reviews/presentation/review_widgets.dart';
import '../../reviews/presentation/reviews_screen.dart';

/// Reviews of the owner's organization. The owner may answer a review but
/// has no way to change or delete it — neither here nor in the repository.
class OwnerReviewsScreen extends StatefulWidget {
  const OwnerReviewsScreen({
    super.key,
    required this.organizationId,
    required this.reviews,
  });

  final String organizationId;
  final ReviewRepository reviews;

  @override
  State<OwnerReviewsScreen> createState() => _OwnerReviewsScreenState();
}

class _OwnerReviewsScreenState extends State<OwnerReviewsScreen> {
  late final _query = LiveQuery<List<Review>>(
    () => widget.reviews.fetchOrganizationReviews(widget.organizationId),
    refreshOn: widget.reviews.changes,
  )..load();
  ReviewSort _sort = ReviewSort.newest;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _reply(Review review) async {
    final text = await showDialog<String>(
      context: context,
      builder: (context) => const _ReplyDialog(),
    );
    if (text == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    await widget.reviews.replyToReview(review.id, text);
    messenger.showSnackBar(
      const SnackBar(content: Text(AppStrings.ownerReplySent)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final gutter = responsiveGutter(constraints.maxWidth);
        return ListenableBuilder(
          listenable: _query,
          builder: (context, _) {
            final reviews = _query.data;
            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  title: const Text(AppStrings.ownerReviewsTitle),
                  actions: [
                    PopupMenuButton<ReviewSort>(
                      tooltip: AppStrings.reviewsSort,
                      icon: const Icon(Icons.sort),
                      initialValue: _sort,
                      onSelected: (value) => setState(() => _sort = value),
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: ReviewSort.newest,
                          child: Text(AppStrings.reviewsSortNewest),
                        ),
                        PopupMenuItem(
                          value: ReviewSort.lowest,
                          child: Text(AppStrings.reviewsSortLowest),
                        ),
                        PopupMenuItem(
                          value: ReviewSort.highest,
                          child: Text(AppStrings.reviewsSortHighest),
                        ),
                      ],
                    ),
                  ],
                ),
                if (reviews == null)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (reviews.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.rate_review_outlined,
                      title: AppStrings.reviewsEmptyTitle,
                      message: AppStrings.reviewsEmptyMessage,
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      gutter,
                      0,
                      gutter,
                      AppSpacing.xl,
                    ),
                    sliver: SliverList.list(
                      children: [
                        RatingDistribution(summary: RatingSummary.of(reviews)),
                        const SizedBox(height: AppSpacing.s),
                        Text(
                          AppStrings.ownerReviewsNote,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.m),
                        for (final review in sortReviews(reviews, _sort))
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.m,
                            ),
                            child: ReviewTile(
                              key: ValueKey(review.id),
                              review: review,
                              onReply: () => _reply(review),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ReplyDialog extends StatefulWidget {
  const _ReplyDialog();

  @override
  State<_ReplyDialog> createState() => _ReplyDialogState();
}

class _ReplyDialogState extends State<_ReplyDialog> {
  final _text = TextEditingController();
  bool _touched = false;

  @override
  void initState() {
    super.initState();
    // Rebuild on every edit, whatever the source of the change.
    _text.addListener(() => setState(() => _touched = true));
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final issues = ReviewRules.validateReply(_text.text);
    final error = !_touched
        ? null
        : issues.contains(ReviewIssue.replyEmpty)
        ? AppStrings.ownerReplyEmpty
        : issues.contains(ReviewIssue.replyTooLong)
        ? AppStrings.ownerReplyTooLong(ReviewRules.maxReplyLength)
        : null;
    return AlertDialog(
      title: const Text(AppStrings.ownerReplyTitle),
      content: TextField(
        controller: _text,
        autofocus: true,
        minLines: 3,
        maxLines: 6,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          helperText: AppStrings.ownerReplyHint,
          errorText: error,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.reviewKeep),
        ),
        FilledButton(
          onPressed: issues.isEmpty
              ? () => Navigator.of(context).pop(_text.text)
              : null,
          child: const Text(AppStrings.ownerReplySend),
        ),
      ],
    );
  }
}

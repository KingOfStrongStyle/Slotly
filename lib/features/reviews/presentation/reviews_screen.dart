import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/app_strings.dart';
import '../../../core/state/live_query.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/responsive.dart';
import '../data/review_repository.dart';
import '../domain/rating_summary.dart';
import '../domain/review.dart';
import 'review_actions.dart';
import 'review_widgets.dart';

enum ReviewSort { newest, highest, lowest }

List<Review> sortReviews(List<Review> reviews, ReviewSort sort) {
  final sorted = [...reviews];
  int byDate(Review a, Review b) => b.createdAt.compareTo(a.createdAt);
  switch (sort) {
    case ReviewSort.newest:
      sorted.sort(byDate);
    case ReviewSort.highest:
      sorted.sort((a, b) {
        final byRating = b.rating.compareTo(a.rating);
        return byRating != 0 ? byRating : byDate(a, b);
      });
    case ReviewSort.lowest:
      sorted.sort((a, b) {
        final byRating = a.rating.compareTo(b.rating);
        return byRating != 0 ? byRating : byDate(a, b);
      });
  }
  return sorted;
}

/// All reviews of an organization with the rating distribution and
/// sorting. The signed-in customer can edit or delete their own reviews.
class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({
    super.key,
    required this.organizationId,
    required this.organizationName,
    required this.reviews,
    required this.currentUserId,
  });

  final String organizationId;
  final String organizationName;
  final ReviewRepository reviews;

  /// Null for guests and owners: no review is "own".
  final String? currentUserId;

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.organizationName),
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
                value: ReviewSort.highest,
                child: Text(AppStrings.reviewsSortHighest),
              ),
              PopupMenuItem(
                value: ReviewSort.lowest,
                child: Text(AppStrings.reviewsSortLowest),
              ),
            ],
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _query,
        builder: (context, _) {
          final reviews = _query.data;
          if (reviews == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (reviews.isEmpty) {
            return const Center(
              child: EmptyState(
                icon: Icons.rate_review_outlined,
                title: AppStrings.reviewsEmptyTitle,
                message: AppStrings.reviewsEmptyMessage,
              ),
            );
          }
          final sorted = sortReviews(reviews, _sort);
          return LayoutBuilder(
            builder: (context, constraints) {
              final gutter = responsiveGutter(constraints.maxWidth);
              return ListView.separated(
                padding: EdgeInsets.fromLTRB(
                  gutter,
                  AppSpacing.l,
                  gutter,
                  AppSpacing.xl,
                ),
                itemCount: sorted.length + 1,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.m),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.s),
                      child: RatingDistribution(
                        summary: RatingSummary.of(reviews),
                      ),
                    );
                  }
                  final review = sorted[index - 1];
                  final isOwn = review.authorId == widget.currentUserId;
                  return ReviewTile(
                    key: ValueKey(review.id),
                    review: review,
                    isOwn: isOwn,
                    onEdit: isOwn
                        ? () => editReview(context, widget.reviews, review)
                        : null,
                    onDelete: isOwn
                        ? () => deleteReview(context, widget.reviews, review)
                        : null,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

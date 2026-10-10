import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slotly/core/app_strings.dart';
import 'package:slotly/data/seed/demo_accounts.dart';
import 'package:slotly/data/seed/demo_catalog.dart';
import 'package:slotly/features/reviews/data/review_repository.dart';
import 'package:slotly/features/reviews/domain/review.dart';
import 'package:slotly/features/reviews/presentation/review_widgets.dart';
import 'package:slotly/features/reviews/presentation/reviews_screen.dart';

import '../../helpers/test_app.dart';

void main() {
  late TestData data;
  late LocalReviewRepository reviews;

  Future<Review> pumpReviews(WidgetTester tester) async {
    data = await TestData.create(withActivity: true);
    data.signInAs('aliya');
    reviews = LocalReviewRepository(data.context);
    final own = data.database.tables.reviews.values.firstWhere(
      (r) => r.authorId == clientAliyaId && r.organizationId == orgNorth,
    );
    await pumpScreen(
      tester,
      ReviewsScreen(
        organizationId: orgNorth,
        organizationName: 'Барбершоп «Северный»',
        reviews: reviews,
        currentUserId: clientAliyaId,
      ),
    );
    return own;
  }

  Finder tileOf(Review review) => find.byKey(ValueKey(review.id));

  testWidgets('sorting by rating puts low ratings first', (tester) async {
    await pumpReviews(tester);
    await tester.tap(find.byTooltip(AppStrings.reviewsSort));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.reviewsSortLowest));
    await tester.pumpAndSettle();

    final tiles = tester
        .widgetList<ReviewTile>(find.byType(ReviewTile))
        .toList();
    final ratings = tiles.map((t) => t.review.rating).toList();
    expect(ratings, orderedEquals([...ratings]..sort()));
  });

  testWidgets('long press on an own review opens edit and delete', (
    tester,
  ) async {
    final own = await pumpReviews(tester);
    await tester.scrollUntilVisible(tileOf(own), 300);
    expect(
      find.descendant(
        of: tileOf(own),
        matching: find.textContaining(AppStrings.reviewYours),
      ),
      findsOneWidget,
    );

    await tester.longPress(tileOf(own));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.reviewEdit), findsOneWidget);
    await tester.tap(find.text(AppStrings.reviewDelete));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.reviewDeleteConfirm));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.reviewDeleted), findsOneWidget);
    expect(data.database.tables.reviews.containsKey(own.id), isFalse);
  });

  testWidgets('the "⋮" button is the alternative to long press', (
    tester,
  ) async {
    final own = await pumpReviews(tester);
    await tester.scrollUntilVisible(tileOf(own), 300);
    await tester.tap(
      find.descendant(
        of: tileOf(own),
        matching: find.byTooltip(AppStrings.reviewActions),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.reviewEdit));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('star-2')));
    await tester.pump();
    await tester.tap(find.text(AppStrings.reviewFormSave));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.reviewUpdated), findsOneWidget);
    expect(data.database.tables.reviews[own.id]!.rating, 2);
  });

  testWidgets('reviews of others have no action menu', (tester) async {
    await pumpReviews(tester);
    final foreign = tester
        .widgetList<ReviewTile>(find.byType(ReviewTile))
        .firstWhere((t) => t.review.authorId != clientAliyaId);
    expect(
      find.descendant(
        of: find.byKey(ValueKey(foreign.review.id)),
        matching: find.byTooltip(AppStrings.reviewActions),
      ),
      findsNothing,
    );
  });
}

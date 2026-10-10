import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme.dart';
import '../../../core/app_strings.dart';
import '../domain/review.dart';
import '../domain/review_rules.dart';

typedef ReviewInput = ({int rating, String text});

/// Opens the review form. Returns the entered rating and text, or null if
/// the customer closed the sheet.
Future<ReviewInput?> showReviewForm(
  BuildContext context, {
  required String subtitle,
  Review? initial,
}) => showModalBottomSheet<ReviewInput>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) => _ReviewForm(subtitle: subtitle, initial: initial),
);

class _ReviewForm extends StatefulWidget {
  const _ReviewForm({required this.subtitle, this.initial});

  final String subtitle;
  final Review? initial;

  @override
  State<_ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<_ReviewForm> {
  late int _rating = widget.initial?.rating ?? 0;
  late final _text = TextEditingController(text: widget.initial?.text ?? '');

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  List<ReviewIssue> get _issues =>
      ReviewRules.validate(rating: _rating, text: _text.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final issues = _issues;
    final ratingColor = SlotlyColors.of(context).rating;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
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
                AppStrings.reviewFormTitle,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                widget.subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.l),
              Text(
                AppStrings.reviewFormRating,
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  for (var star = 1; star <= Review.maxRating; star++)
                    Semantics(
                      selected: star == _rating,
                      child: IconButton(
                        key: ValueKey('star-$star'),
                        tooltip: AppStrings.reviewStarSemantics(star),
                        iconSize: 36,
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          setState(() => _rating = star);
                        },
                        icon: Icon(
                          star <= _rating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: star <= _rating
                              ? ratingColor
                              : theme.colorScheme.outline,
                        ),
                      ),
                    ),
                ],
              ),
              if (_rating == 0)
                Text(
                  AppStrings.reviewFormRatingRequired,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: AppSpacing.l),
              TextField(
                controller: _text,
                minLines: 3,
                maxLines: 6,
                maxLength: Review.maxTextLength,
                maxLengthEnforcement: MaxLengthEnforcement.none,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: AppStrings.reviewFormText,
                  helperText: AppStrings.reviewFormTextHint,
                  errorText: issues.contains(ReviewIssue.textTooLong)
                      ? AppStrings.reviewFormTextTooLong(Review.maxTextLength)
                      : null,
                ),
              ),
              const SizedBox(height: AppSpacing.l),
              FilledButton(
                onPressed: issues.isEmpty
                    ? () =>
                          Navigator.of(context)
                              .pop((rating: _rating, text: _text.text))
                    : null,
                child: Text(
                  widget.initial == null
                      ? AppStrings.reviewFormSubmit
                      : AppStrings.reviewFormSave,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

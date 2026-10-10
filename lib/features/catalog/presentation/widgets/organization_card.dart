import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme.dart';
import '../../../../core/app_strings.dart';
import '../../../../core/widgets/rating_badge.dart';
import '../../../favorites/presentation/favorite_button.dart';
import '../../../reviews/domain/rating_summary.dart';
import '../../domain/organization.dart';
import '../service_category_style.dart';
import 'business_photo_view.dart';

/// Catalog card of a business.
///
/// Tap opens the organization; double tap adds it to favorites (with a
/// heart animation and a light haptic click). The heart button does the
/// same for users who cannot or do not want to double-tap. When
/// [onToggleFavorite] is null (owner view) there is no favorite action.
class OrganizationCard extends StatefulWidget {
  const OrganizationCard({
    super.key,
    required this.organization,
    required this.rating,
    required this.cover,
    required this.isFavorite,
    required this.onTap,
    this.onToggleFavorite,
  });

  final Organization organization;
  final RatingSummary rating;
  final BusinessPhoto? cover;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback? onToggleFavorite;

  @override
  State<OrganizationCard> createState() => _OrganizationCardState();
}

class _OrganizationCardState extends State<OrganizationCard> {
  int _burst = 0;

  void _onDoubleTap() {
    // Double tap only adds: removing by an accidental double tap would be
    // surprising. Removal is done with the heart button.
    if (!widget.isFavorite) widget.onToggleFavorite?.call();
    HapticFeedback.lightImpact();
    setState(() => _burst++);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final organization = widget.organization;
    final canFavorite = widget.onToggleFavorite != null;
    // The heart button is a sibling of the tappable area, not its child:
    // otherwise every tap on it would wait for the double-tap timeout.
    return Card(
      child: Stack(
        children: [
          Semantics(
            button: true,
            hint: canFavorite ? AppStrings.favoriteDoubleTapHint : null,
            child: InkWell(
              onTap: widget.onTap,
              onDoubleTap: canFavorite ? _onDoubleTap : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AspectRatio(
                    aspectRatio: 2.4,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        BusinessPhotoView(
                          photo: widget.cover,
                          category: organization.category,
                          decodeWidth: 480,
                        ),
                        if (canFavorite) FavoriteBurst(trigger: _burst),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.l,
                      AppSpacing.m,
                      AppSpacing.l,
                      AppSpacing.l,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          organization.name,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          organization.category.label,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s),
                        RatingBadge(summary: widget.rating),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (canFavorite)
            Positioned(
              top: AppSpacing.s,
              right: AppSpacing.s,
              child: FavoriteButton(
                isFavorite: widget.isFavorite,
                onImage: true,
                onPressed: widget.onToggleFavorite,
              ),
            ),
        ],
      ),
    );
  }
}

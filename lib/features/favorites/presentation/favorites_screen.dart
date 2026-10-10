import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/app_strings.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/responsive.dart';
import '../../catalog/domain/organization.dart';
import '../../catalog/presentation/catalog_controller.dart';
import '../../catalog/presentation/widgets/organization_card.dart';

/// "Избранное" tab: organizations the customer saved.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({
    super.key,
    required this.controller,
    required this.onOrganizationSelected,
    required this.onBrowse,
  });

  final CatalogController controller;
  final ValueChanged<Organization> onOrganizationSelected;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final data = controller.data;
        final favorites = data == null
            ? const <Organization>[]
            : data.organizations.where((o) => data.isFavorite(o.id)).toList();
        return LayoutBuilder(
          builder: (context, constraints) {
            final gutter = responsiveGutter(constraints.maxWidth);
            return CustomScrollView(
              slivers: [
                const SliverAppBar(
                  pinned: true,
                  title: Text(AppStrings.favoritesTitle),
                ),
                if (data == null)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (favorites.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.favorite_border,
                      title: AppStrings.favoritesEmptyTitle,
                      message: AppStrings.favoritesEmptyMessage,
                      actionLabel: AppStrings.bookingsBrowseServices,
                      onAction: onBrowse,
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
                    sliver: SliverList.separated(
                      itemCount: favorites.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.m),
                      itemBuilder: (context, index) {
                        final organization = favorites[index];
                        return OrganizationCard(
                          key: ValueKey(organization.id),
                          organization: organization,
                          rating: data.ratingOf(organization.id),
                          cover: data.covers[organization.id],
                          isFavorite: true,
                          onTap: () => onOrganizationSelected(organization),
                          onToggleFavorite: () =>
                              controller.toggleFavorite(organization.id),
                        );
                      },
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

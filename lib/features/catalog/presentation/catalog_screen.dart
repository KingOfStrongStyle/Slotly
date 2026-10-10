import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/app_strings.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/responsive.dart';
import '../domain/organization.dart';
import '../domain/service.dart';
import '../domain/service_filter.dart';
import 'catalog_controller.dart';
import 'widgets/category_filter_bar.dart';
import 'widgets/organization_card.dart';
import 'widgets/service_card.dart';

enum CatalogMode { organizations, services }

/// "Каталог" tab: places (organizations) or individual services, one
/// search field and one category filter for both.
///
/// Query, category and mode are local UI state; the data comes from
/// [CatalogController], so the screen does not know where it is stored.
class CatalogScreen extends StatefulWidget {
  const CatalogScreen({
    super.key,
    required this.controller,
    required this.onOrganizationSelected,
    required this.onServiceSelected,
    this.initialCategory,
    this.onFavoriteChanged,
  });

  final CatalogController controller;
  final ValueChanged<Organization> onOrganizationSelected;
  final ValueChanged<Service> onServiceSelected;
  final ServiceCategory? initialCategory;

  /// Called after a favorite was toggled, with the new state.
  final void Function(Organization organization, bool isFavorite)?
  onFavoriteChanged;

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _searchController = TextEditingController();
  late ServiceCategory? _category = widget.initialCategory;
  CatalogMode _mode = CatalogMode.organizations;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() => _category = null);
  }

  Future<void> _toggleFavorite(Organization organization) async {
    final isFavorite = await widget.controller.toggleFavorite(organization.id);
    widget.onFavoriteChanged?.call(organization, isFavorite);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) => LayoutBuilder(
        builder: (context, constraints) {
          final gutter = responsiveGutter(constraints.maxWidth);
          return CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              const SliverAppBar(
                pinned: true,
                title: Text(AppStrings.tabCatalog),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(gutter, 0, gutter, AppSpacing.m),
                sliver: SliverToBoxAdapter(child: _buildSearchField()),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(gutter, 0, gutter, AppSpacing.m),
                sliver: SliverToBoxAdapter(
                  child: SegmentedButton<CatalogMode>(
                    segments: const [
                      ButtonSegment(
                        value: CatalogMode.organizations,
                        icon: Icon(Icons.storefront_outlined),
                        label: Text(AppStrings.catalogOrganizations),
                      ),
                      ButtonSegment(
                        value: CatalogMode.services,
                        icon: Icon(Icons.list_alt),
                        label: Text(AppStrings.catalogServices),
                      ),
                    ],
                    selected: {_mode},
                    onSelectionChanged: (value) =>
                        setState(() => _mode = value.single),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: CategoryFilterBar(
                  selected: _category,
                  horizontalPadding: gutter,
                  onSelected: (category) =>
                      setState(() => _category = category),
                ),
              ),
              ..._buildResults(context, gutter),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildResults(BuildContext context, double gutter) {
    final controller = widget.controller;
    final data = controller.data;
    if (data == null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: controller.error != null
              ? EmptyState(
                  icon: Icons.cloud_off,
                  title: AppStrings.bookingsLoadErrorTitle,
                  message: AppStrings.bookingsLoadErrorMessage,
                  actionLabel: AppStrings.bookingRetry,
                  onAction: controller.load,
                )
              : const Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    final query = _searchController.text;
    final organizations = filterOrganizations(
      data.organizations,
      services: data.services,
      query: query,
      category: _category,
    );
    final services = filterServices(
      data.services,
      query: query,
      category: _category,
    );
    final count = _mode == CatalogMode.organizations
        ? organizations.length
        : services.length;

    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(
          gutter,
          AppSpacing.m,
          gutter,
          AppSpacing.s,
        ),
        sliver: SliverToBoxAdapter(
          child: Text(
            AppStrings.catalogFoundCount(count),
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
      ),
      if (count == 0)
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: Icons.search_off,
            title: AppStrings.catalogEmptyTitle,
            message: AppStrings.catalogEmptyMessage,
            actionLabel: AppStrings.catalogResetFilters,
            onAction: _resetFilters,
          ),
        )
      else
        SliverPadding(
          padding: EdgeInsets.fromLTRB(gutter, 0, gutter, AppSpacing.xl),
          sliver: _mode == CatalogMode.organizations
              ? SliverList.separated(
                  itemCount: organizations.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.m),
                  itemBuilder: (context, index) {
                    final organization = organizations[index];
                    return OrganizationCard(
                      key: ValueKey(organization.id),
                      organization: organization,
                      rating: data.ratingOf(organization.id),
                      cover: data.covers[organization.id],
                      isFavorite: data.isFavorite(organization.id),
                      onTap: () => widget.onOrganizationSelected(organization),
                      onToggleFavorite: () => _toggleFavorite(organization),
                    );
                  },
                )
              : SliverList.separated(
                  itemCount: services.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.m),
                  itemBuilder: (context, index) => ServiceCard(
                    service: services[index],
                    organizationName: data
                        .organizationOf(services[index].organizationId)
                        ?.name,
                    onTap: () => widget.onServiceSelected(services[index]),
                  ),
                ),
        ),
    ];
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: AppStrings.catalogSearchOrganizationsHint,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                tooltip: AppStrings.catalogClearSearch,
                icon: const Icon(Icons.close),
                onPressed: () => setState(_searchController.clear),
              ),
      ),
    );
  }
}

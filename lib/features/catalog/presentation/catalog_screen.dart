import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/app_strings.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/responsive.dart';
import '../domain/service.dart';
import '../domain/service_filter.dart';
import 'widgets/category_filter_bar.dart';
import 'widgets/service_card.dart';

/// "Услуги" tab: search, category filter and the list of services.
///
/// Query and category are local UI state of this screen; the service list
/// itself is passed in, so the screen does not know where data comes from.
class CatalogScreen extends StatefulWidget {
  const CatalogScreen({
    super.key,
    required this.services,
    required this.onServiceSelected,
    this.initialCategory,
  });

  final List<Service> services;
  final ValueChanged<Service> onServiceSelected;
  final ServiceCategory? initialCategory;

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _searchController = TextEditingController();
  late ServiceCategory? _category = widget.initialCategory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() => _category = null);
  }

  @override
  Widget build(BuildContext context) {
    final results = filterServices(
      widget.services,
      query: _searchController.text,
      category: _category,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final gutter = responsiveGutter(constraints.maxWidth);
        return CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            const SliverAppBar(
              pinned: true,
              title: Text(AppStrings.catalogTitle),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(gutter, 0, gutter, AppSpacing.m),
              sliver: SliverToBoxAdapter(child: _buildSearchField()),
            ),
            SliverToBoxAdapter(
              child: CategoryFilterBar(
                selected: _category,
                horizontalPadding: gutter,
                onSelected: (category) => setState(() => _category = category),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                gutter,
                AppSpacing.m,
                gutter,
                AppSpacing.s,
              ),
              sliver: SliverToBoxAdapter(
                child: Text(
                  AppStrings.catalogFoundCount(results.length),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ),
            if (results.isEmpty)
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
                sliver: SliverList.separated(
                  itemCount: results.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.m),
                  itemBuilder: (context, index) => ServiceCard(
                    service: results[index],
                    onTap: () => widget.onServiceSelected(results[index]),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: AppStrings.catalogSearchHint,
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

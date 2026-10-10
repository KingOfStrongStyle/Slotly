import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/app_strings.dart';
import '../../domain/service.dart';
import '../service_category_style.dart';

class CategoryFilterBar extends StatelessWidget {
  const CategoryFilterBar({
    super.key,
    required this.selected,
    required this.onSelected,
    this.horizontalPadding = AppSpacing.l,
  });

  final ServiceCategory? selected;
  final ValueChanged<ServiceCategory?> onSelected;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final options = <ServiceCategory?>[null, ...ServiceCategory.values];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Row(
        children: [
          for (final category in options)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.s),
              child: FilterChip(
                label: Text(category?.label ?? AppStrings.categoryAll),
                avatar: category == null ? null : Icon(category.icon),
                selected: selected == category,
                showCheckmark: false,
                onSelected: (_) => onSelected(category),
              ),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/app_strings.dart';
import '../../core/widgets/responsive.dart';
import '../../core/widgets/slotly_logo.dart';
import '../catalog/domain/service.dart';
import '../catalog/presentation/service_category_style.dart';

/// First screen of the app. The selected category is local state
/// (StatefulWidget + setState) and is handed over to the catalog.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, required this.onShowServices});

  final ValueChanged<ServiceCategory?> onShowServices;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  ServiceCategory? _selectedCategory;

  void _toggleCategory(ServiceCategory category) {
    setState(() {
      _selectedCategory = _selectedCategory == category ? null : category;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = _selectedCategory;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: ResponsiveCenter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xl),
                const SlotlyLogo(size: 80),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  AppStrings.appName,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.s),
                Text(
                  AppStrings.appTagline,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.m),
                Text(
                  AppStrings.welcomeDescription,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  AppStrings.welcomeChooseCategory,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.m),
                Wrap(
                  spacing: AppSpacing.s,
                  runSpacing: AppSpacing.s,
                  children: [
                    for (final category in ServiceCategory.values)
                      ChoiceChip(
                        label: Text(category.label),
                        avatar: Icon(category.icon),
                        selected: category == selected,
                        showCheckmark: false,
                        onSelected: (_) => _toggleCategory(category),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.m),
                Text(
                  selected == null
                      ? AppStrings.welcomeNoCategory
                      : AppStrings.welcomeSelectedCategory(selected.label),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => widget.onShowServices(selected),
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text(AppStrings.welcomeShowServices),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

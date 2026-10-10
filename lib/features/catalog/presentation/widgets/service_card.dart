import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/app_strings.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/service.dart';
import '../service_category_style.dart';
import 'service_artwork.dart';

/// Catalog list item. Reused by the catalog and by the design golden tests.
class ServiceCard extends StatelessWidget {
  const ServiceCard({
    super.key,
    required this.service,
    this.onTap,
    this.organizationName,
  });

  final Service service;
  final VoidCallback? onTap;

  /// Shown in the global service search, where services of different
  /// businesses are mixed.
  final String? organizationName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final meta =
        '${organizationName ?? service.category.label} · '
        '${Formatters.duration(service.duration)}';
    final price = service.hasPriceOptions
        ? AppStrings.priceFrom(Formatters.price(service.minPriceKzt))
        : Formatters.price(service.priceKzt);

    return Semantics(
      button: onTap != null,
      label: '${service.title}, $meta, $price',
      onTap: onTap,
      excludeSemantics: true,
      child: Card(
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.m),
            child: Row(
              children: [
                SizedBox.square(
                  dimension: 72,
                  child: ServiceArtwork(service: service),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(service.title, style: textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        meta,
                        style: textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s),
                      Text(
                        price,
                        style: textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

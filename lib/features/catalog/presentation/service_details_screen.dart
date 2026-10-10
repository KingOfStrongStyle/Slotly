import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/info_row.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/section_title.dart';
import '../domain/service.dart';
import 'service_category_style.dart';
import 'widgets/service_artwork.dart';

class ServiceDetailsScreen extends StatelessWidget {
  const ServiceDetailsScreen({
    super.key,
    required this.service,
    required this.onBook,
  });

  final Service service;

  final VoidCallback? onBook;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 200,
            flexibleSpace: FlexibleSpaceBar(
              background: ServiceArtwork(
                service: service,
                iconSize: 72,
                borderRadius: 0,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: ResponsiveCenter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.l),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(service.title, style: theme.textTheme.headlineSmall),
                    const SizedBox(height: AppSpacing.m),
                    InfoRow(
                      icon: service.category.icon,
                      label: AppStrings.detailsCategory,
                      value: service.category.label,
                    ),
                    InfoRow(
                      icon: Icons.payments_outlined,
                      label: AppStrings.detailsPrice,
                      value: service.hasPriceOptions
                          ? [
                              for (final option in service.priceOptions)
                                '${option.label} — '
                                    '${Formatters.price(option.priceKzt)}',
                            ].join('\n')
                          : Formatters.price(service.priceKzt),
                    ),
                    InfoRow(
                      icon: Icons.schedule,
                      label: AppStrings.detailsDuration,
                      value: Formatters.duration(service.duration),
                    ),
                    const SectionTitle(
                      AppStrings.detailsAbout,
                      padding: EdgeInsets.only(
                        top: AppSpacing.xl,
                        bottom: AppSpacing.s,
                      ),
                    ),
                    Text(service.description, style: theme.textTheme.bodyLarge),
                    const SectionTitle(
                      AppStrings.detailsSpecialists,
                      padding: EdgeInsets.only(
                        top: AppSpacing.xl,
                        bottom: AppSpacing.s,
                      ),
                    ),
                    for (final specialist in service.availableSpecialists)
                      _SpecialistTile(specialist: specialist),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: onBook == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.l,
                  AppSpacing.s,
                  AppSpacing.l,
                  AppSpacing.l,
                ),
                child: FilledButton.icon(
                  onPressed: onBook,
                  icon: const Icon(Icons.event_available),
                  label: const Text(AppStrings.detailsBook),
                ),
              ),
            ),
    );
  }
}

class _SpecialistTile extends StatelessWidget {
  const _SpecialistTile({required this.specialist});

  final Specialist specialist;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: colors.secondaryContainer,
        foregroundColor: colors.onSecondaryContainer,
        child: Text(Formatters.initials(specialist.name)),
      ),
      title: Text(specialist.name),
      subtitle: Text(specialist.role),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/app_strings.dart';
import '../../../core/state/live_query.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/responsive.dart';
import '../../catalog/domain/service.dart';
import '../data/business_repository.dart';

enum _ServiceAction { edit, toggleHidden }

class OwnerServicesScreen extends StatefulWidget {
  const OwnerServicesScreen({
    super.key,
    required this.organizationId,
    required this.business,
    required this.onEdit,
  });

  final String organizationId;
  final BusinessRepository business;

  final ValueChanged<Service?> onEdit;

  @override
  State<OwnerServicesScreen> createState() => _OwnerServicesScreenState();
}

class _OwnerServicesScreenState extends State<OwnerServicesScreen> {
  late final _query = LiveQuery<List<Service>>(
    () => widget.business.fetchManagedServices(widget.organizationId),
    refreshOn: widget.business.changes,
  )..load();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _openMenu(Service service) async {
    final action = await showModalBottomSheet<_ServiceAction>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                AppStrings.ownerServiceActions,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: Text(service.title),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text(AppStrings.ownerServiceEdit),
              onTap: () => Navigator.of(context).pop(_ServiceAction.edit),
            ),
            ListTile(
              leading: Icon(
                service.isHidden
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              title: Text(
                service.isHidden
                    ? AppStrings.ownerServiceShow
                    : AppStrings.ownerServiceHide,
              ),
              onTap: () =>
                  Navigator.of(context).pop(_ServiceAction.toggleHidden),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    switch (action) {
      case _ServiceAction.edit:
        widget.onEdit(service);
      case _ServiceAction.toggleHidden:
        final messenger = ScaffoldMessenger.of(context);
        await widget.business.setServiceHidden(
          service.id,
          hidden: !service.isHidden,
        );
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                service.isHidden
                    ? AppStrings.ownerServiceShownSnack
                    : AppStrings.ownerServiceHiddenSnack,
              ),
            ),
          );
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final gutter = responsiveGutter(constraints.maxWidth);
        return CustomScrollView(
          slivers: [
            const SliverAppBar(
              pinned: true,
              title: Text(AppStrings.ownerServicesTitle),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(gutter, 0, gutter, AppSpacing.m),
              sliver: SliverToBoxAdapter(
                child: Text(
                  AppStrings.ownerServicesHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            ListenableBuilder(
              listenable: _query,
              builder: (context, _) {
                final services = _query.data;
                if (services == null) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (services.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.list_alt,
                      title: AppStrings.organizationNoServices,
                      message: AppStrings.ownerServiceAdd,
                    ),
                  );
                }
                return SliverPadding(
                  padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 96),
                  sliver: SliverList.separated(
                    itemCount: services.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.s),
                    itemBuilder: (context, index) => _ServiceTile(
                      key: ValueKey(services[index].id),
                      service: services[index],
                      onTap: () => widget.onEdit(services[index]),
                      onMenu: () => _openMenu(services[index]),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    super.key,
    required this.service,
    required this.onTap,
    required this.onMenu,
  });

  final Service service;
  final VoidCallback onTap;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final price = service.hasPriceOptions
        ? AppStrings.priceFrom(Formatters.price(service.minPriceKzt))
        : Formatters.price(service.priceKzt);
    return Card(
      child: InkWell(
        onTap: onTap,
        onLongPress: onMenu,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.l,
            AppSpacing.m,
            AppSpacing.xs,
            AppSpacing.m,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: service.isHidden
                            ? theme.colorScheme.onSurfaceVariant
                            : null,
                      ),
                    ),
                    Text(
                      '${Formatters.duration(service.duration)} · $price'
                      '${service.hasPriceOptions ? ' · ${service.priceOptions.length} вар.' : ''}',
                      style: muted,
                    ),
                    if (service.isHidden)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Row(
                          children: [
                            Icon(
                              Icons.visibility_off_outlined,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(AppStrings.ownerServiceHidden, style: muted),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: AppStrings.ownerServiceActions,
                icon: const Icon(Icons.more_vert),
                onPressed: onMenu,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../core/app_strings.dart';
import '../features/analytics/presentation/owner_dashboard_screen.dart';
import '../features/auth/domain/app_user.dart';
import '../features/auth/presentation/sign_out.dart';
import '../features/business/presentation/business_profile_screen.dart';
import '../features/business/presentation/owner_bookings_screen.dart';
import '../features/business/presentation/owner_reviews_screen.dart';
import '../features/business/presentation/owner_services_screen.dart';
import '../features/catalog/domain/organization.dart';
import '../features/catalog/domain/service.dart';
import '../features/profile/presentation/account_tiles.dart';
import 'app_controller.dart';
import 'app_scope.dart';
import 'routes.dart';

/// Main screen of a business owner: dashboard, bookings, services, reviews
/// and the organization profile — all scoped to [AppUser.organizationId].
///
/// Hiding customer screens here is only the first line of defence: every
/// repository call checks the owner's organization again.
class OwnerShell extends StatefulWidget {
  const OwnerShell({super.key, required this.user});

  final AppUser user;

  @override
  State<OwnerShell> createState() => _OwnerShellState();
}

class _OwnerShellState extends State<OwnerShell> {
  late final AppDependencies _dependencies = AppScope.of(context);
  Organization? _organization;
  bool _subscribed = false;

  String get _organizationId => widget.user.organizationId!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_subscribed) return;
    _subscribed = true;
    _loadOrganization();
    _dependencies.catalog.changes.addListener(_loadOrganization);
  }

  @override
  void dispose() {
    _dependencies.catalog.changes.removeListener(_loadOrganization);
    super.dispose();
  }

  Future<void> _loadOrganization() async {
    final organization = await _dependencies.catalog.fetchOrganization(
      _organizationId,
    );
    if (mounted && organization != _organization) {
      setState(() => _organization = organization);
    }
  }

  Future<void> _editService(Service? service) async {
    final organization = _organization;
    if (organization == null) return;
    final specialists = await _dependencies.catalog.fetchSpecialists(
      organization.id,
    );
    if (!mounted) return;
    await Navigator.of(context).push(
      AppRoutes.serviceEditor(
        organizationId: organization.id,
        category: organization.category,
        specialists: specialists,
        service: service,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _dependencies.appController;
    final navigator = Navigator.of(context);
    final organization = _organization;
    if (organization == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final tabs = <Widget>[
      OwnerDashboardScreen(
        organizationId: organization.id,
        organizationName: organization.name,
        analytics: _dependencies.analytics,
      ),
      OwnerBookingsScreen(
        organizationId: organization.id,
        bookings: _dependencies.bookings,
        clock: _dependencies.clock,
        onOpenCheckIn: () => navigator.push(AppRoutes.ticketCheckIn()),
      ),
      OwnerServicesScreen(
        organizationId: organization.id,
        business: _dependencies.business,
        onEdit: _editService,
      ),
      OwnerReviewsScreen(
        organizationId: organization.id,
        reviews: _dependencies.reviews,
      ),
      BusinessProfileScreen(
        organizationId: organization.id,
        catalog: _dependencies.catalog,
        business: _dependencies.business,
        photoPicker: _dependencies.photoPicker,
        settings: [
          AccountTiles.userHeader(context, widget.user),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.visibility_outlined),
            title: const Text(AppStrings.businessPreview),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                navigator.push(AppRoutes.organization(organization.id)),
          ),
          AccountTiles.darkTheme(controller),
          ...AccountTiles.developerTools(
            onOpenDiagnostics: () => navigator.pushNamed(AppRoutes.diagnostics),
            onOpenGestureLab: () => navigator.pushNamed(AppRoutes.gestureLab),
          ),
          ...AccountTiles.about(context),
          AccountTiles.signOut(
            context,
            () => confirmSignOut(context, _dependencies.session),
          ),
        ],
      ),
    ];

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final current = controller.ownerTab;
        return PopScope(
          canPop: current == OwnerTab.dashboard,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) controller.selectOwnerTab(OwnerTab.dashboard);
          },
          child: Scaffold(
            body: IndexedStack(index: current.index, children: tabs),
            floatingActionButton: current == OwnerTab.services
                ? FloatingActionButton.extended(
                    onPressed: () => _editService(null),
                    icon: const Icon(Icons.add),
                    label: const Text(AppStrings.ownerServiceAdd),
                  )
                : null,
            bottomNavigationBar: NavigationBar(
              selectedIndex: current.index,
              onDestinationSelected: (index) =>
                  controller.selectOwnerTab(OwnerTab.values[index]),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.insights_outlined),
                  selectedIcon: Icon(Icons.insights),
                  label: AppStrings.ownerTabDashboard,
                ),
                NavigationDestination(
                  icon: Icon(Icons.event_note_outlined),
                  selectedIcon: Icon(Icons.event_note),
                  label: AppStrings.ownerTabBookings,
                ),
                NavigationDestination(
                  icon: Icon(Icons.list_alt_outlined),
                  selectedIcon: Icon(Icons.list_alt),
                  label: AppStrings.ownerTabServices,
                ),
                NavigationDestination(
                  icon: Icon(Icons.rate_review_outlined),
                  selectedIcon: Icon(Icons.rate_review),
                  label: AppStrings.ownerTabReviews,
                ),
                NavigationDestination(
                  icon: Icon(Icons.storefront_outlined),
                  selectedIcon: Icon(Icons.storefront),
                  label: AppStrings.ownerTabOrganization,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

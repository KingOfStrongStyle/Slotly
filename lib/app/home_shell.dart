import 'package:flutter/material.dart';

import '../core/app_strings.dart';
import '../features/booking/presentation/bookings_screen.dart';
import '../features/catalog/domain/service.dart';
import '../features/catalog/presentation/catalog_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import 'app_controller.dart';
import 'app_scope.dart';
import 'routes.dart';

/// Main screen with the bottom [NavigationBar].
///
/// Tabs are kept in an [IndexedStack], so the search text and scroll
/// position of each tab survive switching. This is the only [Scaffold] for
/// the three tabs; tab screens provide content and their own app bars.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, this.initialCategory});

  final ServiceCategory? initialCategory;

  @override
  Widget build(BuildContext context) {
    final dependencies = AppScope.of(context);
    final controller = dependencies.appController;

    final tabs = <Widget>[
      CatalogScreen(
        services: dependencies.services,
        initialCategory: initialCategory,
        onServiceSelected: (service) =>
            Navigator.of(context).push(AppRoutes.serviceDetails(service)),
      ),
      BookingsScreen(
        bookings: dependencies.bookings,
        onBrowseServices: () => controller.selectTab(HomeTab.services),
      ),
      ProfileScreen(
        appController: controller,
        onOpenDiagnostics: () =>
            Navigator.of(context).pushNamed(AppRoutes.diagnostics),
        onOpenGestureLab: () =>
            Navigator.of(context).pushNamed(AppRoutes.gestureLab),
      ),
    ];

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final current = controller.currentTab;
        return PopScope(
          // Android convention: Back on a secondary tab returns to the first
          // tab instead of closing the app.
          canPop: current == HomeTab.services,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) controller.selectTab(HomeTab.services);
          },
          child: Scaffold(
            body: IndexedStack(index: current.index, children: tabs),
            bottomNavigationBar: NavigationBar(
              selectedIndex: current.index,
              onDestinationSelected: (index) =>
                  controller.selectTab(HomeTab.values[index]),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.storefront_outlined),
                  selectedIcon: Icon(Icons.storefront),
                  label: AppStrings.tabServices,
                ),
                NavigationDestination(
                  icon: Icon(Icons.event_note_outlined),
                  selectedIcon: Icon(Icons.event_note),
                  label: AppStrings.tabBookings,
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: AppStrings.tabProfile,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

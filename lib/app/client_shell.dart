import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_strings.dart';
import '../core/state/live_query.dart';
import '../features/auth/domain/app_user.dart';
import '../features/auth/presentation/sign_out.dart';
import '../features/booking/domain/booking.dart';
import '../features/booking/presentation/bookings_controller.dart';
import '../features/booking/presentation/bookings_screen.dart';
import '../features/catalog/domain/service.dart';
import '../features/catalog/presentation/catalog_controller.dart';
import '../features/catalog/presentation/catalog_screen.dart';
import '../features/favorites/presentation/favorites_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/reviews/domain/review.dart';
import '../features/reviews/presentation/review_actions.dart';
import 'app_controller.dart';
import 'app_scope.dart';
import 'routes.dart';

class ClientShell extends StatefulWidget {
  const ClientShell({super.key, required this.user, this.initialCategory});

  final AppUser user;
  final ServiceCategory? initialCategory;

  @override
  State<ClientShell> createState() => _ClientShellState();
}

class _ClientShellState extends State<ClientShell> {
  late final AppDependencies _dependencies = AppScope.of(context);
  late final CatalogController _catalog = CatalogController(
    catalog: _dependencies.catalog,
    reviews: _dependencies.reviews,
    favorites: _dependencies.favorites,
  )..load();
  late final BookingsController _bookings = BookingsController(
    _dependencies.bookings,
  )..load();
  late final LiveQuery<List<Review>> _myReviews = LiveQuery(
    _dependencies.reviews.fetchMyReviews,
    refreshOn: _dependencies.reviews.changes,
  )..load();
  StreamSubscription<String>? _reminderTaps;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reminderTaps != null) return;
    _reminderTaps = _dependencies.reminders.service.openedBookingIds.listen(
      _openBookingFromReminder,
    );
    _dependencies.reminders.service.takeLaunchBookingId().then((id) {
      if (id != null) _openBookingFromReminder(id);
    });
  }

  @override
  void dispose() {
    _reminderTaps?.cancel();
    _catalog.dispose();
    _bookings.dispose();
    _myReviews.dispose();
    super.dispose();
  }

  Future<void> _openBookingFromReminder(String bookingId) async {
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    _dependencies.appController.selectClientTab(ClientTab.bookings);
    await _bookings.load();
    if (!mounted) return;
    final booking = _bookings.byId(bookingId);
    if (booking == null) return;
    _showBookingDetails(booking);
  }

  final _bookingsKey = GlobalKey();

  void _showBookingDetails(Booking booking) {
    final context = _bookingsKey.currentContext;
    final screen = _bookingsKey.currentWidget;
    if (context == null || screen is! BookingsScreen) return;
    screen.showDetails(context, booking);
  }

  Future<void> _reschedule(Booking booking) async {
    final services = await _dependencies.catalog.fetchServices(
      organizationId: booking.organizationId,
    );
    final service = services
        .where((s) => s.id == booking.serviceId)
        .firstOrNull;
    if (!mounted) return;
    if (service == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.bookingChangeFailed)),
      );
      return;
    }
    await Navigator.of(context).push(
      AppRoutes.bookingForm(
        service,
        bookings: _bookings,
        rescheduling: booking,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _dependencies.appController;
    final navigator = Navigator.of(context);

    final tabs = <Widget>[
      CatalogScreen(
        controller: _catalog,
        initialCategory: widget.initialCategory,
        onOrganizationSelected: (organization) => navigator.push(
          AppRoutes.organization(organization.id, bookings: _bookings),
        ),
        onServiceSelected: (service) => navigator.push(
          AppRoutes.serviceDetails(service, bookings: _bookings),
        ),
        onFavoriteChanged: (organization, isFavorite) =>
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(
                    isFavorite
                        ? AppStrings.favoriteAdded
                        : AppStrings.favoriteRemoved,
                  ),
                ),
              ),
      ),
      FavoritesScreen(
        controller: _catalog,
        onOrganizationSelected: (organization) => navigator.push(
          AppRoutes.organization(organization.id, bookings: _bookings),
        ),
        onBrowse: () => controller.selectClientTab(ClientTab.catalog),
      ),
      ListenableBuilder(
        listenable: _myReviews,
        builder: (context, _) => BookingsScreen(
          key: _bookingsKey,
          bookings: _bookings,
          clock: _dependencies.clock,
          reviewedBookingIds: {
            for (final review in _myReviews.data ?? const <Review>[])
              review.bookingId,
          },
          onBrowseServices: () => controller.selectClientTab(ClientTab.catalog),
          onReschedule: _reschedule,
          onWriteReview: (booking) =>
              writeReview(context, _dependencies.reviews, booking),
        ),
      ),
      ProfileScreen(
        user: widget.user,
        appController: controller,
        onOpenReminders: () => navigator.pushNamed(AppRoutes.reminders),
        onOpenDiagnostics: () => navigator.pushNamed(AppRoutes.diagnostics),
        onOpenGestureLab: () => navigator.pushNamed(AppRoutes.gestureLab),
        onSignOut: () => confirmSignOut(context, _dependencies.session),
      ),
    ];

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final current = controller.clientTab;
        return PopScope(
          canPop: current == ClientTab.catalog,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) controller.selectClientTab(ClientTab.catalog);
          },
          child: Scaffold(
            body: IndexedStack(index: current.index, children: tabs),
            bottomNavigationBar: NavigationBar(
              selectedIndex: current.index,
              onDestinationSelected: (index) =>
                  controller.selectClientTab(ClientTab.values[index]),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.storefront_outlined),
                  selectedIcon: Icon(Icons.storefront),
                  label: AppStrings.tabCatalog,
                ),
                NavigationDestination(
                  icon: Icon(Icons.favorite_border),
                  selectedIcon: Icon(Icons.favorite),
                  label: AppStrings.tabFavorites,
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

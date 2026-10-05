import 'package:flutter/material.dart';

import '../core/app_strings.dart';
import '../core/utils/formatters.dart';
import '../features/booking/domain/booking.dart';
import '../features/booking/presentation/booking_form_screen.dart';
import '../features/catalog/domain/service.dart';
import '../features/catalog/presentation/service_details_screen.dart';
import '../features/diagnostics/presentation/diagnostics_screen.dart';
import 'app_controller.dart';
import 'app_scope.dart';
import 'home_shell.dart';

/// Route configuration of the app.
///
/// Screens without parameters are registered as named routes. Screens that
/// need data get a typed factory method, so the [Service] object is passed
/// straight into the screen constructor instead of an untyped argument.
/// Routes are also the place where screens are connected to each other and
/// to [AppDependencies]; the screens themselves only expose callbacks.
abstract final class AppRoutes {
  static const homeName = '/home';
  static const diagnostics = '/diagnostics';

  static Map<String, WidgetBuilder> get named => {
    diagnostics: (context) =>
        DiagnosticsScreen(logger: AppScope.of(context).lifecycleLogger),
  };

  static Route<void> home({ServiceCategory? initialCategory}) {
    return MaterialPageRoute(
      settings: const RouteSettings(name: homeName),
      builder: (_) => HomeShell(initialCategory: initialCategory),
    );
  }

  static Route<void> serviceDetails(Service service) {
    return MaterialPageRoute(
      settings: RouteSettings(name: '/services/${service.id}'),
      builder: (context) => ServiceDetailsScreen(
        service: service,
        onBook: () => Navigator.of(context).push(bookingForm(service)),
      ),
    );
  }

  static Route<void> bookingForm(Service service) {
    return MaterialPageRoute(
      settings: RouteSettings(name: '/services/${service.id}/booking'),
      builder: (context) {
        final dependencies = AppScope.of(context);
        return BookingFormScreen(
          service: service,
          bookings: dependencies.bookings,
          clock: dependencies.clock,
          onBooked: (booking) => _showBookingResult(context, booking),
        );
      },
    );
  }

  /// After a successful booking the user lands on "Мои записи" and sees a
  /// confirmation in a SnackBar.
  static void _showBookingResult(BuildContext context, Booking booking) {
    final appController = AppScope.of(context).appController;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).popUntil((route) => route.isFirst);
    appController.selectTab(HomeTab.bookings);

    var message = AppStrings.bookingCreated(
      booking.serviceTitle,
      Formatters.dateTime(booking.startAt),
    );
    if (appController.demoNotificationsEnabled) {
      message += AppStrings.bookingReminderSuffix;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

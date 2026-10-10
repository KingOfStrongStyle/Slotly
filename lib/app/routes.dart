import 'package:flutter/material.dart';

import '../core/app_strings.dart';
import '../core/utils/formatters.dart';
import '../features/booking/domain/booking.dart';
import '../features/booking/presentation/booking_form_screen.dart';
import '../features/booking/presentation/bookings_controller.dart';
import '../features/business/presentation/service_editor_screen.dart';
import '../features/catalog/domain/organization.dart';
import '../features/catalog/domain/service.dart';
import '../features/catalog/presentation/organization_screen.dart';
import '../features/catalog/presentation/service_details_screen.dart';
import '../features/diagnostics/presentation/diagnostics_screen.dart';
import '../features/gesture_checkin/data/symbol_templates.dart';
import '../features/gesture_checkin/presentation/ticket_check_in_screen.dart';
import '../features/gesture_lab/presentation/gesture_lab_screen.dart';
import '../features/reminders/presentation/reminders_screen.dart';
import '../features/reviews/presentation/reviews_screen.dart';
import 'app_controller.dart';
import 'app_scope.dart';

abstract final class AppRoutes {
  static const signIn = '/sign-in';
  static const diagnostics = '/diagnostics';
  static const gestureLab = '/gesture-lab';
  static const reminders = '/reminders';

  static Map<String, WidgetBuilder> get named => {
    diagnostics: (context) =>
        DiagnosticsScreen(logger: AppScope.of(context).lifecycleLogger),
    gestureLab: (context) =>
        GestureLabScreen(clock: AppScope.of(context).clock),
    reminders: (context) =>
        RemindersScreen(coordinator: AppScope.of(context).reminders),
  };

  static Route<void> organization(
    String organizationId, {
    BookingsController? bookings,
  }) {
    return MaterialPageRoute(
      settings: RouteSettings(name: '/organizations/$organizationId'),
      builder: (context) {
        final dependencies = AppScope.of(context);
        return OrganizationScreen(
          organizationId: organizationId,
          catalog: dependencies.catalog,
          reviews: dependencies.reviews,
          favorites: dependencies.favorites,
          canFavorite: bookings != null,
          onServiceSelected: (service) =>
              Navigator.of(context)
                  .push(serviceDetails(service, bookings: bookings)),
          onOpenReviews: (organization) =>
              Navigator.of(context).push(reviews(organization)),
        );
      },
    );
  }

  static Route<void> reviews(Organization organization) {
    return MaterialPageRoute(
      settings: RouteSettings(
        name: '/organizations/${organization.id}/reviews',
      ),
      builder: (context) {
        final dependencies = AppScope.of(context);
        return ReviewsScreen(
          organizationId: organization.id,
          organizationName: organization.name,
          reviews: dependencies.reviews,
          currentUserId: dependencies.session.currentUser?.id,
        );
      },
    );
  }

  static Route<void> serviceDetails(
    Service service, {
    BookingsController? bookings,
  }) {
    return MaterialPageRoute(
      settings: RouteSettings(name: '/services/${service.id}'),
      builder: (context) => ServiceDetailsScreen(
        service: service,
        onBook: bookings == null
            ? null
            : () =>
                  Navigator.of(context)
                      .push(bookingForm(service, bookings: bookings)),
      ),
    );
  }

  static Route<void> bookingForm(
    Service service, {
    required BookingsController bookings,
    Booking? rescheduling,
  }) {
    return MaterialPageRoute(
      settings: RouteSettings(
        name: rescheduling == null
            ? '/services/${service.id}/booking'
            : '/bookings/${rescheduling.id}/reschedule',
      ),
      builder: (context) => BookingFormScreen(
        service: service,
        bookings: bookings,
        clock: AppScope.of(context).clock,
        rescheduling: rescheduling,
        onBooked: (booking) => rescheduling == null
            ? _showBookingResult(context, booking)
            : _showRescheduleResult(context, booking),
      ),
    );
  }

  static Route<void> ticketCheckIn() {
    return MaterialPageRoute(
      settings: const RouteSettings(name: '/owner/check-in'),
      builder: (context) {
        final dependencies = AppScope.of(context);
        return TicketCheckInScreen(
          classifier: dependencies.gestureClassifier,
          templates: symbolTemplates,
          checkIn: dependencies.bookings.checkIn,
          finishSymbol: finishSymbol,
        );
      },
    );
  }

  static Route<void> serviceEditor({
    required String organizationId,
    required ServiceCategory category,
    required List<Specialist> specialists,
    Service? service,
  }) {
    return MaterialPageRoute(
      settings: RouteSettings(name: '/owner/services/${service?.id ?? 'new'}'),
      builder: (context) => ServiceEditorScreen(
        organizationId: organizationId,
        category: category,
        specialists: specialists,
        business: AppScope.of(context).business,
        service: service,
      ),
    );
  }

  static void _showBookingResult(BuildContext context, Booking booking) {
    final dependencies = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).popUntil((route) => route.isFirst);
    dependencies.appController.selectClientTab(ClientTab.bookings);

    var message = AppStrings.bookingCreated(
      booking.serviceTitle,
      Formatters.dateTime(booking.startAt),
    );
    message += AppStrings.bookingCreatedTicket(booking.ticketNumber);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  static void _showRescheduleResult(BuildContext context, Booking booking) {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.rescheduled(Formatters.dateTime(booking.startAt)),
          ),
        ),
      );
  }
}

import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/app_strings.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/responsive.dart';
import '../domain/booking.dart';
import 'bookings_controller.dart';
import 'widgets/booking_sheets.dart';
import 'widgets/booking_tile.dart';
import 'widgets/cancel_booking_dialog.dart';

/// "Записи" tab with two inner tabs: active and cancelled bookings.
///
/// Product gestures on an active booking: tap opens details, long press
/// opens the action menu, swipe to the left asks to cancel. Nothing is
/// cancelled without an explicit confirmation in a dialog.
class BookingsScreen extends StatelessWidget {
  const BookingsScreen({
    super.key,
    required this.bookings,
    required this.onBrowseServices,
  });

  final BookingsController bookings;
  final VoidCallback onBrowseServices;

  Future<void> _requestCancel(BuildContext context, Booking booking) async {
    final confirmed = await showCancelBookingDialog(context, booking);
    if (!confirmed || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await bookings.cancel(booking.id);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text(AppStrings.bookingCancelled)),
        );
    } on Exception {
      messenger.showSnackBar(
        const SnackBar(content: Text(AppStrings.bookingCancelFailed)),
      );
    }
  }

  void _showDetails(BuildContext context, Booking booking) {
    showBookingDetailsSheet(
      context,
      booking,
      onCancel: booking.isActive
          ? () => _requestCancel(context, booking)
          : null,
    );
  }

  Future<void> _showActions(BuildContext context, Booking booking) async {
    final action = await showBookingActionsSheet(context, booking);
    if (!context.mounted) return;
    switch (action) {
      case BookingAction.details:
        _showDetails(context, booking);
      case BookingAction.cancel:
        await _requestCancel(context, booking);
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: bookings,
      builder: (context, _) {
        final active = bookings.active;
        final cancelled = bookings.cancelled;
        return DefaultTabController(
          length: 2,
          child: NestedScrollView(
            headerSliverBuilder: (context, _) => [
              SliverAppBar(
                pinned: true,
                title: const Text(AppStrings.bookingsTitle),
                bottom: TabBar(
                  tabs: [
                    Tab(text: AppStrings.bookingsActiveTab(active.length)),
                    Tab(
                      text: AppStrings.bookingsCancelledTab(cancelled.length),
                    ),
                  ],
                ),
              ),
            ],
            body: TabBarView(
              children: [
                _buildActive(context, active),
                _buildCancelled(context, cancelled),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActive(BuildContext context, List<Booking> active) {
    if (bookings.isLoading && active.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (bookings.hasLoadError) {
      return Center(
        child: EmptyState(
          icon: Icons.cloud_off,
          title: AppStrings.bookingsLoadErrorTitle,
          message: AppStrings.bookingsLoadErrorMessage,
          actionLabel: AppStrings.bookingRetry,
          onAction: bookings.load,
        ),
      );
    }
    if (active.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: EmptyState(
            icon: Icons.event_available_outlined,
            title: AppStrings.bookingsEmptyTitle,
            message: AppStrings.bookingsEmptyMessage,
            actionLabel: AppStrings.bookingsBrowseServices,
            onAction: onBrowseServices,
          ),
        ),
      );
    }
    return _BookingList(
      header: AppStrings.bookingsGestureHint,
      bookings: active,
      itemBuilder: (booking) => _CancellableBookingTile(
        key: ValueKey(booking.id),
        booking: booking,
        onTap: () => _showDetails(context, booking),
        onLongPress: () => _showActions(context, booking),
        confirmCancel: () => _requestCancel(context, booking),
      ),
    );
  }

  Widget _buildCancelled(BuildContext context, List<Booking> cancelled) {
    if (cancelled.isEmpty) {
      return const Center(
        child: SingleChildScrollView(
          child: EmptyState(
            icon: Icons.event_busy_outlined,
            title: AppStrings.bookingsCancelledEmptyTitle,
            message: AppStrings.bookingsCancelledEmptyMessage,
          ),
        ),
      );
    }
    return _BookingList(
      bookings: cancelled,
      itemBuilder: (booking) => BookingTile(
        key: ValueKey(booking.id),
        booking: booking,
        onTap: () => _showDetails(context, booking),
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  const _BookingList({
    required this.bookings,
    required this.itemBuilder,
    this.header,
  });

  final List<Booking> bookings;
  final Widget Function(Booking booking) itemBuilder;
  final String? header;

  @override
  Widget build(BuildContext context) {
    final header = this.header;
    return LayoutBuilder(
      builder: (context, constraints) {
        final gutter = responsiveGutter(constraints.maxWidth);
        return ListView(
          padding: EdgeInsets.fromLTRB(
            gutter,
            AppSpacing.l,
            gutter,
            AppSpacing.xl,
          ),
          children: [
            if (header != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.m),
                child: Text(
                  header,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            for (final booking in bookings)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.m),
                child: itemBuilder(booking),
              ),
          ],
        );
      },
    );
  }
}

/// Active booking that can be swiped to the left to request cancellation.
class _CancellableBookingTile extends StatelessWidget {
  const _CancellableBookingTile({
    super.key,
    required this.booking,
    required this.onTap,
    required this.onLongPress,
    required this.confirmCancel,
  });

  final Booking booking;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final Future<void> Function() confirmCancel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Dismissible(
      key: ValueKey('dismiss-${booking.id}'),
      direction: DismissDirection.endToStart,
      // Always returns false: Dismissible must not remove the tile by
      // itself. If the user confirms, the controller updates the list and
      // the tile disappears on rebuild; otherwise it slides back.
      confirmDismiss: (_) async {
        await confirmCancel();
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        decoration: BoxDecoration(
          color: colors.errorContainer,
          borderRadius: BorderRadius.circular(AppRadii.l),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.bookingsSwipeToCancel,
              style: TextStyle(
                color: colors.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            Icon(Icons.event_busy, color: colors.onErrorContainer),
          ],
        ),
      ),
      child: BookingTile(
        booking: booking,
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}

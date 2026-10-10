import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/app_strings.dart';
import '../../../core/utils/clock.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/responsive.dart';
import '../domain/booking.dart';
import '../domain/booking_repository.dart';
import 'bookings_controller.dart';
import 'check_in_messages.dart';
import 'widgets/booking_sheets.dart';
import 'widgets/booking_tile.dart';
import 'widgets/cancel_booking_dialog.dart';

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({
    super.key,
    required this.bookings,
    required this.clock,
    required this.reviewedBookingIds,
    required this.onBrowseServices,
    required this.onReschedule,
    required this.onWriteReview,
  });

  final BookingsController bookings;
  final Clock clock;

  final Set<String> reviewedBookingIds;
  final VoidCallback onBrowseServices;
  final ValueChanged<Booking> onReschedule;
  final ValueChanged<Booking> onWriteReview;

  Future<void> _requestCancel(BuildContext context, Booking booking) async {
    final confirmed = await showCancelBookingDialog(context, booking);
    if (!confirmed || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    String message;
    try {
      await bookings.cancel(booking.id);
      message = AppStrings.bookingCancelled;
    } on BookingLockedException {
      message = AppStrings.bookingLocked;
    } on Exception {
      message = AppStrings.bookingCancelFailed;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _requestReschedule(BuildContext context, Booking booking) {
    if (!booking.canBeChangedAt(clock())) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text(AppStrings.bookingLocked)));
      return;
    }
    onReschedule(booking);
  }

  Future<void> _checkIn(BuildContext context, Booking booking) async {
    final messenger = ScaffoldMessenger.of(context);
    String message;
    try {
      final checkedIn = await bookings.checkIn(booking.ticketNumber);
      message = AppStrings.checkInSuccess(checkedIn.ticketNumber);
    } on Exception catch (error) {
      message = checkInErrorMessage(error);
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  bool _canReview(Booking booking) =>
      booking.isCompleted && !reviewedBookingIds.contains(booking.id);

  void showDetails(BuildContext context, Booking booking) {
    final now = clock();
    final availability = booking.checkInAvailabilityAt(now);
    final changeable = booking.canBeChangedAt(now);
    showBookingDetailsSheet(
      context,
      booking,
      checkInAvailability: availability,
      onCheckIn: availability == CheckInAvailability.available
          ? () => _checkIn(context, booking)
          : null,
      onReschedule: changeable ? () => onReschedule(booking) : null,
      onCancel: changeable ? () => _requestCancel(context, booking) : null,
      onWriteReview: _canReview(booking) ? () => onWriteReview(booking) : null,
    );
  }

  Future<void> _showActions(BuildContext context, Booking booking) async {
    final changeable = booking.canBeChangedAt(clock());
    final action = await showBookingActionsSheet(
      context,
      booking,
      canChange: changeable,
      canReview: _canReview(booking),
    );
    if (!context.mounted) return;
    switch (action) {
      case BookingAction.details:
        showDetails(context, booking);
      case BookingAction.reschedule:
        _requestReschedule(context, booking);
      case BookingAction.cancel:
        await _requestCancel(context, booking);
      case BookingAction.review:
        onWriteReview(booking);
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
        final past = bookings.past;
        final cancelled = bookings.cancelled;
        return DefaultTabController(
          length: 3,
          child: NestedScrollView(
            headerSliverBuilder: (context, _) => [
              SliverAppBar(
                pinned: true,
                title: const Text(AppStrings.bookingsTitle),
                bottom: TabBar(
                  labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                  tabs: [
                    Tab(text: AppStrings.bookingsActiveTab(active.length)),
                    Tab(text: AppStrings.bookingsPastTab(past.length)),
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
                _buildPast(context, past),
                _buildCancelled(context, cancelled),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActive(BuildContext context, List<Booking> active) {
    if (bookings.isLoading && bookings.all.isEmpty) {
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
    final now = clock();
    return _BookingList(
      header: AppStrings.bookingsGestureHint,
      bookings: active,
      itemBuilder: (booking) => booking.canBeChangedAt(now)
          ? _SwipeableBookingTile(
              key: ValueKey(booking.id),
              booking: booking,
              onTap: () => showDetails(context, booking),
              onLongPress: () => _showActions(context, booking),
              onSwipeCancel: () => _requestCancel(context, booking),
              onSwipeReschedule: () async =>
                  _requestReschedule(context, booking),
            )
          : BookingTile(
              key: ValueKey(booking.id),
              booking: booking,
              onTap: () => showDetails(context, booking),
              onLongPress: () => _showActions(context, booking),
            ),
    );
  }

  Widget _buildPast(BuildContext context, List<Booking> past) {
    if (past.isEmpty) {
      return const Center(
        child: SingleChildScrollView(
          child: EmptyState(
            icon: Icons.history,
            title: AppStrings.bookingsPastEmptyTitle,
            message: AppStrings.bookingsPastEmptyMessage,
          ),
        ),
      );
    }
    return _BookingList(
      bookings: past,
      itemBuilder: (booking) => BookingTile(
        key: ValueKey(booking.id),
        booking: booking,
        onTap: () => showDetails(context, booking),
        onLongPress: () => _showActions(context, booking),
        trailing: _canReview(booking)
            ? TextButton(
                onPressed: () => onWriteReview(booking),
                child: const Text(AppStrings.reviewWrite),
              )
            : null,
        note: reviewedBookingIds.contains(booking.id)
            ? AppStrings.bookingReviewed
            : null,
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
        onTap: () => showDetails(context, booking),
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
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final gutter = responsiveGutter(constraints.maxWidth);
        return ListView.builder(
          padding: EdgeInsets.fromLTRB(
            gutter,
            AppSpacing.l,
            gutter,
            AppSpacing.xl,
          ),
          itemCount: bookings.length + (header == null ? 0 : 1),
          itemBuilder: (context, index) {
            if (header != null && index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.m),
                child: Text(
                  header,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            }
            final booking = bookings[index - (header == null ? 0 : 1)];
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.m),
              child: itemBuilder(booking),
            );
          },
        );
      },
    );
  }
}

class _SwipeableBookingTile extends StatelessWidget {
  const _SwipeableBookingTile({
    super.key,
    required this.booking,
    required this.onTap,
    required this.onLongPress,
    required this.onSwipeCancel,
    required this.onSwipeReschedule,
  });

  final Booking booking;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final Future<void> Function() onSwipeCancel;
  final Future<void> Function() onSwipeReschedule;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    // Ян: влево - отмена, вправо - перенос. То же есть в меню записи,
    // жест не единственный способ
    return Dismissible(
      key: ValueKey('dismiss-${booking.id}'),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          await onSwipeCancel();
        } else {
          await onSwipeReschedule();
        }
        return false;
      },
      background: _SwipeBackground(
        alignment: Alignment.centerLeft,
        color: colors.secondaryContainer,
        foreground: colors.onSecondaryContainer,
        icon: Icons.update,
        label: AppStrings.bookingsSwipeToReschedule,
      ),
      secondaryBackground: _SwipeBackground(
        alignment: Alignment.centerRight,
        color: colors.errorContainer,
        foreground: colors.onErrorContainer,
        icon: Icons.event_busy,
        label: AppStrings.bookingsSwipeToCancel,
      ),
      child: BookingTile(
        booking: booking,
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.alignment,
    required this.color,
    required this.foreground,
    required this.icon,
    required this.label,
  });

  final Alignment alignment;
  final Color color;
  final Color foreground;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final children = [
      Icon(icon, color: foreground),
      const SizedBox(width: AppSpacing.s),
      Text(
        label,
        style: TextStyle(color: foreground, fontWeight: FontWeight.w600),
      ),
    ];
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadii.l),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: alignment == Alignment.centerRight
            ? children.reversed.toList()
            : children,
      ),
    );
  }
}

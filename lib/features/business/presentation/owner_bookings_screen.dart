import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/app_strings.dart';
import '../../../core/state/live_query.dart';
import '../../../core/utils/clock.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/responsive.dart';
import '../../booking/domain/booking.dart';
import '../../booking/domain/booking_repository.dart';
import '../../booking/presentation/check_in_messages.dart';
import '../../booking/presentation/widgets/booking_sheets.dart';
import '../../booking/presentation/widgets/booking_tile.dart';

enum OwnerBookingsFilter { today, upcoming, past }

/// Bookings of the owner's organization. The owner checks visitors in
/// (handwritten ticket number at the reception or the button in the
/// details) and marks finished visits as completed.
class OwnerBookingsScreen extends StatefulWidget {
  const OwnerBookingsScreen({
    super.key,
    required this.organizationId,
    required this.bookings,
    required this.clock,
    required this.onOpenCheckIn,
  });

  final String organizationId;
  final BookingRepository bookings;
  final Clock clock;
  final VoidCallback onOpenCheckIn;

  @override
  State<OwnerBookingsScreen> createState() => _OwnerBookingsScreenState();
}

class _OwnerBookingsScreenState extends State<OwnerBookingsScreen> {
  late final _query = LiveQuery<List<Booking>>(
    () => widget.bookings.fetchOrganizationBookings(widget.organizationId),
    refreshOn: widget.bookings.changes,
  )..load();
  OwnerBookingsFilter _filter = OwnerBookingsFilter.today;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<Booking> _filtered(List<Booking> all) {
    final now = widget.clock();
    final today = now.dateOnly;
    final result = switch (_filter) {
      OwnerBookingsFilter.today => all.where((b) => b.startAt.isSameDay(today)),
      OwnerBookingsFilter.upcoming => all.where(
        (b) => b.startAt.isAfter(now) && !b.startAt.isSameDay(today),
      ),
      OwnerBookingsFilter.past => all.where((b) => b.startAt.isBefore(today)),
    }.toList();
    return _filter == OwnerBookingsFilter.past
        ? (result..sort((a, b) => Booking.compareByStartAt(b, a)))
        : (result..sort(Booking.compareByStartAt));
  }

  Future<void> _run(Future<Booking> Function() action, String success) async {
    final messenger = ScaffoldMessenger.of(context);
    String message;
    try {
      await action();
      message = success;
    } on BookingLockedException {
      message = AppStrings.bookingLocked;
    } on Exception catch (error) {
      message = checkInErrorMessage(error);
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showDetails(Booking booking) {
    final now = widget.clock();
    final availability = booking.checkInAvailabilityAt(now);
    showBookingDetailsSheet(
      context,
      booking,
      checkInAvailability: availability,
      onCheckIn: availability == CheckInAvailability.available
          ? () => _run(
              () => widget.bookings.checkIn(booking.ticketNumber),
              AppStrings.checkInSuccess(booking.ticketNumber),
            )
          : null,
      onComplete: booking.isActive && !now.isBefore(booking.startAt)
          ? () => _run(
              () => widget.bookings.completeBooking(booking.id),
              AppStrings.ownerBookingCompleted,
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final gutter = responsiveGutter(constraints.maxWidth);
        return CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              title: const Text(AppStrings.ownerBookingsTitle),
              actions: [
                IconButton(
                  tooltip: AppStrings.ownerCheckIn,
                  icon: const Icon(Icons.draw_outlined),
                  onPressed: widget.onOpenCheckIn,
                ),
              ],
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(gutter, 0, gutter, AppSpacing.s),
              sliver: SliverToBoxAdapter(
                child: SegmentedButton<OwnerBookingsFilter>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: OwnerBookingsFilter.today,
                      label: Text(AppStrings.ownerBookingsToday),
                    ),
                    ButtonSegment(
                      value: OwnerBookingsFilter.upcoming,
                      label: Text(AppStrings.ownerBookingsUpcoming),
                    ),
                    ButtonSegment(
                      value: OwnerBookingsFilter.past,
                      label: Text(AppStrings.ownerBookingsPast),
                    ),
                  ],
                  selected: {_filter},
                  onSelectionChanged: (value) =>
                      setState(() => _filter = value.single),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(gutter, 0, gutter, AppSpacing.s),
              sliver: SliverToBoxAdapter(
                child: Text(
                  AppStrings.ownerBookingsHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            ListenableBuilder(
              listenable: _query,
              builder: (context, _) {
                final all = _query.data;
                if (all == null) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final items = _filtered(all);
                if (items.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.event_note_outlined,
                      title: AppStrings.ownerBookingsEmpty,
                      message: AppStrings.ownerBookingsEmptyMessage,
                    ),
                  );
                }
                return SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    gutter,
                    AppSpacing.s,
                    gutter,
                    AppSpacing.xl,
                  ),
                  sliver: SliverList.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.m),
                    itemBuilder: (context, index) {
                      final booking = items[index];
                      return BookingTile(
                        key: ValueKey(booking.id),
                        booking: booking,
                        subtitle: AppStrings.ownerBookingClient(
                          booking.clientName,
                        ),
                        onTap: () => _showDetails(booking),
                        onLongPress: () => _showDetails(booking),
                      );
                    },
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

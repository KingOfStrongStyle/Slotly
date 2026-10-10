import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme.dart';
import '../../../core/app_strings.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/section_title.dart';
import '../../../core/widgets/time_slot_chip.dart';
import '../../catalog/domain/service.dart';
import '../domain/booking.dart';
import '../domain/booking_draft.dart';
import '../domain/booking_repository.dart';
import '../domain/time_slot.dart';
import 'bookings_controller.dart';
import 'widgets/booking_confirmation_dialog.dart';
import 'widgets/date_selector.dart';
import 'widgets/specialist_selector.dart';

class BookingFormScreen extends StatefulWidget {
  const BookingFormScreen({
    super.key,
    required this.service,
    required this.bookings,
    required this.clock,
    required this.onBooked,
    this.rescheduling,
  });

  final Service service;
  final BookingsController bookings;
  final Clock clock;

  final ValueChanged<Booking> onBooked;
  final Booking? rescheduling;

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _commentController = TextEditingController();
  late BookingDraft _draft;
  List<TimeSlot> _slots = const [];
  bool _slotsLoading = false;
  bool _slotsFailed = false;
  bool _isSubmitting = false;

  int _slotsRequestId = 0;

  @override
  void initState() {
    super.initState();
    final specialists = widget.service.availableSpecialists;
    final moving = widget.rescheduling;
    if (moving != null) {
      _draft = BookingDraft(
        service: widget.service,
        day: moving.startAt.dateOnly,
        specialist: specialists
            .where((s) => s.id == moving.specialist.id)
            .firstOrNull,
        priceOption: widget.service.priceOptions
            .where((o) => o.label == moving.priceLabel)
            .firstOrNull,
      );
    } else {
      _draft = BookingDraft(
        service: widget.service,
        day: widget.clock().dateOnly,
        specialist: specialists.length == 1 ? specialists.single : null,
        priceOption: widget.service.priceOptions.length == 1
            ? widget.service.priceOptions.single
            : null,
      );
    }
    _loadSlots();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadSlots() async {
    final specialist = _draft.specialist;
    final day = _draft.day;
    if (specialist == null || day == null) {
      setState(() => _slots = const []);
      return;
    }
    final requestId = ++_slotsRequestId;
    setState(() {
      _slotsLoading = true;
      _slotsFailed = false;
    });
    try {
      final slots = await widget.bookings.fetchTimeSlots(
        service: widget.service,
        specialist: specialist,
        day: day,
        ignoreBookingId: widget.rescheduling?.id,
      );
      if (!mounted || requestId != _slotsRequestId) return;
      setState(() => _slots = slots);
    } on Exception {
      if (!mounted || requestId != _slotsRequestId) return;
      setState(() => _slotsFailed = true);
    } finally {
      if (mounted && requestId == _slotsRequestId) {
        setState(() => _slotsLoading = false);
      }
    }
  }

  void _selectSpecialist(Specialist specialist) {
    setState(() => _draft = _draft.withSpecialist(specialist));
    _loadSlots();
  }

  void _selectDay(DateTime day) {
    setState(() => _draft = _draft.withDay(day));
    _loadSlots();
  }

  Future<void> _submit() async {
    final request = _draft.toRequest();
    final moving = widget.rescheduling;
    final confirmed = moving == null
        ? await showBookingConfirmationDialog(context, request)
        : await _confirmReschedule(moving, request.startAt);
    if (!confirmed || !mounted) return;

    setState(() => _isSubmitting = true);
    try {
      final booking = moving == null
          ? await widget.bookings.book(request)
          : await widget.bookings.reschedule(
              moving,
              startAt: request.startAt,
              specialist: request.specialist,
            );
      if (mounted) widget.onBooked(booking);
    } on SlotUnavailableException {
      if (!mounted) return;
      setState(() => _draft = _draft.withSlot(null));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.bookingSlotNoLongerAvailable)),
      );
      await _loadSlots();
    } on BookingLockedException {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(AppStrings.bookingLocked)));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<bool> _confirmReschedule(Booking booking, DateTime startAt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.update),
        title: const Text(AppStrings.rescheduleConfirmTitle),
        content: Text(
          AppStrings.rescheduleConfirmMessage(
            Formatters.dateTime(booking.startAt),
            Formatters.dateTime(startAt),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.confirmEdit),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(AppStrings.rescheduleSubmit),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.rescheduling == null
              ? AppStrings.bookingTitle
              : AppStrings.rescheduleTitle,
        ),
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        child: ResponsiveCenter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ServiceSummary(
                  service: widget.service,
                  current: widget.rescheduling,
                ),
                if (widget.service.hasPriceOptions &&
                    widget.rescheduling == null) ...[
                  const _FormSectionTitle(AppStrings.bookingPriceSection),
                  Wrap(
                    spacing: AppSpacing.s,
                    runSpacing: AppSpacing.s,
                    children: [
                      for (final option in widget.service.priceOptions)
                        ChoiceChip(
                          label: Text(
                            '${option.label} · '
                            '${Formatters.price(option.priceKzt)}',
                          ),
                          selected: option == _draft.priceOption,
                          onSelected: (_) => setState(
                            () => _draft = _draft.withPriceOption(option),
                          ),
                        ),
                    ],
                  ),
                ],
                const _FormSectionTitle(AppStrings.bookingSpecialistSection),
                SpecialistSelector(
                  specialists: widget.service.availableSpecialists,
                  selected: _draft.specialist,
                  onSelected: _selectSpecialist,
                ),
                const _FormSectionTitle(AppStrings.bookingDateSection),
                DateSelector(
                  today: widget.clock(),
                  selected: _draft.day,
                  onSelected: _selectDay,
                ),
                const _FormSectionTitle(AppStrings.bookingTimeSection),
                _buildSlots(),
                if (widget.rescheduling == null) ...[
                  const _FormSectionTitle(AppStrings.bookingCommentSection),
                  _buildCommentField(),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _SubmitBar(
        draft: _draft,
        isSubmitting: _isSubmitting,
        onSubmit: _submit,
        submitLabel: widget.rescheduling == null
            ? AppStrings.bookingContinue
            : AppStrings.rescheduleSubmit,
      ),
    );
  }

  Widget _buildSlots() {
    if (_draft.specialist == null) {
      return const _SlotsMessage(AppStrings.bookingChooseSpecialistFirst);
    }
    if (_slotsLoading) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.l),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_slotsFailed) {
      return _SlotsMessage(
        AppStrings.bookingSlotsLoadError,
        actionLabel: AppStrings.bookingRetry,
        onAction: _loadSlots,
        isError: true,
      );
    }
    if (!_slots.any((slot) => slot.isAvailable)) {
      return const _SlotsMessage(AppStrings.bookingNoSlots);
    }
    return Wrap(
      spacing: AppSpacing.s,
      runSpacing: AppSpacing.s,
      children: [
        for (final slot in _slots)
          TimeSlotChip(
            label: Formatters.time(slot.startAt),
            isAvailable: slot.isAvailable,
            isSelected: slot == _draft.slot,
            onSelected: () => setState(() => _draft = _draft.withSlot(slot)),
          ),
      ],
    );
  }

  Widget _buildCommentField() {
    return TextFormField(
      controller: _commentController,
      minLines: 2,
      maxLines: 4,
      maxLength: BookingDraft.maxCommentLength,
      maxLengthEnforcement: MaxLengthEnforcement.none,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      textCapitalization: TextCapitalization.sentences,
      decoration: const InputDecoration(
        hintText: AppStrings.bookingCommentHint,
        helperText: AppStrings.bookingCommentOptional,
      ),
      validator: (_) => _draft.issues.contains(BookingDraftIssue.commentTooLong)
          ? AppStrings.bookingCommentTooLong(BookingDraft.maxCommentLength)
          : null,
      onChanged: (value) => setState(() => _draft = _draft.withComment(value)),
    );
  }
}

class _FormSectionTitle extends StatelessWidget {
  const _FormSectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => SectionTitle(
    text,
    padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.s),
  );
}

class _ServiceSummary extends StatelessWidget {
  const _ServiceSummary({required this.service, this.current});

  final Service service;

  final Booking? current;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.l,
          vertical: AppSpacing.s,
        ),
        title: Text(service.title, style: theme.textTheme.titleMedium),
        subtitle: Text(
          current != null
              ? '${AppStrings.rescheduleCurrent}: '
                    '${Formatters.dateTime(current!.startAt)}, '
                    '${current!.specialist.name}'
              : '${Formatters.duration(service.duration)} · '
                    '${service.hasPriceOptions ? AppStrings.priceFrom(Formatters.price(service.minPriceKzt)) : Formatters.price(service.priceKzt)}',
        ),
      ),
    );
  }
}

class _SlotsMessage extends StatelessWidget {
  const _SlotsMessage(
    this.text, {
    this.actionLabel,
    this.onAction,
    this.isError = false,
  });

  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final action = actionLabel;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: isError ? colors.errorContainer : colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadii.m),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: TextStyle(
              color: isError ? colors.onErrorContainer : colors.onSurface,
            ),
          ),
          if (action != null && onAction != null)
            TextButton(onPressed: onAction, child: Text(action)),
        ],
      ),
    );
  }
}

class _SubmitBar extends StatelessWidget {
  const _SubmitBar({
    required this.draft,
    required this.isSubmitting,
    required this.onSubmit,
    required this.submitLabel,
  });

  final BookingDraft draft;
  final bool isSubmitting;
  final VoidCallback onSubmit;
  final String submitLabel;

  String? get _missingHint {
    final missing = [
      for (final issue in draft.issues)
        switch (issue) {
          BookingDraftIssue.priceOptionMissing =>
            AppStrings.bookingMissingPriceOption,
          BookingDraftIssue.specialistMissing =>
            AppStrings.bookingMissingSpecialist,
          BookingDraftIssue.dateMissing => AppStrings.bookingMissingDate,
          BookingDraftIssue.timeMissing ||
          BookingDraftIssue.timeUnavailable => AppStrings.bookingMissingTime,
          BookingDraftIssue.commentTooLong => null,
        },
    ].nonNulls;
    if (missing.isEmpty) return null;
    return '${AppStrings.bookingMissingPrefix}${missing.join(', ')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hint = _missingHint;
    return Material(
      elevation: 3,
      color: theme.colorScheme.surfaceContainer,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.l,
            AppSpacing.m,
            AppSpacing.l,
            AppSpacing.m,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hint != null) ...[
                Text(
                  hint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.s),
              ],
              FilledButton(
                onPressed: draft.isComplete && !isSubmitting ? onSubmit : null,
                child: isSubmitting
                    ? const SizedBox.square(
                        dimension: 24,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      )
                    : Text(submitLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

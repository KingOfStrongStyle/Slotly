import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/app_strings.dart';
import '../../../core/widgets/responsive.dart';
import '../domain/gesture_classifier.dart';
import '../domain/gesture_template.dart';
import '../domain/ticket.dart';
import '../domain/ticket_entry.dart';
import '../domain/ticket_repository.dart';
import 'widgets/gesture_pad.dart';
import 'widgets/template_preview.dart';

/// Lab 3: the customer draws the ticket number digit by digit and finishes
/// with "S". The number is then checked in the [TicketRepository].
///
/// The screen does not scroll as a whole: a vertical scroll view would
/// compete with the pad for vertical finger movements.
class TicketCheckInScreen extends StatefulWidget {
  const TicketCheckInScreen({
    super.key,
    required this.classifier,
    required this.templates,
    required this.tickets,
    required this.finishSymbol,
  });

  final GestureClassifier classifier;
  final List<GestureTemplate> templates;
  final TicketRepository tickets;
  final String finishSymbol;

  @override
  State<TicketCheckInScreen> createState() => _TicketCheckInScreenState();
}

class _TicketCheckInScreenState extends State<TicketCheckInScreen> {
  final _pad = GesturePadController();
  late TicketEntry _entry = TicketEntry(finishSymbol: widget.finishSymbol);
  _Feedback? _feedback;
  bool _padError = false;

  @override
  void dispose() {
    _pad.dispose();
    super.dispose();
  }

  Future<void> _recognize() async {
    final result = widget.classifier.recognize(_pad.toGestureStrokes());
    final (entry, outcome) = _entry.apply(result);

    if (outcome == TicketEntryOutcome.notRecognized) {
      setState(() {
        _padError = true;
        _feedback = _Feedback.error(
          AppStrings.checkInNotRecognized(
            result.label,
            result.confidencePercent,
          ),
        );
      });
      return;
    }

    _pad.clear();
    setState(() {
      _padError = false;
      _entry = entry;
      _feedback = switch (outcome) {
        TicketEntryOutcome.digitAdded => _Feedback.info(
          AppStrings.checkInDigitAdded(
            result.label ?? '',
            result.confidencePercent,
          ),
        ),
        TicketEntryOutcome.numberTooLong => _Feedback.error(
          AppStrings.checkInTooLong(TicketEntry.maxDigits),
        ),
        TicketEntryOutcome.numberEmpty => _Feedback.error(
          AppStrings.checkInNumberEmpty,
        ),
        TicketEntryOutcome.completed => _Feedback.info(
          AppStrings.checkInSearching,
        ),
        TicketEntryOutcome.notRecognized => _feedback,
      };
    });

    if (outcome == TicketEntryOutcome.completed) {
      final ticket = await widget.tickets.findByNumber(entry.number);
      if (!mounted) return;
      setState(() {
        _feedback = ticket == null
            ? _Feedback.error(AppStrings.checkInNotFound(entry.number))
            : _Feedback.ticket(ticket);
      });
    }
  }

  void _clearPad() {
    _pad.clear();
    setState(() => _padError = false);
  }

  void _removeLastDigit() => setState(() {
    _entry = _entry.removeLastDigit();
    _feedback = null;
  });

  void _restart() {
    _pad.clear();
    setState(() {
      _entry = _entry.cleared();
      _feedback = null;
      _padError = false;
    });
  }

  void _showTemplates() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _TemplatesSheet(templates: widget.templates),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = _entry.isCompleted;
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.checkInTitle),
        actions: [
          IconButton(
            tooltip: AppStrings.checkInTemplates,
            icon: const Icon(Icons.help_outline),
            onPressed: _showTemplates,
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveCenter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Column(
              children: [
                Flexible(
                  flex: 0,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _NumberDisplay(
                          number: _entry.number,
                          onBackspace: isCompleted || _entry.number.isEmpty
                              ? null
                              : _removeLastDigit,
                        ),
                        const SizedBox(height: AppSpacing.m),
                        _FeedbackCard(feedback: _feedback),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
                Expanded(
                  child: Center(
                    child: IgnorePointer(
                      ignoring: isCompleted,
                      child: GesturePad(
                        controller: _pad,
                        hasError: _padError,
                        onStrokeEnd: () {
                          if (_padError) setState(() => _padError = false);
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
                ListenableBuilder(
                  listenable: _pad,
                  builder: (context, _) => isCompleted
                      ? SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _restart,
                            icon: const Icon(Icons.restart_alt),
                            label: const Text(AppStrings.checkInReset),
                          ),
                        )
                      : _PadActions(
                          hasStrokes: !_pad.isEmpty,
                          onUndo: _pad.undoStroke,
                          onClear: _clearPad,
                          onRecognize: _recognize,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Feedback {
  const _Feedback._(this.message, {this.isError = false, this.ticket});

  factory _Feedback.info(String message) => _Feedback._(message);

  factory _Feedback.error(String message) =>
      _Feedback._(message, isError: true);

  factory _Feedback.ticket(Ticket ticket) =>
      _Feedback._(AppStrings.checkInFound(ticket.number), ticket: ticket);

  final String message;
  final bool isError;
  final Ticket? ticket;
}

class _NumberDisplay extends StatelessWidget {
  const _NumberDisplay({required this.number, required this.onBackspace});

  final String number;
  final VoidCallback? onBackspace;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.l,
          AppSpacing.s,
          AppSpacing.s,
          AppSpacing.s,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.checkInNumberLabel,
                    style: theme.textTheme.labelMedium,
                  ),
                  Text(
                    number.isEmpty
                        ? AppStrings.checkInNumberPlaceholder
                        : number,
                    key: const ValueKey('ticket-number'),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: AppStrings.checkInBackspace,
              onPressed: onBackspace,
              icon: const Icon(Icons.backspace_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.feedback});

  final _Feedback? feedback;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final feedback = this.feedback;
    if (feedback == null) {
      return Text(
        AppStrings.checkInInstructions,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colors.onSurfaceVariant,
        ),
      );
    }

    final ticket = feedback.ticket;
    final background = feedback.isError
        ? colors.errorContainer
        : ticket != null
        ? colors.primaryContainer
        : colors.secondaryContainer;
    final foreground = feedback.isError
        ? colors.onErrorContainer
        : ticket != null
        ? colors.onPrimaryContainer
        : colors.onSecondaryContainer;

    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadii.m),
        ),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: foreground),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                feedback.isError
                    ? Icons.error_outline
                    : ticket != null
                    ? Icons.confirmation_number_outlined
                    : Icons.check_circle_outline,
                color: foreground,
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feedback.message,
                      style: ticket == null
                          ? null
                          : theme.textTheme.titleMedium?.copyWith(
                              color: foreground,
                            ),
                    ),
                    if (ticket != null) ...[
                      Text('${ticket.customerName} · ${ticket.serviceTitle}'),
                      Text(_statusText(ticket)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusText(Ticket ticket) => switch (ticket.status) {
    TicketStatus.waiting =>
      '${AppStrings.ticketWaiting}. '
          '${AppStrings.checkInPeopleAhead(ticket.peopleAhead)}',
    TicketStatus.called => AppStrings.ticketCalled,
    TicketStatus.completed => AppStrings.ticketCompleted,
  };
}

class _PadActions extends StatelessWidget {
  const _PadActions({
    required this.hasStrokes,
    required this.onUndo,
    required this.onClear,
    required this.onRecognize,
  });

  final bool hasStrokes;
  final VoidCallback onUndo;
  final VoidCallback onClear;
  final VoidCallback onRecognize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.outlined(
          tooltip: AppStrings.checkInUndo,
          onPressed: hasStrokes ? onUndo : null,
          icon: const Icon(Icons.undo),
        ),
        const SizedBox(width: AppSpacing.s),
        IconButton.outlined(
          tooltip: AppStrings.checkInClearPad,
          onPressed: hasStrokes ? onClear : null,
          icon: const Icon(Icons.delete_outline),
        ),
        const SizedBox(width: AppSpacing.m),
        Expanded(
          child: FilledButton.icon(
            onPressed: hasStrokes ? onRecognize : null,
            icon: const Icon(Icons.auto_fix_high),
            label: const Text(AppStrings.checkInRecognize),
          ),
        ),
      ],
    );
  }
}

class _TemplatesSheet extends StatelessWidget {
  const _TemplatesSheet({required this.templates});

  final List<GestureTemplate> templates;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.l,
          0,
          AppSpacing.l,
          AppSpacing.l,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.checkInTemplates,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.s),
            const Text(AppStrings.checkInTemplatesHint),
            const SizedBox(height: AppSpacing.l),
            Wrap(
              spacing: AppSpacing.s,
              runSpacing: AppSpacing.s,
              children: [
                for (final template in templates)
                  Container(
                    width: 64,
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppRadii.m),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 56,
                          child: TemplatePreview(template: template),
                        ),
                        Text(template.label, style: theme.textTheme.labelLarge),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

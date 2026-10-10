import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme.dart';
import '../../../core/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/section_title.dart';
import '../../../data/local/local_context.dart';
import '../../catalog/domain/service.dart';
import '../data/business_repository.dart';
import '../domain/business_rules.dart';

class ServiceEditorScreen extends StatefulWidget {
  const ServiceEditorScreen({
    super.key,
    required this.organizationId,
    required this.category,
    required this.specialists,
    required this.business,
    this.service,
  });

  final String organizationId;
  final ServiceCategory category;

  final List<Specialist> specialists;
  final BusinessRepository business;

  final Service? service;

  @override
  State<ServiceEditorScreen> createState() => _ServiceEditorScreenState();
}

class _OptionRow {
  _OptionRow({this.id = '', String label = '', String price = ''})
    : label = TextEditingController(text: label),
      price = TextEditingController(text: price);

  final String id;
  final TextEditingController label;
  final TextEditingController price;

  void dispose() {
    label.dispose();
    price.dispose();
  }
}

class _ServiceEditorScreenState extends State<ServiceEditorScreen> {
  static final _durations = [
    for (
      var minutes = BusinessRules.minDuration.inMinutes;
      minutes <= 240;
      minutes += BusinessRules.durationStep.inMinutes
    )
      Duration(minutes: minutes),
  ];

  late final _title = TextEditingController(text: widget.service?.title);
  late final _description = TextEditingController(
    text: widget.service?.description,
  );
  late final _price = TextEditingController(
    text: widget.service == null ? '' : '${widget.service!.priceKzt}',
  );
  late Duration _duration =
      widget.service?.duration ?? const Duration(minutes: 60);
  late bool _hidden = widget.service?.isHidden ?? false;
  late final Set<String> _specialistIds = {
    for (final s
        in widget.service?.availableSpecialists ?? const <Specialist>[])
      s.id,
  };
  late final List<_OptionRow> _options = [
    for (final o in widget.service?.priceOptions ?? const <PriceOption>[])
      _OptionRow(id: o.id, label: o.label, price: '${o.priceKzt}'),
  ];
  bool _showErrors = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    for (final option in _options) {
      option.dispose();
    }
    super.dispose();
  }

  Service _draft() => Service(
    id: widget.service?.id ?? '',
    organizationId: widget.organizationId,
    title: _title.text,
    category: widget.category,
    description: _description.text,
    duration: _duration,
    priceKzt: int.tryParse(_price.text.trim()) ?? 0,
    priceOptions: [
      for (final row in _options)
        PriceOption(
          id: row.id,
          label: row.label.text,
          priceKzt: int.tryParse(row.price.text.trim()) ?? 0,
        ),
    ],
    availableSpecialists: [
      for (final s in widget.specialists)
        if (_specialistIds.contains(s.id)) s,
    ],
    artworkVariant: widget.service?.artworkVariant ?? 0,
    isHidden: _hidden,
  );

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final draft = _draft();
    if (BusinessRules.validateService(draft).isNotEmpty) {
      setState(() => _showErrors = true);
      return;
    }
    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await widget.business.saveService(draft);
      messenger.showSnackBar(
        const SnackBar(content: Text(AppStrings.serviceSaved)),
      );
      navigator.pop();
    } on ValidationException {
      setState(() => _showErrors = true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final issues = _showErrors
        ? BusinessRules.validateService(_draft())
        : const <ServiceIssue>[];
    String? error(ServiceIssue issue, String message) =>
        issues.contains(issue) ? message : null;
    final numbersOnly = [FilteringTextInputFormatter.digitsOnly];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.service == null
              ? AppStrings.serviceEditorNew
              : AppStrings.serviceEditorEdit,
        ),
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(AppSpacing.l),
        child: ResponsiveCenter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _title,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: AppStrings.serviceFieldTitle,
                  errorText: error(
                    ServiceIssue.titleLength,
                    AppStrings.serviceTitleLength(
                      BusinessRules.minNameLength,
                      BusinessRules.maxNameLength,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              TextField(
                controller: _description,
                minLines: 2,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: AppStrings.serviceFieldDescription,
                  errorText: error(
                    ServiceIssue.descriptionTooLong,
                    AppStrings.serviceDescriptionTooLong(
                      BusinessRules.maxDescriptionLength,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              DropdownButtonFormField<Duration>(
                initialValue: _durations.contains(_duration) ? _duration : null,
                decoration: const InputDecoration(
                  labelText: AppStrings.serviceFieldDuration,
                ),
                items: [
                  for (final duration in _durations)
                    DropdownMenuItem(
                      value: duration,
                      child: Text(Formatters.duration(duration)),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _duration = value);
                },
              ),
              const SizedBox(height: AppSpacing.m),
              TextField(
                controller: _price,
                keyboardType: TextInputType.number,
                inputFormatters: numbersOnly,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: AppStrings.serviceFieldPrice,
                  helperText: AppStrings.serviceFieldPriceHint,
                  errorText: error(
                    ServiceIssue.priceOutOfRange,
                    AppStrings.servicePriceInvalid,
                  ),
                ),
              ),
              const SectionTitle(
                AppStrings.serviceFieldOptions,
                padding: EdgeInsets.only(
                  top: AppSpacing.xl,
                  bottom: AppSpacing.xs,
                ),
              ),
              Text(
                AppStrings.serviceFieldOptionsHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              for (final (index, row) in _options.indexed)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.m),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          key: ValueKey('option-label-$index'),
                          controller: row.label,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: AppStrings.serviceOptionLabel,
                            errorText: row.label.text.trim().isEmpty
                                ? error(
                                    ServiceIssue.optionLabelEmpty,
                                    AppStrings.serviceOptionLabelEmpty,
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          key: ValueKey('option-price-$index'),
                          controller: row.price,
                          keyboardType: TextInputType.number,
                          inputFormatters: numbersOnly,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            labelText: AppStrings.serviceOptionPrice,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: AppStrings.serviceOptionRemove,
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () =>
                            setState(() => _options.removeAt(index).dispose()),
                      ),
                    ],
                  ),
                ),
              for (final (issue, message) in [
                (
                  ServiceIssue.optionLabelDuplicate,
                  AppStrings.serviceOptionLabelDuplicate,
                ),
                (
                  ServiceIssue.optionPriceOutOfRange,
                  AppStrings.servicePriceInvalid,
                ),
                (
                  ServiceIssue.tooManyOptions,
                  AppStrings.serviceTooManyOptions(
                    BusinessRules.maxPriceOptions,
                  ),
                ),
              ])
                if (issues.contains(issue))
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.s),
                    child: Text(
                      message,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _options.length >= BusinessRules.maxPriceOptions
                      ? null
                      : () => setState(() => _options.add(_OptionRow())),
                  icon: const Icon(Icons.add),
                  label: const Text(AppStrings.serviceOptionAdd),
                ),
              ),
              const SectionTitle(
                AppStrings.serviceFieldSpecialists,
                padding: EdgeInsets.only(
                  top: AppSpacing.l,
                  bottom: AppSpacing.s,
                ),
              ),
              Wrap(
                spacing: AppSpacing.s,
                runSpacing: AppSpacing.s,
                children: [
                  for (final specialist in widget.specialists)
                    FilterChip(
                      label: Text(specialist.name),
                      selected: _specialistIds.contains(specialist.id),
                      onSelected: (selected) => setState(() {
                        if (selected) {
                          _specialistIds.add(specialist.id);
                        } else {
                          _specialistIds.remove(specialist.id);
                        }
                      }),
                    ),
                ],
              ),
              if (issues.contains(ServiceIssue.noSpecialists))
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.s),
                  child: Text(
                    AppStrings.serviceNoSpecialists,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              const SizedBox(height: AppSpacing.m),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(AppStrings.serviceFieldHidden),
                value: _hidden,
                onChanged: (value) => setState(() => _hidden = value),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.l,
            AppSpacing.s,
            AppSpacing.l,
            AppSpacing.l,
          ),
          child: FilledButton(
            onPressed: _isSaving ? null : _save,
            child: const Text(AppStrings.serviceSave),
          ),
        ),
      ),
    );
  }
}

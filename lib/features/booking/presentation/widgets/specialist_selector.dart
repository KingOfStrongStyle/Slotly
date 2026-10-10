import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../catalog/domain/service.dart';

class SpecialistSelector extends StatelessWidget {
  const SpecialistSelector({
    super.key,
    required this.specialists,
    required this.selected,
    required this.onSelected,
  });

  final List<Specialist> specialists;
  final Specialist? selected;
  final ValueChanged<Specialist> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        for (final specialist in specialists)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s),
            child: _SpecialistOption(
              specialist: specialist,
              isSelected: specialist == selected,
              colors: colors,
              onTap: () => onSelected(specialist),
            ),
          ),
      ],
    );
  }
}

class _SpecialistOption extends StatelessWidget {
  const _SpecialistOption({
    required this.specialist,
    required this.isSelected,
    required this.colors,
    required this.onTap,
  });

  final Specialist specialist;
  final bool isSelected;
  final ColorScheme colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: isSelected,
      inMutuallyExclusiveGroup: true,
      child: Card(
        color: isSelected ? colors.primaryContainer : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.l),
          side: BorderSide(
            color: isSelected ? colors.primary : colors.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: ListTile(
          onTap: onTap,
          leading: CircleAvatar(
            backgroundColor: colors.secondaryContainer,
            foregroundColor: colors.onSecondaryContainer,
            child: Text(Formatters.initials(specialist.name)),
          ),
          title: Text(specialist.name),
          subtitle: Text(specialist.role),
          trailing: Icon(
            isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isSelected ? colors.primary : colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

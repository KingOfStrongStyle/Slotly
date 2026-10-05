import 'package:flutter/material.dart';

import '../app_strings.dart';

/// Time slot in the booking form.
///
/// States: available, selected and unavailable. An unavailable slot is
/// disabled, crossed out and announced as busy by screen readers, so it can
/// never be chosen.
class TimeSlotChip extends StatelessWidget {
  const TimeSlotChip({
    super.key,
    required this.label,
    required this.isAvailable,
    required this.isSelected,
    required this.onSelected,
  });

  final String label;
  final bool isAvailable;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: isAvailable ? null : '$label, ${AppStrings.bookingSlotTaken}',
      child: ChoiceChip(
        label: Text(
          label,
          style: isAvailable
              ? null
              : const TextStyle(decoration: TextDecoration.lineThrough),
        ),
        selected: isSelected,
        showCheckmark: false,
        tooltip: isAvailable ? null : AppStrings.bookingSlotTaken,
        onSelected: isAvailable ? (_) => onSelected() : null,
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../inspection_tokens.dart';

class InspectionMultiChoiceList extends StatelessWidget {
  final List<Map<String, dynamic>> options;
  final Set<String> selected;
  final void Function(String) onToggle;

  const InspectionMultiChoiceList({
    super.key,
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: options.map((opt) {
        final label = opt['label'] as String? ?? '';
        final isSelected = selected.contains(label);
        return GestureDetector(
          onTap: () => onToggle(label),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? kInspPrimary.withValues(alpha: 0.08)
                  : kInspFormField,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? kInspPrimary : kInspBorder,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: inspInterStyle(
                      14,
                      FontWeight.w500,
                      isSelected ? kInspPrimary : kInspPrimaryText,
                    ),
                  ),
                ),
                Icon(
                  isSelected
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded,
                  color: isSelected ? kInspPrimary : kInspSecText,
                  size: 20,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

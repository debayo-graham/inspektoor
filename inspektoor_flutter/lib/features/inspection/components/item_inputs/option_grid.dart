import 'package:flutter/material.dart';

import '../../inspection_tokens.dart';

class InspectionOptionGrid extends StatelessWidget {
  final List<Map<String, dynamic>> options;
  final bool submitting;
  final void Function(String label) onTap;
  // '' = nothing selected; non-empty dims all other options.
  final String selected;

  const InspectionOptionGrid({
    super.key,
    required this.options,
    required this.submitting,
    required this.onTap,
    this.selected = '',
  });

  Color _colorFor(String label) {
    final l = label.toLowerCase();
    if (l == 'pass' || l == 'ok' || l == 'yes') return kInspSuccess;
    if (l == 'fail' || l == 'no' || l == 'failed') return kInspError;
    return kInspPrimary;
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = selected.isNotEmpty;
    return Column(
      children: options.map((opt) {
        final label = opt['label'] as String? ?? '';
        final color = _colorFor(label);
        final isSelected = hasSelection && label == selected;
        final alpha = submitting
            ? 0.4
            : (hasSelection && !isSelected ? 0.45 : 1.0);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: color.withValues(alpha: alpha),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: submitting ? null : () => onTap(label),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                alignment: Alignment.center,
                decoration: isSelected
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.7),
                          width: 2.5,
                        ),
                      )
                    : null,
                child: Text(
                  label,
                  style: inspInterStyle(16, FontWeight.w600, Colors.white),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

import 'package:flutter/material.dart';

import '../../inspection_tokens.dart';

// ─── InspectionMultiCheckList ─────────────────────────────────────────────────

class InspectionMultiCheckList extends StatelessWidget {
  final List<Map<String, dynamic>> checks;
  final Map<String, String> values;
  final void Function(String id, String value) onToggle;
  final Future<void> Function() onPassAll;
  final bool submitting;

  const InspectionMultiCheckList({
    super.key,
    required this.checks,
    required this.values,
    required this.onToggle,
    required this.onPassAll,
    required this.submitting,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: submitting ? null : onPassAll,
          icon: const Icon(Icons.check_circle_outline, size: 18),
          label: const Text('Pass All'),
          style: OutlinedButton.styleFrom(
            foregroundColor: kInspSuccess,
            side: const BorderSide(color: kInspSuccess),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...checks.map((check) {
          final id = check['id'] as String? ?? '';
          final label = check['label'] as String? ?? '';
          final current = values[id] ?? '';
          return InspectionSubCheckRow(
            label: label,
            value: current,
            onToggle: (v) => onToggle(id, v),
            disabled: submitting,
          );
        }),
      ],
    );
  }
}

// ─── InspectionSubCheckRow ────────────────────────────────────────────────────

class InspectionSubCheckRow extends StatelessWidget {
  final String label;
  final String value;
  final void Function(String) onToggle;
  final bool disabled;

  const InspectionSubCheckRow({
    super.key,
    required this.label,
    required this.value,
    required this.onToggle,
    required this.disabled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: kInspFormField,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kInspBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: inspInterStyle(14, FontWeight.w500, kInspPrimaryText),
            ),
          ),
          const SizedBox(width: 8),
          InspectionToggleChip(
            label: 'Pass',
            active: value == 'pass',
            activeColor: kInspSuccess,
            disabled: disabled,
            onTap: () => onToggle('pass'),
          ),
          const SizedBox(width: 6),
          InspectionToggleChip(
            label: 'Fail',
            active: value == 'fail',
            activeColor: kInspError,
            disabled: disabled,
            onTap: () => onToggle('fail'),
          ),
        ],
      ),
    );
  }
}

// ─── InspectionToggleChip ─────────────────────────────────────────────────────

class InspectionToggleChip extends StatelessWidget {
  final String label;
  final bool active;
  final Color activeColor;
  final bool disabled;
  final VoidCallback onTap;

  const InspectionToggleChip({
    super.key,
    required this.label,
    required this.active,
    required this.activeColor,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: active ? activeColor : kInspBorder,
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: inspInterStyle(
            12,
            FontWeight.w600,
            active ? Colors.white : kInspSecText,
          ),
        ),
      ),
    );
  }
}

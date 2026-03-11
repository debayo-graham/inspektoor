import 'package:flutter/material.dart';

import '../inspection_tokens.dart';

// ─── InspectionProgressHeader ─────────────────────────────────────────────────

class InspectionProgressHeader extends StatelessWidget {
  final int step;
  final int total;
  final String label;
  final String assetName;
  final List<Map<String, dynamic>> templateItems;
  final Map<String, bool> defectMap;

  /// Sub-check values for all multi-check items (keyed by step index).
  /// Each value is a map of sub-check id → 'pass', 'fail', or '' (unset).
  final Map<int, Map<String, String>> allSubValues;

  /// Cached single-check values (keyed by step index → 'pass' or 'fail').
  final Map<int, String> singleCheckValues;

  /// Navigation direction: true = forward, false = backward.
  final bool forward;

  const InspectionProgressHeader({
    super.key,
    required this.step,
    required this.total,
    required this.label,
    this.assetName = '',
    required this.templateItems,
    required this.defectMap,
    this.allSubValues = const {},
    this.singleCheckValues = const {},
    this.forward = true,
  });

  @override
  Widget build(BuildContext context) {
    // Count total defects: failed sub-checks from multi-check items +
    // single-check cached fails + whole-item defects for remaining items.
    int defects = 0;
    for (final entry in allSubValues.entries) {
      defects += entry.value.values.where((v) => v == 'fail').length;
    }
    for (final entry in singleCheckValues.entries) {
      if (entry.value.toLowerCase() == 'fail') defects++;
    }
    // Add item-level defects for items not already counted above.
    for (var i = 0; i < templateItems.length; i++) {
      if (allSubValues.containsKey(i)) continue;
      if (singleCheckValues.containsKey(i)) continue;
      final key = templateItems[i]['key'] as String? ?? '';
      if (defectMap[key] == true) defects++;
    }

    return Container(
      color: kInspCard,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${step + 1} of $total',
                style: inspInterStyle(12, FontWeight.w500, kInspSecText),
              ),
              if (defects > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: kInspError.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '$defects defect${defects == 1 ? '' : 's'}',
                    style: inspInterStyle(11, FontWeight.w600, kInspError),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          InspectionSegmentBar(
            total: total,
            step: step,
            templateItems: templateItems,
            defectMap: defectMap,
            allSubValues: allSubValues,
            singleCheckValues: singleCheckValues,
            forward: forward,
          ),
        ],
      ),
    );
  }
}

// ─── InspectionSegmentBar ─────────────────────────────────────────────────────
//
// Shared by InspectionProgressHeader (during steps) and InspectionSummaryView
// (on completion). When step == total, no index equals step so no item gets
// the "current" blue highlight — all are coloured by pass/fail result.

class InspectionSegmentBar extends StatefulWidget {
  final int total;
  final int step;
  final List<Map<String, dynamic>> templateItems;
  final Map<String, bool> defectMap;

  /// Sub-check values for all multi-check items (keyed by step index).
  final Map<int, Map<String, String>> allSubValues;

  /// Cached single-check values (keyed by step index → 'pass' or 'fail').
  final Map<int, String> singleCheckValues;

  /// Navigation direction: true = forward, false = backward.
  final bool forward;

  const InspectionSegmentBar({
    super.key,
    required this.total,
    required this.step,
    required this.templateItems,
    required this.defectMap,
    this.allSubValues = const {},
    this.singleCheckValues = const {},
    this.forward = true,
  });

  @override
  State<InspectionSegmentBar> createState() => _InspectionSegmentBarState();
}

class _InspectionSegmentBarState extends State<InspectionSegmentBar> {
  Color _baseColorForIndex(int index) {
    if (index >= widget.templateItems.length) return kInspBorder;
    // Single-check cached value.
    final sc = widget.singleCheckValues[index]?.toLowerCase();
    if (sc != null) {
      if (sc == 'pass') return kInspSuccess;
      if (sc == 'fail') return kInspError;
    }
    final key = widget.templateItems[index]['key'] as String? ?? '';
    if (!widget.defectMap.containsKey(key)) return kInspBorder;
    return widget.defectMap[key]! ? kInspError : kInspSuccess;
  }

  Color _subColor(String value) {
    if (value == 'pass') return kInspSuccess;
    if (value == 'fail') return kInspError;
    return kInspBorder;
  }

  // Builds a segment with left-to-right fill animation.
  Widget _fillSegment(Color color, {BorderRadius? borderRadius}) {
    final isActive = color != kInspBorder;
    final br = borderRadius ?? BorderRadius.circular(100);
    return ClipRRect(
      borderRadius: br,
      child: SizedBox(
        height: 6,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(color: kInspBorder, borderRadius: br),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(end: isActive ? 1.0 : 0.0),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return FractionallySizedBox(
                  widthFactor: value,
                  alignment: Alignment.centerLeft,
                  child: child,
                );
              },
              child: Container(
                decoration: BoxDecoration(color: color, borderRadius: br),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Builds the current multi-check step with sub-check colors under blue overlay.
  Widget _currentMultiCheckSegment(List<String> entries) {
    final br = BorderRadius.circular(100);
    final alignment =
        widget.forward ? Alignment.centerLeft : Alignment.centerRight;
    return ClipRRect(
      borderRadius: br,
      child: SizedBox(
        height: 6,
        child: Stack(
          children: [
            // Base: actual sub-check pass/fail/unset colors.
            Row(
              children: entries.map((v) => Expanded(
                child: Container(color: _subColor(v)),
              )).toList(),
            ),
            // Blue overlay sweeping directionally.
            TweenAnimationBuilder<double>(
              key: ValueKey('multicheck_${widget.step}_${widget.forward}'),
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Align(
                  alignment: alignment,
                  child: FractionallySizedBox(
                    widthFactor: value,
                    child: child,
                  ),
                );
              },
              child: Container(color: kInspPrimary),
            ),
          ],
        ),
      ),
    );
  }

  // Builds the current step segment with a directional blue overlay.
  Widget _currentStepSegment(Color baseColor, {BorderRadius? borderRadius}) {
    final br = borderRadius ?? BorderRadius.circular(100);
    final alignment =
        widget.forward ? Alignment.centerLeft : Alignment.centerRight;
    return ClipRRect(
      borderRadius: br,
      child: SizedBox(
        height: 6,
        child: Stack(
          children: [
            // Base color (the actual state: green/red/grey).
            Container(
              decoration: BoxDecoration(color: baseColor, borderRadius: br),
            ),
            // Blue overlay sweeping in from left or right.
            TweenAnimationBuilder<double>(
              key: ValueKey('step_${widget.step}_${widget.forward}'),
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Align(
                  alignment: alignment,
                  child: FractionallySizedBox(
                    widthFactor: value,
                    child: child,
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(color: kInspPrimary, borderRadius: br),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(widget.total, (i) {
        final margin = EdgeInsets.only(left: i == 0 ? 0 : 3);
        final isCurrent = i == widget.step;

        // Multi-check item with sub-check segments (current or answered).
        final subValues = widget.allSubValues[i];
        if (subValues != null && subValues.isNotEmpty) {
          // Current step → blue overlay on top of sub-check colors.
          if (isCurrent) {
            final entries = subValues.values.toList();
            return Expanded(
              child: Padding(
                padding: margin,
                child: _currentMultiCheckSegment(entries),
              ),
            );
          }
          final entries = subValues.values.toList();
          return Expanded(
            child: Padding(
              padding: margin,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: SizedBox(
                  height: 6,
                  child: Row(
                    children: List.generate(entries.length, (j) {
                      return Expanded(
                        child: _fillSegment(
                          _subColor(entries[j]),
                          borderRadius: BorderRadius.zero,
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          );
        }

        // Current step → directional blue overlay.
        if (isCurrent) {
          return Expanded(
            child: Padding(
              padding: margin,
              child: _currentStepSegment(_baseColorForIndex(i)),
            ),
          );
        }

        // Default: single colour per segment.
        return Expanded(
          child: Padding(
            padding: margin,
            child: _fillSegment(_baseColorForIndex(i)),
          ),
        );
      }),
    );
  }
}

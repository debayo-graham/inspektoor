import 'package:flutter/material.dart';

import '../inspection_tokens.dart';

// ─── InspectionProgressHeader ─────────────────────────────────────────────────

class InspectionProgressHeader extends StatelessWidget {
  final int step;
  final int total;
  final String label;
  final List<Map<String, dynamic>> templateItems;
  final Map<String, bool> defectMap;

  const InspectionProgressHeader({
    super.key,
    required this.step,
    required this.total,
    required this.label,
    required this.templateItems,
    required this.defectMap,
  });

  @override
  Widget build(BuildContext context) {
    final answered = defectMap.length;
    final defects = defectMap.values.where((v) => v).length;

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
                )
              else
                Text(
                  '$answered answered',
                  style: inspInterStyle(12, FontWeight.w500, kInspSecText),
                ),
            ],
          ),
          const SizedBox(height: 8),
          InspectionSegmentBar(
            total: total,
            step: step,
            templateItems: templateItems,
            defectMap: defectMap,
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: inspInterStyle(17, FontWeight.w600, kInspPrimaryText),
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

class InspectionSegmentBar extends StatelessWidget {
  final int total;
  final int step;
  final List<Map<String, dynamic>> templateItems;
  final Map<String, bool> defectMap;

  const InspectionSegmentBar({
    super.key,
    required this.total,
    required this.step,
    required this.templateItems,
    required this.defectMap,
  });

  Color _colorForIndex(int index) {
    if (index >= templateItems.length) return kInspBorder;
    final key = templateItems[index]['key'] as String? ?? '';
    if (!defectMap.containsKey(key)) {
      return index == step
          ? kInspPrimary.withValues(alpha: 0.35)
          : kInspBorder;
    }
    return defectMap[key]! ? kInspError : kInspSuccess;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(left: i == 0 ? 0 : 3),
            height: 6,
            decoration: BoxDecoration(
              color: _colorForIndex(i),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
        );
      }),
    );
  }
}

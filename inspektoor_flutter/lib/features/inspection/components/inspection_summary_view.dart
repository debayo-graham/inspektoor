import 'package:flutter/material.dart';

import '../inspection_tokens.dart';
import 'inspection_progress_header.dart';

// ─── InspectionSummaryView ────────────────────────────────────────────────────

class InspectionSummaryView extends StatelessWidget {
  final List<Map<String, dynamic>> templateItems;
  final List<Map<String, dynamic>> answeredItems;
  final Map<String, bool> defectMap;
  final Future<void> Function() onBack;

  const InspectionSummaryView({
    super.key,
    required this.templateItems,
    required this.answeredItems,
    required this.defectMap,
    required this.onBack,
  });

  Map<String, dynamic>? _answeredFor(String key) {
    try {
      return answeredItems.firstWhere(
        (a) => a['template_item_key'] == key,
      );
    } catch (_) {
      return null;
    }
  }

  String _formatValues(List<dynamic> values) {
    if (values.isEmpty) return '—';
    return values
        .map((v) => (v as Map?)?['value'] as String? ?? '')
        .where((s) => s.isNotEmpty)
        .join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final total = templateItems.length;
    final defectCount = defectMap.values.where((v) => v).length;
    final passCount = defectMap.values.where((v) => !v).length;

    return ColoredBox(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Container(
            color: kInspCard,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'All $total items completed',
                      style: inspInterStyle(12, FontWeight.w500, kInspSecText),
                    ),
                    if (defectCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: kInspError.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          '$defectCount defect${defectCount == 1 ? '' : 's'}',
                          style: inspInterStyle(11, FontWeight.w600, kInspError),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // step: total → no index equals step, so no "current" highlight.
                // All segments colour by pass/fail result only.
                InspectionSegmentBar(
                  total: total,
                  step: total,
                  templateItems: templateItems,
                  defectMap: defectMap,
                ),
                const SizedBox(height: 12),
                Text(
                  'Inspection Summary',
                  style: inspInterStyle(17, FontWeight.w600, kInspPrimaryText),
                ),
              ],
            ),
          ),

          // ── Stats row ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                InspectionStatChip(
                  label: 'Passed',
                  count: passCount,
                  color: kInspSuccess,
                ),
                const SizedBox(width: 10),
                InspectionStatChip(
                  label: 'Defects',
                  count: defectCount,
                  color: defectCount > 0 ? kInspError : kInspSecText,
                ),
                const SizedBox(width: 10),
                InspectionStatChip(
                  label: 'Total',
                  count: total,
                  color: kInspPrimary,
                ),
              ],
            ),
          ),

          // ── Item list ─────────────────────────────────────────────────────
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: templateItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final tItem = templateItems[i];
                final key = tItem['key'] as String? ?? '';
                final label = tItem['label'] as String? ?? '';
                final answered = _answeredFor(key);
                final hasDefect = defectMap[key] ?? false;
                final values = answered != null
                    ? (answered['values'] as List? ?? [])
                    : <dynamic>[];
                final valueStr = _formatValues(values);

                return Container(
                  decoration: BoxDecoration(
                    color: kInspCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: hasDefect
                          ? kInspError.withValues(alpha: 0.4)
                          : kInspBorder,
                      width: hasDefect ? 1.5 : 1.0,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: answered == null
                                ? kInspBorder
                                : hasDefect
                                    ? kInspError
                                    : kInspSuccess,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: inspInterStyle(
                                  14, FontWeight.w500, kInspPrimaryText),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              valueStr,
                              style: inspInterStyle(
                                13,
                                FontWeight.w400,
                                hasDefect ? kInspError : kInspSecText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (hasDefect)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: kInspError.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Defect',
                              style: inspInterStyle(10, FontWeight.w600, kInspError),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),

          // ── Footer ────────────────────────────────────────────────────────
          Container(
            color: kInspCard,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // TODO(INSP-02): Replace with caSubmitInspection once implemented.
                ElevatedButton(
                  onPressed: null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kInspPrimary,
                    disabledBackgroundColor:
                        kInspPrimary.withValues(alpha: 0.4),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    textStyle: inspInterStyle(14, FontWeight.w600, Colors.white),
                  ),
                  child: const Text('Submit Inspection'),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: kInspPrimary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Submission not yet available — INSP-02',
                    textAlign: TextAlign.center,
                    style: inspInterStyle(11, FontWeight.w400, kInspPrimary),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: onBack,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kInspPrimaryText,
                    side: const BorderSide(color: kInspBorder, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    textStyle:
                        inspInterStyle(14, FontWeight.w600, kInspPrimaryText),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_back_rounded, size: 16),
                      SizedBox(width: 6),
                      Text('Review previous item'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── InspectionStatChip ───────────────────────────────────────────────────────

class InspectionStatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const InspectionStatChip({
    super.key,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: kInspCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kInspBorder),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: inspInterStyle(20, FontWeight.w700, color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: inspInterStyle(11, FontWeight.w500, kInspSecText),
            ),
          ],
        ),
      ),
    );
  }
}

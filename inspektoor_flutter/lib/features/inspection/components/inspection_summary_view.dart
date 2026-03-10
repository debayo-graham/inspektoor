import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '/app_state.dart';
import '../../../../common/components/photo_viewer_screen.dart';
import '../inspection_tokens.dart';

// ─── InspectionSummaryView ────────────────────────────────────────────────────

class InspectionSummaryView extends StatelessWidget {
  final List<Map<String, dynamic>> templateItems;
  final List<Map<String, dynamic>> answeredItems;
  final Map<String, bool> defectMap;
  final Map<int, Map<String, String>> allSubValues;
  final Map<int, String> singleCheckValues;
  final Map<String, Map<String, dynamic>> answerCache;
  final Future<void> Function() onBack;

  const InspectionSummaryView({
    super.key,
    required this.templateItems,
    required this.answeredItems,
    required this.defectMap,
    this.allSubValues = const {},
    this.singleCheckValues = const {},
    this.answerCache = const {},
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

  static bool _isBase64Image(String s) => s.length > 200 && !s.contains(' ');

  /// Extract image bytes from answered values (signature + photo types).
  List<Uint8List> _extractImages(List<dynamic> values) {
    final images = <Uint8List>[];
    for (final v in values) {
      final val = (v as Map?)?['value'];
      if (val is String && _isBase64Image(val)) {
        try { images.add(base64Decode(val)); } catch (_) {}
      } else if (val is List) {
        for (final item in val) {
          if (item is String && _isBase64Image(item)) {
            try { images.add(base64Decode(item)); } catch (_) {}
          }
        }
      }
    }
    return images;
  }

  @override
  Widget build(BuildContext context) {
    final total = templateItems.length;
    final defectCount = defectMap.values.where((v) => v).length;
    final passCount = defectMap.values.where((v) => !v).length;
    final passRate = total > 0 ? (passCount / total * 100).round() : 0;

    return ColoredBox(
      color: const Color(0xFFF8FAFC),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Scrollable body ────────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: [
                // ── Verdict card ─────────────────────────────────────────────
                _VerdictCard(
                  total: total,
                  passCount: passCount,
                  defectCount: defectCount,
                  passRate: passRate,
                ),
                const SizedBox(height: 12),

                // ── Step cards ───────────────────────────────────────────────
                ...List.generate(templateItems.length, (i) {
                  final tItem = templateItems[i];
                  final key = tItem['key'] as String? ?? '';
                  final type = tItem['type'] as String? ?? '';
                  final label = tItem['label'] as String? ?? '';
                  final config = Map<String, dynamic>.from(
                      tItem['config'] as Map? ?? {});
                  final answered = _answeredFor(key);
                  final hasDefect = defectMap[key] ?? false;
                  final values = answered != null
                      ? (answered['values'] as List? ?? [])
                      : <dynamic>[];
                  final cache = answerCache[key] ?? const {};
                  final stepNum = i + 1;

                  final Widget card;
                  switch (type) {
                    case 'numeric':
                      card = _NumericCard(
                        stepNum: stepNum,
                        label: label,
                        values: values,
                        config: config,
                        hasDefect: hasDefect,
                      );
                    case 'alphanumeric':
                      card = _AlphanumericCard(
                        stepNum: stepNum,
                        label: label,
                        values: values,
                        hasOcr: cache['ocrImageBase64'] != null,
                      );
                    case 'comment-box':
                      card = _CommentCard(
                        stepNum: stepNum,
                        label: label,
                        values: values,
                      );
                    case 'multi-check':
                      card = _MultiCheckCard(
                        stepNum: stepNum,
                        label: label,
                        values: values,
                        config: config,
                        cache: cache,
                        hasDefect: hasDefect,
                      );
                    case 'single-check':
                      card = _SingleCheckCard(
                        stepNum: stepNum,
                        label: label,
                        values: values,
                        config: config,
                        hasDefect: hasDefect,
                      );
                    case 'photo':
                      card = _PhotoCard(
                        stepNum: stepNum,
                        label: label,
                        values: values,
                        extractImages: _extractImages,
                      );
                    case 'signature':
                      card = _SignatureCard(
                        stepNum: stepNum,
                        label: label,
                        inspectorName: FFAppState().fullName,
                        values: values,
                        extractImages: _extractImages,
                      );
                    default:
                      card = _GenericCard(
                        stepNum: stepNum,
                        label: label,
                        values: values,
                        hasDefect: hasDefect,
                      );
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: card,
                  );
                }),
              ],
            ),
          ),

          // ── Footer ──────────────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Divider(height: 1, thickness: 1, color: kInspBorder),
                const SizedBox(height: 12),
                // TODO(INSP-02): Replace with caSubmitInspection once implemented.
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: null, // INSP-02
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.send_rounded,
                                color: Colors.white, size: 14),
                            const SizedBox(width: 8),
                            Text('Submit Report',
                                style: inspInterStyle(
                                    14, FontWeight.w700, Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ),
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

// ═════════════════════════════════════════════════════════════════════════════
// VERDICT CARD — stats + pass rate bar
// ═════════════════════════════════════════════════════════════════════════════

class _VerdictCard extends StatelessWidget {
  final int total;
  final int passCount;
  final int defectCount;
  final int passRate;

  const _VerdictCard({
    required this.total,
    required this.passCount,
    required this.defectCount,
    required this.passRate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kInspBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Inspection Summary',
            style: inspInterStyle(18, FontWeight.w700, kInspPrimaryText),
          ),
          const SizedBox(height: 12),
          // Stats row
          Row(
            children: [
              _StatBox(
                count: passCount,
                label: 'Passed',
                bg: const Color(0xFFF0FDF4),
                border: const Color(0xFFBBF7D0),
                color: const Color(0xFF16A34A),
              ),
              const SizedBox(width: 8),
              _StatBox(
                count: defectCount,
                label: 'Failed',
                bg: const Color(0xFFFEF2F2),
                border: const Color(0xFFFECACA),
                color: const Color(0xFFDC2626),
              ),
              const SizedBox(width: 8),
              _StatBox(
                count: total,
                label: 'Checks',
                bg: const Color(0xFFF8FAFC),
                border: kInspBorder,
                color: const Color(0xFF475569),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Pass rate bar
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: SizedBox(
              height: 6,
              child: Stack(
                children: [
                  Container(color: const Color(0xFFF1F5F9)),
                  FractionallySizedBox(
                    widthFactor: total > 0 ? passCount / total : 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$passRate% pass rate',
              style: inspInterStyle(
                  10, FontWeight.w500, const Color(0xFF94A3B8)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final int count;
  final String label;
  final Color bg;
  final Color border;
  final Color color;

  const _StatBox({
    required this.count,
    required this.label,
    required this.bg,
    required this.border,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Column(
          children: [
            Text('$count',
                style: inspInterStyle(20, FontWeight.w700, color)),
            const SizedBox(height: 2),
            Text(label,
                style: inspInterStyle(
                    9, FontWeight.w600, color.withValues(alpha: 0.6))),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// NUMERIC CARD — colored left bar, large value + unit, range badge
// ═════════════════════════════════════════════════════════════════════════════

class _NumericCard extends StatelessWidget {
  final int stepNum;
  final String label;
  final List<dynamic> values;
  final Map<String, dynamic> config;
  final bool hasDefect;

  const _NumericCard({
    required this.stepNum,
    required this.label,
    required this.values,
    required this.config,
    required this.hasDefect,
  });

  @override
  Widget build(BuildContext context) {
    final rawVal = values.isNotEmpty ? values.first : null;
    final raw = (rawVal as Map?)?['value'] as String? ?? '';
    final unit = config['unit'] as String? ?? '';
    final mn = config['min'] as num?;
    final mx = config['max'] as num?;
    final hasRange = mn != null || mx != null;
    final numVal = num.tryParse(raw);
    final inRange = hasRange &&
        numVal != null &&
        (mn == null || numVal >= mn) &&
        (mx == null || numVal <= mx);
    final barColor = hasDefect
        ? const Color(0xFFEF4444) // red when out of range
        : const Color(0xFF0EA5E9); // sky blue

    String rangeStr = '';
    if (mn != null && mx != null) {
      rangeStr = '${mn.toStringAsFixed(mn == mn.roundToDouble() ? 0 : 1)}–${mx.toStringAsFixed(mx == mx.roundToDouble() ? 0 : 1)}';
      if (unit.isNotEmpty) rangeStr += ' $unit';
    } else if (mn != null) {
      rangeStr = '≥ ${mn.toStringAsFixed(mn == mn.roundToDouble() ? 0 : 1)}';
      if (unit.isNotEmpty) rangeStr += ' $unit';
    } else if (mx != null) {
      rangeStr = '≤ ${mx.toStringAsFixed(mx == mx.roundToDouble() ? 0 : 1)}';
      if (unit.isNotEmpty) rangeStr += ' $unit';
    }

    return _CardShell(
      child: Row(
        children: [
          // Colored left bar
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$label${rangeStr.isNotEmpty ? ' · ' : ''}',
                        style: inspInterStyle(
                            11, FontWeight.w500, const Color(0xFF94A3B8)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (rangeStr.isNotEmpty)
                      Text(rangeStr,
                          style: inspInterStyle(11, FontWeight.w500,
                              const Color(0xFF38BDF8))),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(raw.isNotEmpty ? raw : '—',
                        style: inspInterStyle(
                            28, FontWeight.w800,
                            hasDefect ? const Color(0xFFEF4444) : kInspPrimaryText)),
                    if (unit.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Text(unit,
                          style: inspInterStyle(13, FontWeight.w700,
                              const Color(0xFF94A3B8))),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (hasRange)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: inRange
                    ? const Color(0xFFF0FDF4)
                    : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                inRange ? 'In range' : 'Out of range',
                style: inspInterStyle(
                  10,
                  FontWeight.w600,
                  inRange
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFDC2626),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ALPHANUMERIC CARD — blue left bar, large tracking text, scanned badge
// ═════════════════════════════════════════════════════════════════════════════

class _AlphanumericCard extends StatelessWidget {
  final int stepNum;
  final String label;
  final List<dynamic> values;
  final bool hasOcr;

  const _AlphanumericCard({
    required this.stepNum,
    required this.label,
    required this.values,
    required this.hasOcr,
  });

  @override
  Widget build(BuildContext context) {
    final rawVal = values.isNotEmpty ? values.first : null;
    final raw = (rawVal as Map?)?['value'] as String? ?? '';

    return _CardShell(
      child: Row(
        children: [
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF0EA5E9),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: inspInterStyle(
                        11, FontWeight.w500, const Color(0xFF94A3B8))),
                const SizedBox(height: 2),
                Text(
                  raw.isNotEmpty ? raw : '—',
                  style: inspInterStyle(22, FontWeight.w800, kInspPrimaryText)
                      .copyWith(letterSpacing: 2.5),
                ),
              ],
            ),
          ),
          if (hasOcr)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.photo_camera_outlined,
                      size: 10, color: Color(0xFF0EA5E9)),
                  const SizedBox(width: 4),
                  Text('Scanned',
                      style: inspInterStyle(
                          10, FontWeight.w600, const Color(0xFF0EA5E9))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// COMMENT CARD — simple text value
// ═════════════════════════════════════════════════════════════════════════════

class _CommentCard extends StatelessWidget {
  final int stepNum;
  final String label;
  final List<dynamic> values;

  const _CommentCard({
    required this.stepNum,
    required this.label,
    required this.values,
  });

  @override
  Widget build(BuildContext context) {
    final rawVal = values.isNotEmpty ? values.first : null;
    final raw = (rawVal as Map?)?['value'] as String? ?? '';

    return _CardShell(
      child: Row(
        children: [
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF0EA5E9),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: inspInterStyle(
                        11, FontWeight.w500, const Color(0xFF94A3B8))),
                const SizedBox(height: 4),
                Text(
                  raw.isNotEmpty ? raw : '—',
                  style: inspInterStyle(
                      13, FontWeight.w400, const Color(0xFF475569)),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// MULTI-CHECK CARD — expandable, sub-items with pass/fail pills + evidence
// ═════════════════════════════════════════════════════════════════════════════

class _MultiCheckCard extends StatefulWidget {
  final int stepNum;
  final String label;
  final List<dynamic> values;
  final Map<String, dynamic> config;
  final Map<String, dynamic> cache;
  final bool hasDefect;

  const _MultiCheckCard({
    required this.stepNum,
    required this.label,
    required this.values,
    required this.config,
    required this.cache,
    required this.hasDefect,
  });

  @override
  State<_MultiCheckCard> createState() => _MultiCheckCardState();
}

class _MultiCheckCardState extends State<_MultiCheckCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final checks =
        (widget.config['checks'] as List? ?? []).whereType<Map>().toList();

    // Build a map of check id → value from the answered values
    final valueMap = <String, String>{};
    for (final v in widget.values) {
      final m = v as Map?;
      final key = m?['key'] as String? ?? '';
      final val = m?['value'];
      if (val is String && key.isNotEmpty) valueMap[key] = val;
    }

    final failCount = valueMap.values.where((v) => v == 'fail').length;
    final passItemCount = valueMap.values.where((v) => v == 'pass').length;
    final stepOk = failCount == 0;

    // Failure notes / photos from cache
    final failureNotes =
        (widget.cache['failureNotes'] as Map?)?.cast<String, String>() ?? {};
    final failurePhotosRaw =
        (widget.cache['failurePhotos'] as Map?)?.cast<String, dynamic>() ?? {};

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kInspBorder, width: 1.5),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          // Header row (tappable)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: stepOk
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.label,
                            style: inspInterStyle(
                                14, FontWeight.w700, kInspPrimaryText)),
                        const SizedBox(height: 2),
                        Text(
                          '$passItemCount passed${failCount > 0 ? ', $failCount failed' : ''} · ${checks.length} items',
                          style: inspInterStyle(
                              11, FontWeight.w500, const Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: stepOk
                          ? const Color(0xFFF0FDF4)
                          : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      stepOk
                          ? 'All passed'
                          : '$failCount issue${failCount > 1 ? 's' : ''}',
                      style: inspInterStyle(
                        11,
                        FontWeight.w600,
                        stepOk
                            ? const Color(0xFF10B981)
                            : const Color(0xFFDC2626),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        size: 18, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
          ),

          // Expanded sub-items
          if (_open) ...[
            const Divider(height: 1, thickness: 1, color: kInspBorder),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Column(
                children: [
                  for (final check in checks) ...[
                    Builder(builder: (_) {
                      final checkId =
                          check['id']?.toString() ?? '';
                      final checkLabel =
                          check['label'] as String? ?? checkId;
                      final status = valueMap[checkId] ?? '';
                      final isFail = status == 'fail';
                      final note = failureNotes[checkId] ?? '';
                      final photoList =
                          failurePhotosRaw[checkId] as List? ?? [];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Sub-check row
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: status == 'pass'
                                        ? const Color(0xFF10B981)
                                        : status == 'fail'
                                            ? const Color(0xFFEF4444)
                                            : const Color(0xFFCBD5E1),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(checkLabel,
                                      style: inspInterStyle(
                                          13,
                                          FontWeight.w500,
                                          const Color(0xFF475569))),
                                ),
                                _PassFailPill(pass: status == 'pass'),
                              ],
                            ),
                          ),

                          // Evidence block (only for failures with notes/photos)
                          if (isFail && (note.isNotEmpty || photoList.isNotEmpty))
                            _EvidenceBlock(
                              note: note,
                              photoList: photoList,
                            ),

                          const SizedBox(height: 6),
                        ],
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SINGLE-CHECK CARD
// ═════════════════════════════════════════════════════════════════════════════

class _SingleCheckCard extends StatelessWidget {
  final int stepNum;
  final String label;
  final List<dynamic> values;
  final Map<String, dynamic> config;
  final bool hasDefect;

  const _SingleCheckCard({
    required this.stepNum,
    required this.label,
    required this.values,
    required this.config,
    required this.hasDefect,
  });

  @override
  Widget build(BuildContext context) {
    final firstVal = values.isNotEmpty ? values.first : null;
    final val = (firstVal as Map?)?['value'] as String? ?? '';
    final isPassed = val.toLowerCase() == 'pass';
    final subLabel =
        (config['checks'] as List?)?.isNotEmpty == true
            ? (config['checks'] as List).first['label'] as String? ?? ''
            : '';

    return _CardShell(
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: isPassed
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: inspInterStyle(
                        14, FontWeight.w700, kInspPrimaryText)),
                if (subLabel.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(subLabel,
                      style: inspInterStyle(
                          11, FontWeight.w500, const Color(0xFF94A3B8))),
                ],
              ],
            ),
          ),
          _PassFailPill(pass: isPassed),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TAPPABLE PHOTO THUMBNAIL — expand icon overlay + opens viewer
// ═════════════════════════════════════════════════════════════════════════════

class _TappablePhotoThumbnail extends StatelessWidget {
  final Uint8List bytes;
  final double width;
  final double height;
  final double borderRadius;
  final List<Uint8List> allPhotos;
  final int index;

  const _TappablePhotoThumbnail({
    required this.bytes,
    required this.width,
    required this.height,
    this.borderRadius = 12,
    required this.allPhotos,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PhotoViewerScreen(
            photos: allPhotos,
            initialIndex: index,
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.memory(bytes, fit: BoxFit.cover),
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.zoom_out_map,
                      size: 11, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// PHOTO CARD — grid of thumbnails
// ═════════════════════════════════════════════════════════════════════════════

class _PhotoCard extends StatelessWidget {
  final int stepNum;
  final String label;
  final List<dynamic> values;
  final List<Uint8List> Function(List<dynamic>) extractImages;

  const _PhotoCard({
    required this.stepNum,
    required this.label,
    required this.values,
    required this.extractImages,
  });

  @override
  Widget build(BuildContext context) {
    final images = extractImages(values);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kInspBorder, width: 1.5),
      ),
      clipBehavior: Clip.hardEdge,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: LayoutBuilder(builder: (context, constraints) {
          const barW = 4.0;
          const gap = 10.0;
          const tileSpacing = 6.0;
          final contentW = constraints.maxWidth - barW - gap;
          final tileW = (contentW - tileSpacing * 2) / 3;
          final rows = images.isEmpty ? 0 : (images.length + 2) ~/ 3;
          // Header line height (~20) + gap before grid + grid height
          const headerH = 20.0;
          final gridH = rows > 0
              ? rows * tileW + (rows - 1) * tileSpacing + 10 // +10 = SizedBox before grid
              : 0.0;
          final totalH = headerH + gridH;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: barW,
                height: totalH < 40 ? 40 : totalH,
                decoration: BoxDecoration(
                  color: const Color(0xFF0EA5E9),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const SizedBox(width: gap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(label,
                            style: inspInterStyle(
                                14, FontWeight.w700, kInspPrimaryText)),
                        Text(
                          '${images.length} photo${images.length == 1 ? '' : 's'}',
                          style: inspInterStyle(
                              11, FontWeight.w500, const Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                    if (images.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: tileSpacing,
                        runSpacing: tileSpacing,
                        children: images.asMap().entries.map((entry) {
                          return _TappablePhotoThumbnail(
                            bytes: entry.value,
                            width: tileW,
                            height: tileW,
                            allPhotos: images,
                            index: entry.key,
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SIGNATURE CARD — signed-by row + signature image
// ═════════════════════════════════════════════════════════════════════════════

class _SignatureCard extends StatelessWidget {
  final int stepNum;
  final String label;
  final String inspectorName;
  final List<dynamic> values;
  final List<Uint8List> Function(List<dynamic>) extractImages;

  const _SignatureCard({
    required this.stepNum,
    required this.label,
    required this.inspectorName,
    required this.values,
    required this.extractImages,
  });

  @override
  Widget build(BuildContext context) {
    final images = extractImages(values);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kInspBorder, width: 1.5),
      ),
      clipBehavior: Clip.hardEdge,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Green vertical bar (full card height) ──
            Container(
              width: 4,
              margin: const EdgeInsets.only(left: 14, top: 12, bottom: 12),
              constraints: const BoxConstraints(minHeight: 40),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            const SizedBox(width: 12),
            // ── Content column ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Inspected-by header row
                  Padding(
                    padding: const EdgeInsets.only(top: 12, right: 14, bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Inspected by',
                                  style: inspInterStyle(
                                      11, FontWeight.w500, const Color(0xFF94A3B8))),
                              const SizedBox(height: 2),
                              Text(
                                  inspectorName.isNotEmpty
                                      ? inspectorName
                                      : 'Unknown',
                                  style: inspInterStyle(
                                      15, FontWeight.w700, kInspPrimaryText)),
                            ],
                          ),
                        ),
                        Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check_rounded,
                                    color: Colors.white, size: 9),
                              ),
                              const SizedBox(width: 5),
                              Text('Signed',
                                  style: inspInterStyle(
                                      11, FontWeight.w700, const Color(0xFF059669))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Signature image
                  if (images.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 14, bottom: 14),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: kInspBorder),
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // "SIGNATURE" label
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                      color: Color(0xFFF1F5F9), width: 1),
                                ),
                              ),
                              child: Text(
                                'SIGNATURE',
                                style: inspInterStyle(
                                        9, FontWeight.w700, const Color(0xFFCBD5E1))
                                    .copyWith(letterSpacing: 1.2),
                              ),
                            ),
                            // Image (tappable for full-size view)
                            GestureDetector(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => PhotoViewerScreen(
                                    photos: images,
                                    initialIndex: 0,
                                  ),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    Image.memory(
                                      images.first,
                                      height: 64,
                                      width: double.infinity,
                                      fit: BoxFit.contain,
                                    ),
                                    Container(
                                      width: 22,
                                      height: 22,
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.zoom_out_map,
                                          size: 12, color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Baseline
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Container(
                                height: 1,
                                color: kInspBorder,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// GENERIC CARD — fallback for unknown types
// ═════════════════════════════════════════════════════════════════════════════

class _GenericCard extends StatelessWidget {
  final int stepNum;
  final String label;
  final List<dynamic> values;
  final bool hasDefect;

  const _GenericCard({
    required this.stepNum,
    required this.label,
    required this.values,
    required this.hasDefect,
  });

  @override
  Widget build(BuildContext context) {
    final valStr = values
        .map((v) {
          final val = (v as Map?)?['value'];
          if (val is List || val == null) return '';
          final s = val.toString();
          return s.length > 200 ? '' : s;
        })
        .where((s) => s.isNotEmpty)
        .join(', ');

    return _CardShell(
      child: Row(
        children: [
          _StepBadge(
            stepNumber: stepNum,
            bg: hasDefect
                ? const Color(0xFFFEF2F2)
                : const Color(0xFFF0FDF4),
            color: hasDefect
                ? const Color(0xFFEF4444)
                : const Color(0xFF10B981),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: inspInterStyle(
                        14, FontWeight.w700, kInspPrimaryText)),
                if (valStr.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(valStr,
                      style: inspInterStyle(
                          13, FontWeight.w400, const Color(0xFF94A3B8)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ═════════════════════════════════════════════════════════════════════════════

/// Standard white rounded card shell.
class _CardShell extends StatelessWidget {
  final Widget child;
  const _CardShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kInspBorder, width: 1.5),
      ),
      child: child,
    );
  }
}

/// Step number badge.
class _StepBadge extends StatelessWidget {
  final int stepNumber;
  final Color bg;
  final Color color;
  const _StepBadge({required this.stepNumber, required this.bg, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text('$stepNumber',
          style: inspInterStyle(12, FontWeight.w700, color)),
    );
  }
}

/// Pass / Fail pill badge.
class _PassFailPill extends StatelessWidget {
  final bool pass;
  const _PassFailPill({required this.pass});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: pass ? const Color(0xFFDCFCE7) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        pass ? 'Pass' : 'Fail',
        style: inspInterStyle(
          10,
          FontWeight.w800,
          pass ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
        ),
      ),
    );
  }
}

/// Evidence block showing failure note + photos.
class _EvidenceBlock extends StatelessWidget {
  final String note;
  final List<dynamic> photoList;

  const _EvidenceBlock({
    required this.note,
    required this.photoList,
  });

  @override
  Widget build(BuildContext context) {
    // Decode photos from base64
    final photos = <Uint8List>[];
    for (final item in photoList) {
      if (item is String && item.isNotEmpty) {
        try { photos.add(base64Decode(item)); } catch (_) {}
      } else if (item is List) {
        for (final sub in item) {
          if (sub is String && sub.isNotEmpty) {
            try { photos.add(base64Decode(sub)); } catch (_) {}
          }
        }
      }
    }

    return Container(
      margin: const EdgeInsets.only(left: 16, top: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kInspBorder),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (note.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NOTE',
                    style: inspInterStyle(
                            9, FontWeight.w700, const Color(0xFF94A3B8))
                        .copyWith(letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    note,
                    style: inspInterStyle(
                        12.5, FontWeight.w400, const Color(0xFF475569)),
                  ),
                ],
              ),
            ),
          if (photos.isNotEmpty)
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                itemCount: photos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) => _TappablePhotoThumbnail(
                  bytes: photos[i],
                  width: 72,
                  height: 72,
                  borderRadius: 8,
                  allPhotos: photos,
                  index: i,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

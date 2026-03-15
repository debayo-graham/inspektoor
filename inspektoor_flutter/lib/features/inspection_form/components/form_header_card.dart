import 'package:flutter/material.dart';

import '../pages/form_flow_tokens.dart';

// ─── Stat chip (Steps / Est. Time / Version) ─────────────────────────────────
class FormStatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color bg;

  const FormStatChip({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value, style: ffStyle(15, FontWeight.w800, color)),
            const SizedBox(height: 2),
            Text(label, style: ffStyle(13, FontWeight.w600, kFormSlate4)),
          ],
        ),
      ),
    );
  }
}

// ─── Form header card ─────────────────────────────────────────────────────────
/// Displays form name, category, creation time, and stat chips.
/// Used by the unified form flow shell on the Details step.
class FormHeaderCard extends StatelessWidget {
  final String name;
  final String? category;
  final String? createdAt;
  final int stepCount;
  final bool loading;
  final int version;

  const FormHeaderCard({
    super.key,
    required this.name,
    this.category,
    this.createdAt,
    required this.stepCount,
    this.loading = false,
    this.version = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: kFormBorder, width: 1.5),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFE0F2FE), Color(0xFFBAE6FD)],
                    ),
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Icon(categoryIcon(category),
                        color: kFormBlue, size: 26),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style:
                                ffStyle(16, FontWeight.w800, kFormSlate8)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (category != null &&
                                category!.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F9FF),
                                  border: Border.all(
                                      color: const Color(0xFFBAE6FD)),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(category!,
                                    style: ffStyle(
                                        12, FontWeight.w700, kFormBlue)),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(relativeTime(createdAt),
                                style: ffStyle(
                                    12, FontWeight.w400, kFormSlate4)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                FormStatChip(
                  label: 'Steps',
                  value: loading ? '—' : '$stepCount',
                  color: kFormBlue,
                  bg: const Color(0xFFF0F9FF),
                ),
                const SizedBox(width: 10),
                FormStatChip(
                  label: 'Est. Time',
                  value: loading
                      ? '—'
                      : '~${(stepCount * 1.5).ceil()} min',
                  color: kFormGreen,
                  bg: const Color(0xFFF0FDF4),
                ),
                const SizedBox(width: 10),
                FormStatChip(
                  label: 'Version',
                  value: 'v$version',
                  color: kFormAmber,
                  bg: const Color(0xFFFFFBEB),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

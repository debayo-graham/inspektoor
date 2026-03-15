import 'package:flutter/material.dart';

import '../pages/form_flow_tokens.dart';

// ─── Horizontal step progress bar ─────────────────────────────────────────────
/// Gradient step bar shown at the top of the Create Form flow on mobile and
/// tablet portrait. Displays 4 steps with connector lines, a back button,
/// and an optional "selected form" chip.
class FormFlowStepBar extends StatelessWidget {
  /// Index of the current step (0 = Get Started … 3 = Confirm).
  final int currentStepIndex;

  /// Callback for the "Dashboard" back button.
  final VoidCallback onBack;

  /// Selected form row (null until the user picks a form).
  final Map<String, dynamic>? selectedForm;

  /// Number of schema steps in the selected form.
  final int schemaStepCount;

  /// Callback for the X (close) button in the top-right.
  final VoidCallback? onClose;

  /// Category icon helper (re-exported for the form chip).
  final IconData Function(String?)? categoryIconFn;

  const FormFlowStepBar({
    super.key,
    required this.currentStepIndex,
    required this.onBack,
    this.selectedForm,
    this.schemaStepCount = 0,
    this.onClose,
    this.categoryIconFn,
  });

  static const _stepLabels = [
    'Get Started',
    'Select Form',
    'Review Steps',
    'Confirm',
  ];

  @override
  Widget build(BuildContext context) {
    final iconFn = categoryIconFn ?? categoryIcon;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kFormSidebarDk, kFormBlue],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Title row ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    // ── Back button ────────────────────────────────
                    GestureDetector(
                      onTap: onBack,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.chevron_left_rounded,
                                color: Colors.white, size: 22),
                          ),
                          if (currentStepIndex == 0) ...[
                            const SizedBox(width: 8),
                            Text('Dashboard',
                                style: ffStyle(14, FontWeight.w700, Colors.white70)),
                          ],
                        ],
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Create Inspection Form',
                          style: ffStyle(15, FontWeight.w800, Colors.white),
                        ),
                      ),
                    ),
                    // ── X (close) button or balancing spacer ────
                    if (onClose != null)
                      GestureDetector(
                        onTap: onClose,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.close_rounded,
                              color: Colors.white, size: 20),
                        ),
                      )
                    else
                      const SizedBox(width: 36),
                  ],
                ),
              ),

              // ── Horizontal step indicators ──────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: List.generate(_stepLabels.length * 2 - 1, (i) {
                    // Even indices → step circles, odd → connector lines
                    if (i.isEven) {
                      final stepIdx = i ~/ 2;
                      return _StepCircle(
                        index: stepIdx,
                        label: _stepLabels[stepIdx],
                        isDone: currentStepIndex > stepIdx,
                        isActive: currentStepIndex == stepIdx,
                      );
                    } else {
                      // Connector line
                      final leftStepIdx = i ~/ 2;
                      final isDone = currentStepIndex > leftStepIdx;
                      return Expanded(
                        child: Container(
                          height: 2,
                          margin: const EdgeInsets.only(bottom: 18),
                          decoration: BoxDecoration(
                            color: isDone
                                ? kFormGreen
                                : Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      );
                    }
                  }),
                ),
              ),

              // ── Selected form chip ──────────────────────────────────────
              if (selectedForm != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            iconFn(
                                selectedForm!['category'] as String?),
                            color: Colors.white,
                            size: 13,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            selectedForm!['name'] as String? ?? 'Untitled',
                            style:
                                ffStyle(12, FontWeight.w700, Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$schemaStepCount steps',
                          style: ffStyle(10, FontWeight.w400,
                              Colors.white.withValues(alpha: 0.6)),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Step circle + label ──────────────────────────────────────────────────────
class _StepCircle extends StatelessWidget {
  final int index;
  final String label;
  final bool isDone;
  final bool isActive;

  const _StepCircle({
    required this.index,
    required this.label,
    required this.isDone,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isDone
                ? kFormGreen
                : isActive
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check_rounded,
                    color: Colors.white, size: 14)
                : Text(
                    '${index + 1}',
                    style: ffStyle(
                      12,
                      FontWeight.w800,
                      isActive
                          ? kFormBlue
                          : Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: ffStyle(
            10,
            FontWeight.w700,
            isActive
                ? Colors.white
                : isDone
                    ? Colors.white.withValues(alpha: 0.8)
                    : Colors.white.withValues(alpha: 0.4),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

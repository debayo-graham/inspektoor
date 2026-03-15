import 'dart:convert';

import 'package:flutter/material.dart';

import '/features/inspection/components/inspection_item_step.dart';
import '/features/inspection/components/inspection_progress_header.dart';
import '/features/inspection/components/inspection_summary_view.dart';
import '/features/inspection/components/pill_button.dart';
import '/features/inspection/inspection_session.dart';
import '/features/inspection/inspection_tokens.dart';

// ─── Form Preview Screen ─────────────────────────────────────────────────────
//
// Interactive walkthrough of a form template. The user can fill inputs and
// navigate with Prev / Next, including the summary page, but cannot submit.
// All state is local — no FFAppState reads or writes for draft data.

class FormPreviewScreen extends StatefulWidget {
  final List<Map<String, dynamic>> templateItems;
  final String formName;

  const FormPreviewScreen({
    super.key,
    required this.templateItems,
    required this.formName,
  });

  @override
  State<FormPreviewScreen> createState() => _FormPreviewScreenState();
}

class _FormPreviewScreenState extends State<FormPreviewScreen> {
  late final List<Map<String, dynamic>> _items;
  int _stepIndex = 0;
  bool _goingForward = true;

  final Map<String, Map<String, dynamic>> _answerCache = {};
  final List<Map<String, dynamic>> _answeredItems = [];

  late final DateTime _startedAt;

  // Tablet sidebar ↔ InspectionItemStep communication.
  final ValueNotifier<bool> _canNextNotifier = ValueNotifier(false);
  final ValueNotifier<VoidCallback?> _handleNextNotifier = ValueNotifier(null);
  final ValueNotifier<VoidCallback?> _handleSkipNotifier = ValueNotifier(null);

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _items = List<Map<String, dynamic>>.from(widget.templateItems);
    // Append final signature step (same as InspectionSession.parseTemplate).
    _items.add({
      'key': '__final_signature__',
      'type': 'signature',
      'label': 'Inspector Signature',
      'order': 999999,
      'config': {'note': 'Sign to confirm this inspection is complete'},
    });
  }

  @override
  void dispose() {
    _canNextNotifier.dispose();
    _handleNextNotifier.dispose();
    _handleSkipNotifier.dispose();
    super.dispose();
  }

  // ── Callbacks ──────────────────────────────────────────────────────────────

  Future<void> _onStepSubmit(
    Map<String, dynamic> item,
    List<dynamic> values,
  ) async {
    final key = item['key'] as String? ?? '';
    // Replace any existing answer for this step.
    _answeredItems.removeWhere((a) => a['template_item_key'] == key);
    _answeredItems.add({
      'template_item_key': key,
      'type': item['type'] as String? ?? '',
      'label': item['label'] as String? ?? '',
      'order': (item['order'] as num?)?.toInt() ?? 0,
      'values': values,
    });
    setState(() {
      _goingForward = true;
      _stepIndex++;
    });
  }

  Future<void> _onBack() async {
    if (_stepIndex <= 0) return;
    setState(() {
      _goingForward = false;
      _stepIndex--;
      // Remove stale answer for the step we're returning to so
      // re-submission replaces it cleanly.
      final key = _items[_stepIndex]['key'] as String? ?? '';
      _answeredItems.removeWhere((a) => a['template_item_key'] == key);
    });
  }

  /// Jump to a specific step (for tablet sidebar tapping).
  void _goToStep(int target) {
    if (target == _stepIndex) return;
    setState(() {
      _goingForward = target > _stepIndex;
      // When going back, remove stale answer for the target step.
      if (target < _stepIndex) {
        final key = _items[target]['key'] as String? ?? '';
        _answeredItems.removeWhere((a) => a['template_item_key'] == key);
      }
      _stepIndex = target;
    });
  }

  // ── Computed state ─────────────────────────────────────────────────────────

  Map<String, bool> _computeDefectMap() {
    final syntheticDraft = json.encode({'items': _answeredItems});
    return InspectionSession.defectMap(
      syntheticDraft,
      templateItems: _items,
    );
  }

  Map<int, Map<String, String>> _resolveSubValues() {
    final Map<int, Map<String, String>> allSubValues = {};
    for (var i = 0; i < _items.length; i++) {
      final type = _items[i]['type'] as String? ?? '';
      final key = _items[i]['key'] as String? ?? 'step_$i';
      if (type == 'multi-check') {
        final cv = (_answerCache[key]?['checkValues'] as Map?)
            ?.cast<String, String>();
        if (cv != null && cv.isNotEmpty) allSubValues[i] = cv;
      }
    }
    return allSubValues;
  }

  Map<int, String> _resolveSingleCheckValues() {
    final Map<int, String> singleCheckValues = {};
    for (var i = 0; i < _items.length; i++) {
      final type = _items[i]['type'] as String? ?? '';
      final key = _items[i]['key'] as String? ?? 'step_$i';
      if (type == 'single-check') {
        final sc = _answerCache[key]?['singleChoice'] as String? ?? '';
        if (sc.isNotEmpty) singleCheckValues[i] = sc;
      } else if (type == 'numeric') {
        final text = _answerCache[key]?['text'] as String? ?? '';
        final v = num.tryParse(text.trim());
        if (v != null) {
          final cfg = Map<String, dynamic>.from(
              _items[i]['config'] as Map? ?? {});
          final mn = cfg['min'] as num?;
          final mx = cfg['max'] as num?;
          final inRange =
              (mn == null || v >= mn) && (mx == null || v <= mx);
          singleCheckValues[i] = (mn == null && mx == null) || inRange
              ? 'pass'
              : 'fail';
        }
      } else if (type == 'alphanumeric' || type == 'comment-box') {
        final text = _answerCache[key]?['text'] as String? ?? '';
        if (text.trim().isNotEmpty) singleCheckValues[i] = 'pass';
      } else if (type == 'photo') {
        final photos = _answerCache[key]?['photos'] as List?;
        if (photos != null && photos.isNotEmpty) {
          singleCheckValues[i] = 'pass';
        }
      } else if (type == 'signature') {
        final sig = _answerCache[key]?['signatureBase64'] as String? ?? '';
        if (sig.isNotEmpty) singleCheckValues[i] = 'pass';
      } else if (type == 'multiple-choice') {
        final sc = _answerCache[key]?['singleChoice'] as String? ?? '';
        final ms = _answerCache[key]?['multiSelected'] as List? ?? [];
        if (sc.isNotEmpty || ms.isNotEmpty) singleCheckValues[i] = 'pass';
      }
    }
    return singleCheckValues;
  }

  /// Detect which steps were skipped (from answered items with 'skipped' value).
  Set<int> _resolveSkippedSet() {
    final skipped = <int>{};
    for (final a in _answeredItems) {
      final key = a['template_item_key'] as String?;
      if (key == null) continue;
      final vals = a['values'] as List? ?? [];
      if (vals.any((e) => e is Map && e['value'] == 'skipped')) {
        final idx = _items.indexWhere((i) => i['key'] == key);
        if (idx >= 0) skipped.add(idx);
      }
    }
    return skipped;
  }

  // ── Build step child ───────────────────────────────────────────────────────

  Widget _buildStepChild({
    required int step,
    required int total,
    required bool isSummary,
    required Map<String, bool> defectMap,
    required Map<int, Map<String, String>> allSubValues,
    required Map<int, String> singleCheckValues,
    required bool isTablet,
  }) {
    if (isSummary) {
      if (isTablet) {
        _canNextNotifier.value = false;
        _handleNextNotifier.value = null;
      }
      return InspectionSummaryView(
        key: const ValueKey('__preview_summary__'),
        templateItems: _items,
        answeredItems: _answeredItems,
        defectMap: defectMap,
        allSubValues: allSubValues,
        singleCheckValues: singleCheckValues,
        answerCache: _answerCache,
        onBack: _onBack,
        onSubmit: null, // Disabled — this is preview mode.
        startedAt: _startedAt,
        completedAt: DateTime.now(),
      );
    }

    final item = _items[step];
    final currentItemKey = item['key'] as String? ?? 'step_$step';
    return InspectionItemStep(
      key: ValueKey(currentItemKey),
      item: item,
      step: step,
      total: total,
      templateItems: _items,
      defectMap: defectMap,
      onSubmit: (values) => _onStepSubmit(item, values),
      onBack: step > 0 ? _onBack : null,
      initialCache: _answerCache[currentItemKey] ?? const {},
      onCacheChanged: (cache) {
        _answerCache[currentItemKey] = cache;
        if (mounted) setState(() {});
      },
      hideFooter: isTablet,
      isTablet: isTablet,
      canNextNotifier: isTablet ? _canNextNotifier : null,
      handleNextNotifier: isTablet ? _handleNextNotifier : null,
      handleSkipNotifier: isTablet ? _handleSkipNotifier : null,
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final total = _items.length;
    final isSummary = _stepIndex >= total;
    final defectMap = _computeDefectMap();
    final allSubValues = _resolveSubValues();
    final singleCheckValues = _resolveSingleCheckValues();
    final goingForward = _goingForward;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 768;

            final child = _buildStepChild(
              step: _stepIndex,
              total: total,
              isSummary: isSummary,
              defectMap: defectMap,
              allSubValues: allSubValues,
              singleCheckValues: singleCheckValues,
              isTablet: isTablet,
            );
            final childKey = child.key!;

            Widget animatedContent({Color? bg}) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                transitionBuilder: (animChild, animation) {
                  final isIncoming = animChild.key == childKey;
                  final begin = isIncoming
                      ? (goingForward
                          ? const Offset(1.0, 0.0)
                          : const Offset(-1.0, 0.0))
                      : (goingForward
                          ? const Offset(-1.0, 0.0)
                          : const Offset(1.0, 0.0));
                  return ClipRect(
                    child: SlideTransition(
                      position:
                          Tween<Offset>(begin: begin, end: Offset.zero)
                              .animate(CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeInOut)),
                      child: animChild,
                    ),
                  );
                },
                child: child,
              );
            }

            if (isTablet) {
              return Column(
                children: [
                  // ── Preview banner ─────────────────────────────────────
                  _PreviewBanner(
                      onExit: () => Navigator.of(context).pop()),

                  // ── Tablet header ──────────────────────────────────────
                  _PreviewTabletHeader(
                    step: _stepIndex,
                    total: total,
                    isSummary: isSummary,
                    formName: widget.formName,
                    templateItems: _items,
                    defectMap: defectMap,
                    allSubValues: allSubValues,
                    singleCheckValues: singleCheckValues,
                    forward: goingForward,
                  ),

                  // ── Sidebar + Content ──────────────────────────────────
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _PreviewTabletSidebar(
                          items: _items,
                          currentStep: _stepIndex,
                          isSummary: isSummary,
                          allSubValues: allSubValues,
                          singleCheckValues: singleCheckValues,
                          defectMap: defectMap,
                          skippedSet: _resolveSkippedSet(),
                          canNextNotifier: _canNextNotifier,
                          handleNextNotifier: _handleNextNotifier,
                          handleSkipNotifier: _handleSkipNotifier,
                          currentItemIsOptional: !isSummary &&
                              _stepIndex < _items.length &&
                              _items[_stepIndex]['required'] == false,
                          onBack: _stepIndex > 0 ? _onBack : null,
                          onStepTapped: _goToStep,
                        ),
                        Container(width: 1, color: kInspBorder),
                        Expanded(
                          child: ColoredBox(
                            color: const Color(0xFFF8FAFC),
                            child: animatedContent(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            // ── Mobile layout ────────────────────────────────────────────
            return Column(
              children: [
                _PreviewBanner(
                    onExit: () => Navigator.of(context).pop()),
                if (!isSummary)
                  InspectionProgressHeader(
                    step: _stepIndex,
                    total: total,
                    label: _items[_stepIndex]['label'] as String? ?? '',
                    assetName: 'Preview',
                    templateItems: _items,
                    defectMap: defectMap,
                    allSubValues: allSubValues,
                    singleCheckValues: singleCheckValues,
                    forward: goingForward,
                  ),
                Expanded(child: animatedContent()),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─── Preview Banner ──────────────────────────────────────────────────────────

class _PreviewBanner extends StatelessWidget {
  final VoidCallback onExit;
  const _PreviewBanner({required this.onExit});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E293B),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onExit,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.chevron_left_rounded,
                    color: Color(0xFF94A3B8), size: 20),
                const SizedBox(width: 2),
                Text(
                  'Exit Preview',
                  style: inspInterStyle(
                      13, FontWeight.w600, const Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.visibility_outlined,
                    size: 12, color: Color(0xFFA78BFA)),
                const SizedBox(width: 5),
                Text(
                  'Preview Mode',
                  style: inspInterStyle(
                      12, FontWeight.w700, const Color(0xFFA78BFA)),
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
// TABLET HEADER — progress bar + form name (adapted from runner)
// ═════════════════════════════════════════════════════════════════════════════

class _PreviewTabletHeader extends StatelessWidget {
  final int step;
  final int total;
  final bool isSummary;
  final String formName;
  final List<Map<String, dynamic>> templateItems;
  final Map<String, bool> defectMap;
  final Map<int, Map<String, String>> allSubValues;
  final Map<int, String> singleCheckValues;
  final bool forward;

  const _PreviewTabletHeader({
    required this.step,
    required this.total,
    required this.isSummary,
    required this.formName,
    required this.templateItems,
    required this.defectMap,
    required this.allSubValues,
    required this.singleCheckValues,
    required this.forward,
  });

  int get _defectCount {
    int defects = 0;
    for (final entry in allSubValues.entries) {
      defects += entry.value.values.where((v) => v == 'fail').length;
    }
    for (final entry in singleCheckValues.entries) {
      if (entry.value.toLowerCase() == 'fail') defects++;
    }
    for (var i = 0; i < templateItems.length; i++) {
      if (allSubValues.containsKey(i)) continue;
      if (singleCheckValues.containsKey(i)) continue;
      final key = templateItems[i]['key'] as String? ?? '';
      if (defectMap[key] == true) defects++;
    }
    return defects;
  }

  @override
  Widget build(BuildContext context) {
    final defects = _defectCount;

    return Container(
      decoration: const BoxDecoration(
        color: kInspCard,
        border: Border(bottom: BorderSide(color: kInspBorder)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          // Title — fixed width to align with sidebar (250px)
          SizedBox(
            width: 250,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PREVIEW',
                  style: inspInterStyle(13, FontWeight.w600, kInspSecText)
                      .copyWith(letterSpacing: 0.5),
                ),
                Text(
                  formName,
                  style:
                      inspInterStyle(16, FontWeight.w700, kInspPrimaryText),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Progress section
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isSummary
                          ? 'Complete'
                          : 'Step ${step + 1} of $total',
                      style:
                          inspInterStyle(13, FontWeight.w500, kInspSecText),
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
                          style: inspInterStyle(
                              12, FontWeight.w600, kInspError),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
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
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TABLET SIDEBAR — step list + navigation buttons (adapted from runner)
// ═════════════════════════════════════════════════════════════════════════════

class _PreviewTabletSidebar extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final int currentStep;
  final bool isSummary;
  final Map<int, Map<String, String>> allSubValues;
  final Map<int, String> singleCheckValues;
  final Map<String, bool> defectMap;
  final Set<int> skippedSet;
  final ValueNotifier<bool> canNextNotifier;
  final ValueNotifier<VoidCallback?> handleNextNotifier;
  final ValueNotifier<VoidCallback?> handleSkipNotifier;
  final bool currentItemIsOptional;
  final VoidCallback? onBack;
  final ValueChanged<int>? onStepTapped;

  const _PreviewTabletSidebar({
    required this.items,
    required this.currentStep,
    required this.isSummary,
    required this.allSubValues,
    required this.singleCheckValues,
    required this.defectMap,
    required this.skippedSet,
    required this.canNextNotifier,
    required this.handleNextNotifier,
    required this.handleSkipNotifier,
    required this.currentItemIsOptional,
    this.onBack,
    this.onStepTapped,
  });

  @override
  State<_PreviewTabletSidebar> createState() => _PreviewTabletSidebarState();
}

class _PreviewTabletSidebarState extends State<_PreviewTabletSidebar> {
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollToActive();
  }

  @override
  void didUpdateWidget(_PreviewTabletSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStep != widget.currentStep) {
      _scrollToActive();
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToActive() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      const tileHeight = 52.0;
      final target = widget.currentStep * tileHeight;
      final maxScroll = _scrollCtrl.position.maxScrollExtent;
      _scrollCtrl.animateTo(
        target.clamp(0.0, maxScroll),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  String _stepStatus(int index) {
    if (index < widget.currentStep) return 'done';
    if (index == widget.currentStep && !widget.isSummary) return 'active';
    if (widget.isSummary) return 'done';
    if (widget.allSubValues.containsKey(index)) return 'done';
    if (widget.singleCheckValues.containsKey(index)) return 'done';
    return 'pending';
  }

  bool _hasDefect(int index) {
    final sv = widget.allSubValues[index];
    if (sv != null && sv.values.any((v) => v == 'fail')) return true;
    if (widget.singleCheckValues[index]?.toLowerCase() == 'fail') return true;
    final key = widget.items[index]['key'] as String? ?? '';
    return widget.defectMap[key] == true;
  }

  int get _firstPendingIndex {
    for (var i = 0; i < widget.items.length; i++) {
      if (_stepStatus(i) == 'pending') return i;
    }
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: kInspCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Text(
              'PREVIEW STEPS',
              style: inspInterStyle(13, FontWeight.w600, kInspSecText)
                  .copyWith(letterSpacing: 0.5),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: EdgeInsets.zero,
              itemCount: widget.items.length + 1,
              itemBuilder: (context, index) {
                // Summary tile
                if (index == widget.items.length) {
                  final summaryStatus = widget.isSummary
                      ? 'active'
                      : (_firstPendingIndex == -1 ? 'pending' : 'locked');
                  final summaryTappable = summaryStatus != 'locked' &&
                      widget.onStepTapped != null;
                  return Column(
                    children: [
                      const Divider(
                          color: kInspBorder, thickness: 1, height: 1),
                      _PreviewSidebarTile(
                        index: index,
                        label: 'Summary',
                        status: summaryStatus,
                        hasDefect: false,
                        isSummaryTile: true,
                        onTap: summaryTappable
                            ? () => widget.onStepTapped!(index)
                            : null,
                      ),
                    ],
                  );
                }

                final label = widget.items[index]['label'] as String? ??
                    'Step ${index + 1}';
                final status = _stepStatus(index);
                final hasDefect = status == 'done' && _hasDefect(index);
                final tappable = status == 'done' ||
                    status == 'active' ||
                    (status == 'pending' && index == _firstPendingIndex);

                return _PreviewSidebarTile(
                  index: index,
                  label: label,
                  status: status,
                  hasDefect: hasDefect,
                  isSkipped: widget.skippedSet.contains(index),
                  onTap: tappable && widget.onStepTapped != null
                      ? () => widget.onStepTapped!(index)
                      : null,
                );
              },
            ),
          ),
          // Navigation buttons
          if (!widget.isSummary)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: kInspBorder)),
              ),
              child: ValueListenableBuilder<bool>(
                valueListenable: widget.canNextNotifier,
                builder: (context, canNext, _) {
                  return Column(
                    children: [
                      if (widget.onBack != null) ...[
                        SizedBox(
                          width: double.infinity,
                          child: InspectionPillButton(
                            label: 'Previous',
                            leadingIcon: Icons.arrow_back_rounded,
                            onTap: widget.onBack,
                            outlined: true,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: InspectionPillButton(
                          label: 'Continue',
                          trailingIcon: Icons.arrow_forward_rounded,
                          onTap: canNext
                              ? () =>
                                  widget.handleNextNotifier.value?.call()
                              : null,
                          outlined: false,
                        ),
                      ),
                      if (widget.currentItemIsOptional) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: InspectionPillButton(
                            label: 'Skip',
                            trailingIcon: Icons.redo_rounded,
                            onTap: () =>
                                widget.handleSkipNotifier.value?.call(),
                            outlined: true,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SIDEBAR STEP TILE (adapted from runner's _SidebarStepTile)
// ═════════════════════════════════════════════════════════════════════════════

class _PreviewSidebarTile extends StatelessWidget {
  final int index;
  final String label;
  final String status; // 'done', 'active', 'pending', 'locked'
  final bool hasDefect;
  final bool isSkipped;
  final bool isSummaryTile;
  final VoidCallback? onTap;

  const _PreviewSidebarTile({
    required this.index,
    required this.label,
    required this.status,
    required this.hasDefect,
    this.isSkipped = false,
    this.isSummaryTile = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = status == 'active';
    final isDone = status == 'done';
    final isLocked = status == 'locked';

    final Color circleColor;
    final Widget circleChild;

    if (isSummaryTile) {
      if (isActive) {
        circleColor = kInspPrimary;
        circleChild = const Icon(Icons.assignment_turned_in_rounded,
            size: 14, color: Colors.white);
      } else if (isLocked) {
        circleColor = const Color(0xFFF1F5F9);
        circleChild = const Icon(Icons.assignment_turned_in_rounded,
            size: 14, color: Color(0xFFCBD5E1));
      } else {
        circleColor = const Color(0xFFF1F5F9);
        circleChild = const Icon(Icons.assignment_turned_in_rounded,
            size: 14, color: kInspPrimary);
      }
    } else if (isDone && isSkipped) {
      circleColor = const Color(0xFFF1F5F9);
      circleChild = const Icon(Icons.redo_rounded,
          size: 14, color: Color(0xFF94A3B8));
    } else if (isDone && hasDefect) {
      circleColor = kInspError;
      circleChild =
          const Icon(Icons.priority_high, size: 14, color: Colors.white);
    } else if (isDone) {
      circleColor = kInspSuccess;
      circleChild =
          const Icon(Icons.check, size: 14, color: Colors.white);
    } else if (isActive) {
      circleColor = kInspPrimary;
      circleChild = Text(
        '${index + 1}',
        style: inspInterStyle(13, FontWeight.w600, Colors.white),
      );
    } else {
      circleColor = const Color(0xFFF1F5F9);
      circleChild = Text(
        '${index + 1}',
        style:
            inspInterStyle(13, FontWeight.w500, const Color(0xFFCBD5E1)),
      );
    }

    final TextStyle labelStyle;
    if (isActive) {
      labelStyle = inspInterStyle(13, FontWeight.w700, kInspPrimary);
    } else if (isDone && isSkipped) {
      labelStyle =
          inspInterStyle(13, FontWeight.w500, const Color(0xFF94A3B8));
    } else if (isDone && hasDefect) {
      labelStyle = inspInterStyle(13, FontWeight.w600, kInspError);
    } else if (isDone) {
      labelStyle = inspInterStyle(13, FontWeight.w600, kInspSuccess);
    } else if (isSummaryTile && !isLocked) {
      labelStyle = inspInterStyle(13, FontWeight.w600, kInspPrimary);
    } else {
      labelStyle =
          inspInterStyle(13, FontWeight.w500, const Color(0xFF94A3B8));
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFF0F9FF) : null,
          border: isActive
              ? const Border(
                  right: BorderSide(color: kInspPrimary, width: 3))
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: circleColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: circleChild,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: labelStyle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

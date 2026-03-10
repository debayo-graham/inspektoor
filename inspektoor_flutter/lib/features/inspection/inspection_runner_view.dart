import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/app_state.dart';
import '/custom_code/actions/add_or_update_item_value.dart';
import '/custom_code/actions/undo_last_step.dart';
import 'inspection_session.dart';
import 'inspection_tokens.dart';
import 'components/inspection_item_step.dart';
import 'components/inspection_progress_header.dart';
import 'components/inspection_summary_view.dart';
import 'components/pill_button.dart';

// ─── InspectionRunnerView ─────────────────────────────────────────────────────
//
// Orchestrates the step-by-step inspection flow.
// Reads template + draft from FFAppState; delegates rendering to components.

class InspectionRunnerView extends StatefulWidget {
  /// Called once the first time the user makes any change (cache update or
  /// item submission). Used by the parent page to know the inspection is dirty
  /// even before the first item is fully submitted.
  final VoidCallback? onInteracted;

  const InspectionRunnerView({super.key, this.onInteracted});

  @override
  State<InspectionRunnerView> createState() => _InspectionRunnerViewState();
}

class _InspectionRunnerViewState extends State<InspectionRunnerView> {
  List<Map<String, dynamic>> _items = [];
  bool _loaded = false;
  String? _loadError;

  // Tracks slide direction: true = forward, false = back.
  bool _goingForward = true;

  // Per-item answer cache so selections survive back-navigation.
  final Map<String, Map<String, dynamic>> _answerCache = {};

  // Fired once to tell the parent page the user has started interacting.
  bool _interactionReported = false;

  // Tablet: notifiers for sidebar ↔ step widget communication.
  final ValueNotifier<bool> _canNextNotifier = ValueNotifier(false);
  final ValueNotifier<VoidCallback?> _handleNextNotifier = ValueNotifier(null);

  void _reportInteraction() {
    if (_interactionReported) return;
    _interactionReported = true;
    widget.onInteracted?.call();
  }

  @override
  void initState() {
    super.initState();
    _parseTemplate();
  }

  @override
  void dispose() {
    _canNextNotifier.dispose();
    _handleNextNotifier.dispose();
    super.dispose();
  }

  void _parseTemplate() {
    try {
      final items = InspectionSession.parseTemplate(FFAppState().templateJson);
      setState(() {
        _items = items;
        _loaded = true;
      });
    } on FormatException catch (e) {
      setState(() => _loadError = e.message);
    } catch (e) {
      setState(() => _loadError = 'Failed to parse template: $e');
    }
  }

  int _answeredCount() =>
      InspectionSession.answeredCount(FFAppState().inspectionDraftJson);

  Map<String, bool> _defectMap() =>
      InspectionSession.defectMap(
        FFAppState().inspectionDraftJson,
        templateItems: _items,
      );

  List<Map<String, dynamic>> _answeredItemsList() =>
      InspectionSession.answeredItems(FFAppState().inspectionDraftJson);

  Future<void> _onSubmit(
    Map<String, dynamic> item,
    List<dynamic> values,
  ) async {
    _reportInteraction();
    _goingForward = true;
    await addOrUpdateItemValue(
      item['key'] as String,
      item['type'] as String,
      item['label'] as String? ?? '',
      ((item['order'] as num?) ?? 0).toInt(),
      values,
    );

    FFAppState().update(() {
      FFAppState().currentInspectionIndex = _answeredCount();
    });
    if (mounted) setState(() {});
  }

  Future<void> _onBack() async {
    _goingForward = false;
    await undoLastStep();
    FFAppState().update(() {
      FFAppState().currentInspectionIndex = _answeredCount();
    });
    if (mounted) setState(() {});
  }

  /// Jump to a specific step. Supports both backward (undo) and forward
  /// (auto-submit cached steps) navigation.
  Future<void> _goToStep(int target) async {
    if (target < 0 || target > _items.length) return;
    final current = _answeredCount();
    if (target == current) return;

    if (target < current) {
      // Backward: undo steps until we reach the target.
      _goingForward = false;
      while (_answeredCount() > target) {
        await undoLastStep();
      }
    } else {
      // Forward: auto-submit cached steps from current up to target.
      _goingForward = true;
      while (_answeredCount() < target) {
        final stepIdx = _answeredCount();
        final item = _items[stepIdx];
        final key = item['key'] as String? ?? 'step_$stepIdx';
        final cached = _answerCache[key];
        if (cached == null || cached.isEmpty) break;

        final values = _valuesFromCache(item, cached);
        if (values == null) break;

        await addOrUpdateItemValue(
          key,
          item['type'] as String,
          item['label'] as String? ?? '',
          ((item['order'] as num?) ?? 0).toInt(),
          values,
        );
      }
    }

    FFAppState().update(() {
      FFAppState().currentInspectionIndex = _answeredCount();
    });
    if (mounted) setState(() {});
  }

  /// Build submission values from a cached answer.
  /// Returns null if the cache doesn't contain enough data to submit.
  List<dynamic>? _valuesFromCache(
    Map<String, dynamic> item,
    Map<String, dynamic> cache,
  ) {
    final type = item['type'] as String? ?? '';
    final cfg = Map<String, dynamic>.from(item['config'] as Map? ?? {});

    switch (type) {
      case 'numeric':
        final text = (cache['text'] as String? ?? '').trim();
        if (num.tryParse(text) == null) return null;
        return [{'key': 'value', 'label': 'Value', 'value': text}];

      case 'alphanumeric':
        final text = (cache['text'] as String? ?? '').trim();
        if (text.isEmpty) return null;
        final pattern =
            cfg['formatPattern'] as String? ?? cfg['regex'] as String?;
        if (pattern != null &&
            pattern.isNotEmpty &&
            text.length != pattern.length) {
          return null;
        }
        return [{'key': 'value', 'label': 'Value', 'value': text}];

      case 'comment-box':
        final text = (cache['text'] as String? ?? '').trim();
        if (text.isEmpty) return null;
        final maxLen = (cfg['maxLength'] as num?)?.toInt() ?? 500;
        if (text.length > maxLen) return null;
        return [{'key': 'value', 'label': 'Value', 'value': text}];

      case 'single-check':
        final choice = cache['singleChoice'] as String? ?? '';
        if (choice.isEmpty) return null;
        if (choice.toLowerCase() == 'fail') {
          // Cache stores single-check failure data under '_single' key
          const singleKey = '_single';
          final notes =
              (cache['failureNotes'] as Map?)?.cast<String, String>() ?? {};
          final photos =
              (cache['failurePhotos'] as Map?)?.cast<String, dynamic>() ?? {};
          final reqPhoto = cfg['photoRequired'] as bool? ?? false;
          final hasNote = (notes[singleKey] ?? '').trim().isNotEmpty;
          final hasPhotos = photos[singleKey] is List
              ? (photos[singleKey] as List).isNotEmpty
              : (photos[singleKey] as String? ?? '').isNotEmpty;
          if (reqPhoto && !hasPhotos) return null;
          if (!hasNote && !hasPhotos) return null;
        }
        return [{'key': 'selected', 'label': choice, 'value': choice}];

      case 'multi-check':
        final cv =
            (cache['checkValues'] as Map?)?.cast<String, String>() ?? {};
        if (cv.isEmpty || cv.values.any((v) => v.isEmpty)) return null;
        final checks = (cfg['checks'] as List? ?? []).whereType<Map>();
        final itemReqPhoto = cfg['photoRequired'] as bool? ?? false;
        final notes =
            (cache['failureNotes'] as Map?)?.cast<String, String>() ?? {};
        final photos =
            (cache['failurePhotos'] as Map?)?.cast<String, dynamic>() ?? {};
        for (final e in cv.entries.where((e) => e.value == 'fail')) {
          final checkCfg = checks
              .cast<Map<String, dynamic>>()
              .where((c) => c['id'] == e.key)
              .firstOrNull;
          final reqPhoto =
              checkCfg?['photoRequired'] as bool? ?? itemReqPhoto;
          final hasNote = (notes[e.key] ?? '').trim().isNotEmpty;
          final hasPhotos =
              photos[e.key] is List ? (photos[e.key] as List).isNotEmpty : false;
          if (reqPhoto && !hasPhotos) return null;
          if (!hasNote && !hasPhotos) return null;
        }
        return InspectionSession.buildValues(
          type: 'multi-check',
          checkValues: cv,
          multiSelected: {},
          textValue: '',
          checks: checks.map((e) => Map<String, dynamic>.from(e)).toList(),
        );

      case 'photo':
        final savedPhotos =
            (cache['photos'] as List?)?.whereType<String>() ?? [];
        if (savedPhotos.isEmpty) return null;
        return [
          {'key': 'photos', 'label': 'Photos', 'value': savedPhotos.toList()}
        ];

      case 'signature':
        final sig = cache['signatureBase64'] as String? ?? '';
        if (sig.isEmpty) return null;
        return [
          {'key': 'signature_data', 'label': 'Signature', 'value': sig}
        ];

      default:
        return null;
    }
  }

  // ── Shared state resolution ──────────────────────────────────────────────

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
        if (photos != null && photos.isNotEmpty) singleCheckValues[i] = 'pass';
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

  Widget _buildStepChild({
    required int step,
    required int total,
    required bool isSummary,
    required Map<int, Map<String, String>> allSubValues,
    required Map<int, String> singleCheckValues,
    bool isTablet = false,
  }) {
    if (isSummary) {
      // Reset notifiers on summary (no step widget owns them).
      if (isTablet) {
        _canNextNotifier.value = false;
        _handleNextNotifier.value = null;
      }
      return InspectionSummaryView(
        key: const ValueKey('__summary__'),
        templateItems: _items,
        answeredItems: _answeredItemsList(),
        defectMap: _defectMap(),
        allSubValues: allSubValues,
        singleCheckValues: singleCheckValues,
        answerCache: _answerCache,
        onBack: _onBack,
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
      defectMap: _defectMap(),
      onSubmit: (values) => _onSubmit(item, values),
      onBack: step > 0 ? _onBack : null,
      initialCache: _answerCache[currentItemKey] ?? const {},
      onCacheChanged: (cache) {
        _answerCache[currentItemKey] = cache;
        _reportInteraction();
        if (mounted) setState(() {});
      },
      hideFooter: isTablet,
      isTablet: isTablet,
      canNextNotifier: isTablet ? _canNextNotifier : null,
      handleNextNotifier: isTablet ? _handleNextNotifier : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    if (_loadError != null) {
      return _ErrorView(message: _loadError!);
    }
    if (!_loaded) {
      return const Center(child: CircularProgressIndicator());
    }

    final step = _answeredCount();
    final total = _items.length;
    final isSummary = step >= total;
    final allSubValues = _resolveSubValues();
    final singleCheckValues = _resolveSingleCheckValues();
    final goingForward = _goingForward;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 768;
        final child = _buildStepChild(
          step: step,
          total: total,
          isSummary: isSummary,
          allSubValues: allSubValues,
          singleCheckValues: singleCheckValues,
          isTablet: isTablet,
        );
        final childKey = child.key!;

        if (isTablet) {
          return _buildTabletLayout(
            step: step,
            total: total,
            isSummary: isSummary,
            allSubValues: allSubValues,
            singleCheckValues: singleCheckValues,
            goingForward: goingForward,
            child: child,
            childKey: childKey,
          );
        }
        return _buildMobileLayout(
          step: step,
          total: total,
          isSummary: isSummary,
          allSubValues: allSubValues,
          singleCheckValues: singleCheckValues,
          goingForward: goingForward,
          child: child,
          childKey: childKey,
        );
      },
    );
  }

  // ── Mobile layout (unchanged from original) ────────────────────────────

  Widget _buildMobileLayout({
    required int step,
    required int total,
    required bool isSummary,
    required Map<int, Map<String, String>> allSubValues,
    required Map<int, String> singleCheckValues,
    required bool goingForward,
    required Widget child,
    required Key childKey,
  }) {
    return Column(
      children: [
        if (!isSummary)
          InspectionProgressHeader(
            step: step,
            total: total,
            label: _items[step]['label'] as String? ?? '',
            assetName: InspectionSession.assetName(
                FFAppState().inspectionDraftJson),
            templateItems: _items,
            defectMap: _defectMap(),
            allSubValues: allSubValues,
            singleCheckValues: singleCheckValues,
            forward: goingForward,
          ),
        Expanded(
          child: AnimatedSwitcher(
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
                      Tween<Offset>(begin: begin, end: Offset.zero).animate(
                    CurvedAnimation(
                        parent: animation, curve: Curves.easeInOut),
                  ),
                  child: animChild,
                ),
              );
            },
            child: child,
          ),
        ),
      ],
    );
  }

  // ── Tablet layout ─────────────────────────────────────────────────────

  Widget _buildTabletLayout({
    required int step,
    required int total,
    required bool isSummary,
    required Map<int, Map<String, String>> allSubValues,
    required Map<int, String> singleCheckValues,
    required bool goingForward,
    required Widget child,
    required Key childKey,
  }) {
    final assetName =
        InspectionSession.assetName(FFAppState().inspectionDraftJson);
    return Column(
      children: [
        // ── Tablet header bar ──────────────────────────────────────────
        _TabletHeader(
          step: step,
          total: total,
          isSummary: isSummary,
          assetName: assetName,
          templateItems: _items,
          defectMap: _defectMap(),
          allSubValues: allSubValues,
          singleCheckValues: singleCheckValues,
          forward: goingForward,
          onBack: () {
            // Trigger the page-level back handler via Navigator
            Navigator.of(context).maybePop();
          },
        ),
        // ── Sidebar + Content ──────────────────────────────────────────
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Left sidebar ────────────────────────────────────────
              _TabletSidebar(
                items: _items,
                currentStep: step,
                isSummary: isSummary,
                allSubValues: allSubValues,
                singleCheckValues: singleCheckValues,
                defectMap: _defectMap(),
                canNextNotifier: _canNextNotifier,
                handleNextNotifier: _handleNextNotifier,
                onBack: step > 0 ? _onBack : null,
                onStepTapped: (index) {
                  if (index == step) return;
                  _goToStep(index);
                },
              ),
              // ── Vertical divider ────────────────────────────────────
              Container(width: 1, color: kInspBorder),
              // ── Content panel ───────────────────────────────────────
              Expanded(
                child: ColoredBox(
                  color: const Color(0xFFF8FAFC),
                  child: AnimatedSwitcher(
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
                          position: Tween<Offset>(
                                  begin: begin, end: Offset.zero)
                              .animate(CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeInOut)),
                          child: animChild,
                        ),
                      );
                    },
                    child: child,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── _TabletHeader ────────────────────────────────────────────────────────────

class _TabletHeader extends StatelessWidget {
  final int step;
  final int total;
  final bool isSummary;
  final String assetName;
  final List<Map<String, dynamic>> templateItems;
  final Map<String, bool> defectMap;
  final Map<int, Map<String, String>> allSubValues;
  final Map<int, String> singleCheckValues;
  final bool forward;
  final VoidCallback onBack;

  const _TabletHeader({
    required this.step,
    required this.total,
    required this.isSummary,
    required this.assetName,
    required this.templateItems,
    required this.defectMap,
    required this.allSubValues,
    required this.singleCheckValues,
    required this.forward,
    required this.onBack,
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
    final fullName = FFAppState().fullName;
    final initials = fullName.isNotEmpty
        ? fullName
            .split(' ')
            .where((w) => w.isNotEmpty)
            .take(2)
            .map((w) => w[0].toUpperCase())
            .join()
        : '?';
    final defects = _defectCount;

    return Container(
      decoration: const BoxDecoration(
        color: kInspCard,
        border: Border(bottom: BorderSide(color: kInspBorder)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          // Back button + title — fixed width to align with sidebar (250px)
          SizedBox(
            width: 250,
            child: Row(
              children: [
                InkWell(
                  onTap: onBack,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: kInspBorder),
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        size: 18, color: kInspPrimaryText),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'INSPECTION',
                        style: inspInterStyle(9, FontWeight.w600, kInspSecText)
                            .copyWith(letterSpacing: 0.5),
                      ),
                      if (assetName.isNotEmpty)
                        Text(
                          assetName,
                          style: inspInterStyle(
                              16, FontWeight.w700, kInspPrimaryText),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Progress section: step counter + defects above bar
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
                          style:
                              inspInterStyle(11, FontWeight.w600, kInspError),
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
          // Avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: kInspPrimary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: inspInterStyle(12, FontWeight.w600, kInspPrimary),
            ),
          ),
          if (fullName.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              fullName.split(' ').first,
              style: inspInterStyle(12, FontWeight.w500, kInspPrimaryText),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── _TabletSidebar ───────────────────────────────────────────────────────────

class _TabletSidebar extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final int currentStep;
  final bool isSummary;
  final Map<int, Map<String, String>> allSubValues;
  final Map<int, String> singleCheckValues;
  final Map<String, bool> defectMap;
  final ValueNotifier<bool> canNextNotifier;
  final ValueNotifier<VoidCallback?> handleNextNotifier;
  final VoidCallback? onBack;
  final ValueChanged<int>? onStepTapped;

  const _TabletSidebar({
    required this.items,
    required this.currentStep,
    required this.isSummary,
    required this.allSubValues,
    required this.singleCheckValues,
    required this.defectMap,
    required this.canNextNotifier,
    required this.handleNextNotifier,
    this.onBack,
    this.onStepTapped,
  });

  @override
  State<_TabletSidebar> createState() => _TabletSidebarState();
}

class _TabletSidebarState extends State<_TabletSidebar> {
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollToActive();
  }

  @override
  void didUpdateWidget(_TabletSidebar oldWidget) {
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
      // Each tile is ~52px tall (12px padding top + 28px circle + 12px padding bottom)
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

  /// Determine step status: 'done', 'active', or 'pending'.
  ///
  /// Items before currentStep are always 'done' (submitted to draft).
  /// Items after currentStep are 'done' if they have cached values
  /// (user filled them in previously, then navigated back).
  String _stepStatus(int index) {
    if (index < widget.currentStep) return 'done';
    if (index == widget.currentStep && !widget.isSummary) return 'active';
    if (widget.isSummary) return 'done';
    // Check if the step has cached values (filled but not yet re-submitted).
    if (widget.allSubValues.containsKey(index)) return 'done';
    if (widget.singleCheckValues.containsKey(index)) return 'done';
    return 'pending';
  }

  /// Whether this step has a defect (any fail).
  bool _hasDefect(int index) {
    // Check sub-values for multi-check
    final sv = widget.allSubValues[index];
    if (sv != null && sv.values.any((v) => v == 'fail')) return true;
    // Check single-check values
    if (widget.singleCheckValues[index]?.toLowerCase() == 'fail') return true;
    // Check defect map
    final key = widget.items[index]['key'] as String? ?? '';
    return widget.defectMap[key] == true;
  }

  /// Index of the first step with 'pending' status (no cache, not answered).
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
              'INSPECTION STEPS',
              style: inspInterStyle(10, FontWeight.w600, kInspSecText)
                  .copyWith(letterSpacing: 0.5),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: EdgeInsets.zero,
              itemCount: widget.items.length + 1, // +1 for Summary tile
              itemBuilder: (context, index) {
                // ── Summary tile (last item) ──────────────────────────────
                if (index == widget.items.length) {
                  final summaryStatus = widget.isSummary
                      ? 'active'
                      : (_firstPendingIndex == -1 ? 'pending' : 'locked');
                  final summaryTappable = summaryStatus != 'locked' &&
                      widget.onStepTapped != null;
                  return Column(
                    children: [
                      const Divider(
                        color: kInspBorder,
                        thickness: 1,
                        height: 1,
                      ),
                      _SidebarStepTile(
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

                final label =
                    widget.items[index]['label'] as String? ?? 'Step ${index + 1}';
                final status = _stepStatus(index);
                final hasDefect = status == 'done' && _hasDefect(index);

                // Tappable if: done, active, or the first unchecked step
                // (which may be ahead of currentStep when cached items
                // are shown as done).
                final tappable = status == 'done' ||
                    status == 'active' ||
                    (status == 'pending' && index == _firstPendingIndex);

                return _SidebarStepTile(
                  index: index,
                  label: label,
                  status: status,
                  hasDefect: hasDefect,
                  onTap: tappable && widget.onStepTapped != null
                      ? () => widget.onStepTapped!(index)
                      : null,
                );
              },
            ),
          ),
          // ── Navigation buttons ──────────────────────────────────────
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
                              ? () => widget.handleNextNotifier.value?.call()
                              : null,
                          outlined: false,
                        ),
                      ),
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

// ─── _SidebarStepTile ─────────────────────────────────────────────────────────

class _SidebarStepTile extends StatelessWidget {
  final int index;
  final String label;
  final String status; // 'done', 'active', 'pending', 'locked'
  final bool hasDefect;
  final bool isSummaryTile;
  final VoidCallback? onTap;

  const _SidebarStepTile({
    required this.index,
    required this.label,
    required this.status,
    required this.hasDefect,
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
      // Summary tile uses an icon instead of a number.
      if (isActive) {
        circleColor = kInspPrimary;
        circleChild = const Icon(Icons.assignment_turned_in_rounded, size: 14, color: Colors.white);
      } else if (isLocked) {
        circleColor = const Color(0xFFF1F5F9);
        circleChild = const Icon(Icons.assignment_turned_in_rounded, size: 14, color: Color(0xFFCBD5E1));
      } else {
        // pending (all steps done, tappable)
        circleColor = const Color(0xFFF1F5F9);
        circleChild = const Icon(Icons.assignment_turned_in_rounded, size: 14, color: kInspPrimary);
      }
    } else if (isDone && hasDefect) {
      circleColor = kInspError;
      circleChild = const Icon(Icons.priority_high, size: 14, color: Colors.white);
    } else if (isDone) {
      circleColor = kInspSuccess;
      circleChild = const Icon(Icons.check, size: 14, color: Colors.white);
    } else if (isActive) {
      circleColor = kInspPrimary;
      circleChild = Text(
        '${index + 1}',
        style: inspInterStyle(11, FontWeight.w600, Colors.white),
      );
    } else {
      circleColor = const Color(0xFFF1F5F9);
      circleChild = Text(
        '${index + 1}',
        style: inspInterStyle(11, FontWeight.w500, const Color(0xFFCBD5E1)),
      );
    }

    // Label style varies by state.
    final TextStyle labelStyle;
    if (isActive) {
      labelStyle = inspInterStyle(12, FontWeight.w700, kInspPrimary);
    } else if (isDone && hasDefect) {
      labelStyle = inspInterStyle(12, FontWeight.w600, kInspError);
    } else if (isDone) {
      labelStyle = inspInterStyle(12, FontWeight.w600, kInspSuccess);
    } else if (isSummaryTile && !isLocked) {
      // Summary tile when all steps done but not yet on summary
      labelStyle = inspInterStyle(12, FontWeight.w600, kInspPrimary);
    } else {
      labelStyle = inspInterStyle(12, FontWeight.w500, const Color(0xFF94A3B8));
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFF0F9FF) : null,
          border: isActive
              ? const Border(right: BorderSide(color: kInspPrimary, width: 3))
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

// ─── _ErrorView ───────────────────────────────────────────────────────────────
// Kept here — only used by InspectionRunnerView, too small to justify a file.

class _ErrorView extends StatelessWidget {
  final String message;

  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: kInspError, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: inspInterStyle(14, FontWeight.w400, kInspSecText),
            ),
          ],
        ),
      ),
    );
  }
}

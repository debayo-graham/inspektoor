import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/app_state.dart';
import '/custom_code/actions/add_or_update_item_value.dart';
import '/custom_code/actions/undo_last_step.dart';
import 'inspection_session.dart';
import 'inspection_tokens.dart';
import 'components/inspection_item_step.dart';
import 'components/inspection_summary_view.dart';

// ─── InspectionRunnerView ─────────────────────────────────────────────────────
//
// Orchestrates the step-by-step inspection flow.
// Reads template + draft from FFAppState; delegates rendering to components.

class InspectionRunnerView extends StatefulWidget {
  const InspectionRunnerView({super.key});

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

  @override
  void initState() {
    super.initState();
    _parseTemplate();
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
      InspectionSession.defectMap(FFAppState().inspectionDraftJson);

  List<Map<String, dynamic>> _answeredItemsList() =>
      InspectionSession.answeredItems(FFAppState().inspectionDraftJson);

  Future<void> _onSubmit(
    Map<String, dynamic> item,
    List<dynamic> values,
  ) async {
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

    final Key childKey;
    final Widget child;

    if (step >= total) {
      childKey = const ValueKey('__summary__');
      child = InspectionSummaryView(
        key: childKey,
        templateItems: _items,
        answeredItems: _answeredItemsList(),
        defectMap: _defectMap(),
        onBack: _onBack,
      );
    } else {
      final item = _items[step];
      final itemKey = item['key'] as String? ?? 'step_$step';
      childKey = ValueKey(itemKey);
      child = InspectionItemStep(
        key: childKey,
        item: item,
        step: step,
        total: total,
        templateItems: _items,
        defectMap: _defectMap(),
        onSubmit: (values) => _onSubmit(item, values),
        onBack: step > 0 ? _onBack : null,
        initialCache: _answerCache[itemKey] ?? const {},
        onCacheChanged: (cache) => _answerCache[itemKey] = cache,
      );
    }

    // Capture direction before the closure captures a stale value.
    final goingForward = _goingForward;

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
            position: Tween<Offset>(begin: begin, end: Offset.zero).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            ),
            child: animChild,
          ),
        );
      },
      child: child,
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

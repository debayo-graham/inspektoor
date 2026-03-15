import 'dart:async';
import 'dart:math' show pi;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/features/inspection_form/pages/form_flow_tokens.dart';

// ═════════════════════════════════════════════════════════════════════════════
// FormPickerSheet — swipeable card carousel to choose an inspection form
// ═════════════════════════════════════════════════════════════════════════════

/// Shows a bottom sheet with swipeable form cards. Returns the selected form
/// map (with `id`, `name`, `schema`, etc.) or `null` if the user dismisses.
Future<Map<String, dynamic>?> showFormPickerSheet(
  BuildContext context, {
  required String assetName,
  required String assetId,
}) {
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0xFF0F172A).withValues(alpha: 0.45),
    builder: (_) => _FormPickerSheet(assetName: assetName, assetId: assetId),
  );
}

class _FormPickerSheet extends StatefulWidget {
  final String assetName;
  final String assetId;
  const _FormPickerSheet({required this.assetName, required this.assetId});

  @override
  State<_FormPickerSheet> createState() => _FormPickerSheetState();
}

class _FormPickerSheetState extends State<_FormPickerSheet> {
  List<Map<String, dynamic>> _allForms = []; // full set for this asset
  List<Map<String, dynamic>> _forms = []; // filtered by _query
  bool _loading = true;
  int _currentPage = 0;
  String _query = '';
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  bool _searching = false;

  // ── Fan / swipe state ───────────────────────────────────────────────────
  double _dragStartX = 0;
  double _dragDelta = 0;
  bool _dragging = false;
  static const double _swipeThreshold = 35;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        final q = _searchCtrl.text.trim();
        setState(() {
          _query = q;
          _applyFilter();
        });
      }
    });
  }

  void _applyFilter() {
    if (_query.isEmpty) {
      _forms = List.of(_allForms);
    } else {
      final lq = _query.toLowerCase();
      _forms = _allForms.where((f) {
        final name = (f['name'] ?? '').toString().toLowerCase();
        final cat = (f['category'] ?? '').toString().toLowerCase();
        return name.contains(lq) || cat.contains(lq);
      }).toList();
    }
    _currentPage = 0;
  }

  Future<void> _fetch() async {
    if (!mounted) return;
    final supabase = Supabase.instance.client;
    final assetId = widget.assetId;

    try {
      // 1. Get template IDs linked to this asset.
      final relRows = await supabase
          .from('asset_inspection_templates')
          .select('inspection_template_id')
          .eq('asset_id', assetId);

      final templateIds = (relRows as List)
          .map<String>((r) => r['inspection_template_id'] as String)
          .toList();

      if (!mounted) return;

      if (templateIds.isEmpty) {
        setState(() {
          _allForms = [];
          _forms = [];
          _loading = false;
        });
        return;
      }

      // 2. Fetch template records.
      final templates = await supabase
          .from('inspection_templates')
          .select()
          .inFilter('id', templateIds)
          .order('name', ascending: true);

      if (!mounted) return;

      // 3. Count completed inspections per template for this asset.
      final counts = await supabase
          .from('inspections')
          .select('template_id')
          .eq('asset_id', assetId)
          .eq('status', 'completed')
          .inFilter('template_id', templateIds);

      if (!mounted) return;

      // Build count map.
      final countMap = <String, int>{};
      for (final row in (counts as List)) {
        final tid = row['template_id'] as String;
        countMap[tid] = (countMap[tid] ?? 0) + 1;
      }

      // 4. Merge count into each template.
      final enriched = (templates as List).map<Map<String, dynamic>>((t) {
        final m = Map<String, dynamic>.from(t as Map);
        m['completed_count'] = countMap[m['id']] ?? 0;
        return m;
      }).toList();

      setState(() {
        _allForms = enriched;
        _loading = false;
        _applyFilter();
      });
    } catch (e) {
      debugPrint('FormPickerSheet fetch error: $e');
      if (mounted) {
        setState(() {
          _allForms = [];
          _forms = [];
          _loading = false;
        });
      }
    }
  }

  int _stepCount(Map<String, dynamic> form) {
    final schema = form['schema'];
    if (schema is Map && schema.containsKey('items')) {
      return ((schema['items'] as List?) ?? []).length;
    }
    if (schema is List) return schema.length;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ──────────────────────────────────────────────
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: kFormBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // ── Header ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SELECT FORM FOR',
                        style: ffStyle(13, FontWeight.w800, kFormSlate4)
                            .copyWith(letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.assetName,
                        style: ffStyle(17, FontWeight.w800, kFormSlate8),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Search toggle
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _searching = !_searching;
                      if (!_searching) {
                        _searchCtrl.clear();
                        _query = '';
                        _applyFilter();
                      }
                    });
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _searching
                          ? const Color(0xFFF0F8FD)
                          : kFormBg,
                      border: _searching
                          ? Border.all(color: const Color(0xFFB3DFF5), width: 1.5)
                          : null,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _searching
                          ? Icons.close_rounded
                          : Icons.search_rounded,
                      size: 18,
                      color: _searching ? kFormBlue : kFormSlate5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Search bar (when active) ─────────────────────────────────
          if (_searching) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: kFormSurface,
                  border: Border.all(color: kFormBlue, width: 2),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: kFormBlue.withValues(alpha: 0.08),
                      blurRadius: 0,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, size: 16, color: kFormBlue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        autofocus: true,
                        onChanged: (_) => _onSearchChanged(),
                        style: ffStyle(13, FontWeight.w500, kFormSlate8),
                        decoration: InputDecoration.collapsed(
                          hintText: 'Search by name or category\u2026',
                          hintStyle: ffStyle(13, FontWeight.w400, kFormSlate4),
                        ),
                      ),
                    ),
                    if (_searchCtrl.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchCtrl.clear();
                          setState(() {
                            _query = '';
                            _applyFilter();
                          });
                        },
                        child: const Icon(Icons.close_rounded,
                            size: 16, color: kFormSlate4),
                      ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // ── Dot indicators + count ───────────────────────────────────
          if (!_loading && _forms.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    '${_currentPage + 1} ',
                    style: ffStyle(13, FontWeight.w800, kFormSlate8),
                  ),
                  Text(
                    'of ${_forms.length} forms',
                    style: ffStyle(13, FontWeight.w600, kFormSlate4),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      _forms.length > 8 ? 8 : _forms.length,
                      (i) => Container(
                        width: i == _currentPage ? 20 : 6,
                        height: 6,
                        margin: const EdgeInsets.only(left: 3),
                        decoration: BoxDecoration(
                          color: i == _currentPage ? kFormBlue : kFormBorder,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // ── Card fan / stack ─────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: kFormBlue))
                : _forms.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.search_off_rounded,
                                  size: 40, color: kFormBorder),
                              const SizedBox(height: 12),
                              Text(
                                _query.isNotEmpty
                                    ? 'No forms match "$_query"'
                                    : 'No forms assigned to this asset',
                                textAlign: TextAlign.center,
                                style:
                                    ffStyle(14, FontWeight.w500, kFormSlate4),
                              ),
                            ],
                          ),
                        ),
                      )
                    : GestureDetector(
                        onHorizontalDragStart: (d) {
                          _dragStartX = d.localPosition.dx;
                          _dragDelta = 0;
                          _dragging = true;
                        },
                        onHorizontalDragUpdate: (d) {
                          _dragDelta =
                              d.localPosition.dx - _dragStartX;
                        },
                        onHorizontalDragEnd: (_) {
                          if (!_dragging) return;
                          _dragging = false;
                          if (_dragDelta < -_swipeThreshold &&
                              _currentPage < _forms.length - 1) {
                            setState(() => _currentPage++);
                          } else if (_dragDelta > _swipeThreshold &&
                              _currentPage > 0) {
                            setState(() => _currentPage--);
                          }
                        },
                        behavior: HitTestBehavior.translucent,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final cardW = constraints.maxWidth * 0.78;

                            // Build visible cards sorted so active is on
                            // top (last in Stack children list).
                            final visible = <int>[];
                            for (int i = 0; i < _forms.length; i++) {
                              final off = (i - _currentPage).abs();
                              if (off <= 1) visible.add(i);
                            }
                            // Sort: furthest from active first → active last (on top).
                            visible.sort((a, b) =>
                                (b - _currentPage).abs().compareTo(
                                    (a - _currentPage).abs()));

                            return Stack(
                              alignment: Alignment.center,
                              clipBehavior: Clip.none,
                              children: visible.map((i) {
                                final offset = i - _currentPage;
                                final targetTx = offset * 110.0;
                                final targetRot =
                                    offset * 8.0 * pi / 180; // radians
                                final targetScale = offset == 0
                                    ? 1.0
                                    : offset.abs() == 1
                                        ? 0.88
                                        : 0.78;
                                final targetOpacity = offset == 0
                                    ? 1.0
                                    : offset.abs() == 1
                                        ? 0.7
                                        : 0.4;

                                final form = _forms[i];
                                final isActive = offset == 0;

                                // Pack 4 values into one tween so they
                                // all animate together.
                                final target = _FanValues(
                                  tx: targetTx,
                                  rotation: targetRot,
                                  scale: targetScale,
                                  opacity: targetOpacity,
                                );

                                return TweenAnimationBuilder<_FanValues>(
                                  key: ValueKey(i),
                                  tween: _FanTween(end: target),
                                  duration:
                                      const Duration(milliseconds: 380),
                                  curve:
                                      const Cubic(0.34, 1.26, 0.64, 1),
                                  builder: (context, v, child) {
                                    return Opacity(
                                      opacity: v.opacity.clamp(0.0, 1.0),
                                      child: SizedBox(
                                        width: cardW,
                                        child: Transform(
                                          alignment:
                                              Alignment.bottomCenter,
                                          transform: Matrix4.identity()
                                            ..translate(v.tx, 0.0)
                                            ..scale(v.scale)
                                            ..rotateZ(v.rotation),
                                          child: child,
                                        ),
                                      ),
                                    );
                                  },
                                  child: _FormCard(
                                    form: form,
                                    stepCount: _stepCount(form),
                                    completedCount:
                                        (form['completed_count'] as int?) ??
                                            0,
                                    isActive: isActive,
                                    onTap: isActive
                                        ? () => Navigator.of(context)
                                            .pop(form)
                                        : () => setState(
                                            () => _currentPage = i),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ),
          ),

          // ── Swipe hint ───────────────────────────────────────────────
          if (!_loading && _forms.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 4, top: 2),
              child: Text(
                _currentPage == 0
                    ? 'Swipe to browse \u2192'
                    : _currentPage == _forms.length - 1
                        ? '\u2190 Swipe to browse'
                        : '\u2190 Swipe to browse \u2192',
                style: ffStyle(13, FontWeight.w600, kFormSlate4),
              ),
            ),

          SizedBox(height: bottomPad + 16),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// _FormCard — individual form card in the carousel
// ═════════════════════════════════════════════════════════════════════════════

class _FormCard extends StatelessWidget {
  final Map<String, dynamic> form;
  final int stepCount;
  final int completedCount;
  final bool isActive;
  final VoidCallback onTap;

  const _FormCard({
    required this.form,
    required this.stepCount,
    required this.completedCount,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = form['name'] as String? ?? 'Untitled';
    final category = form['category'] as String?;
    final icon = categoryIcon(category);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(4, 4, 4, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: isActive
                ? const Color(0xFFB3DFF5)
                : kFormBorder,
            width: isActive ? 2 : 1.5,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: kFormBlue.withValues(alpha: 0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Hero gradient zone ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF0F8FD), Color(0xFFD6EEF9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  // Decorative circles
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFB3DFF5).withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 4,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFB3DFF5).withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon badge
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF27AAE2),
                                  Color(0xFF1A8ABF)
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: kFormBlue.withValues(alpha: 0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Icon(icon, size: 22, color: Colors.white),
                          ),
                          const Spacer(),
                          // Category chip
                          if (category != null && category.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                    color: const Color(0xFFB3DFF5)),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                category,
                                style: ffStyle(
                                    12, FontWeight.w800, kFormBlue),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        name,
                        style: ffStyle(17, FontWeight.w800, kFormSlate8),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Stats row ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  _StatPill(
                      value: '$stepCount',
                      label: 'STEPS',
                      color: kFormBlue),
                  const SizedBox(width: 8),
                  _StatPill(
                      value: '~${(stepCount * 1.5).round()}m',
                      label: 'EST. TIME',
                      color: kFormBlue),
                  const SizedBox(width: 8),
                  _StatPill(
                      value: '$completedCount',
                      label: 'USED',
                      color: completedCount > 0 ? kFormGreen : kFormSlate4),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── CTA (active card only) ─────────────────────────────────
            if (isActive)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF27AAE2), Color(0xFF1A8ABF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: kFormBlue.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.play_arrow_rounded,
                          size: 18, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        'Tap to Begin Inspection',
                        style: ffStyle(13, FontWeight.w800, Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            if (!isActive) const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── Stat pill ────────────────────────────────────────────────────────────────
class _StatPill extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatPill(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: kFormSurface,
          border: Border.all(color: kFormBorder),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(value, style: ffStyle(15, FontWeight.w800, color)),
            const SizedBox(height: 2),
            Text(label,
                style: ffStyle(13, FontWeight.w700, kFormSlate4)
                    .copyWith(letterSpacing: 0.8)),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// _FanValues / _FanTween — interpolate tx, rotation, scale, opacity together
// ═════════════════════════════════════════════════════════════════════════════

class _FanValues {
  final double tx;
  final double rotation;
  final double scale;
  final double opacity;

  const _FanValues({
    required this.tx,
    required this.rotation,
    required this.scale,
    required this.opacity,
  });

  static const zero = _FanValues(tx: 0, rotation: 0, scale: 1, opacity: 1);

  _FanValues operator +(_FanValues o) => _FanValues(
        tx: tx + o.tx,
        rotation: rotation + o.rotation,
        scale: scale + o.scale,
        opacity: opacity + o.opacity,
      );

  _FanValues operator -(_FanValues o) => _FanValues(
        tx: tx - o.tx,
        rotation: rotation - o.rotation,
        scale: scale - o.scale,
        opacity: opacity - o.opacity,
      );

  _FanValues operator *(double t) => _FanValues(
        tx: tx * t,
        rotation: rotation * t,
        scale: scale * t,
        opacity: opacity * t,
      );
}

class _FanTween extends Tween<_FanValues> {
  _FanTween({required _FanValues end})
      : super(begin: end, end: end);

  @override
  _FanValues lerp(double t) {
    final b = begin ?? _FanValues.zero;
    final e = end ?? _FanValues.zero;
    return _FanValues(
      tx: b.tx + (e.tx - b.tx) * t,
      rotation: b.rotation + (e.rotation - b.rotation) * t,
      scale: b.scale + (e.scale - b.scale) * t,
      opacity: b.opacity + (e.opacity - b.opacity) * t,
    );
  }
}

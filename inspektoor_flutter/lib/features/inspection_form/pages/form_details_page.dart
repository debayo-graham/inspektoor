import 'package:flutter/material.dart';

import '/backend/supabase/supabase.dart';
import '/common/components/confirm_action_dialog.dart';
import '/features/inspection_form/components/form_flow_step_bar.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/dashboard/home_page/home_page_widget.dart';
import 'form_confirmed_page.dart';
import 'form_flow_tokens.dart';
import 'form_preview_screen.dart';

// ─── Screen 3 — Form Details ──────────────────────────────────────────────────
///
/// Shows the full details of a selected template before committing.
/// Steps are collapsible accordion rows revealing their saved config.
class FormDetailsPage extends StatefulWidget {
  /// The form row returned by [SearchInspectionFormTemplatesCall].
  final Map<String, dynamic> form;

  const FormDetailsPage({super.key, required this.form});

  @override
  State<FormDetailsPage> createState() => _FormDetailsPageState();
}

class _FormDetailsPageState extends State<FormDetailsPage> {
  List<Map<String, dynamic>> _steps = [];
  bool _loading = true;
  bool _duplicating = false;
  String? _error;
  int? _openIndex; // accordion — only one step expanded at a time
  Map<String, dynamic>? _duplicatedForm;

  @override
  void initState() {
    super.initState();
    _fetchSchema();
  }

  Future<void> _fetchSchema() async {
    try {
      final id = widget.form['id'] as String?;
      if (id == null) throw Exception('Missing template id');

      final response = await Supabase.instance.client
          .from('inspection_templates')
          .select('schema')
          .eq('id', id)
          .single();

      final schema = response['schema'];
      List<dynamic> rawItems = [];

      if (schema is Map && schema.containsKey('items')) {
        rawItems = (schema['items'] as List?) ?? [];
      } else if (schema is List) {
        rawItems = schema;
      }

      final items = rawItems
          .whereType<Map<String, dynamic>>()
          .toList()
        ..sort((a, b) =>
            ((a['order'] as num?) ?? 0)
                .compareTo((b['order'] as num?) ?? 0));

      if (mounted) {
        setState(() {
          _steps = items;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _toggleStep(int index) {
    setState(() => _openIndex = _openIndex == index ? null : index);
  }

  Future<void> _confirmAndDuplicate() async {
    final form = widget.form;

    final confirmed = await ConfirmActionDialog.show(
      context,
      icon: Icons.file_copy_outlined,
      title: 'Use this form?',
      message:
          'This will add a copy of this form template to your organization.',
      confirmLabel: 'Use Form',
      themeColor: kFormBlue,
    );
    if (!confirmed || !mounted) return;

    setState(() => _duplicating = true);

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      final orgId = FFAppState().currentOrgId;

      final newRow = await supabase
          .from('inspection_templates')
          .insert({
            'org_id': orgId,
            'name': form['name'] as String? ?? 'Untitled',
            'category_id': form['category_id'] as String?,
            'schema': form['schema'],
            'version': 1,
            'is_active': true,
            'is_predefined': false,
            'created_by': userId,
          })
          .select()
          .single();

      if (!mounted) return;
      setState(() {
        _duplicating = false;
        _duplicatedForm = newRow;
      });

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FormConfirmedPage(
            form: newRow,
            schemaItems: _steps,
          ),
        ),
      );
      // Null out so the PopScope won't delete the form if popUntil
      // pops through this page (e.g. from Done on the confirmed page).
      // The confirmed page has its own copy and handles deletion itself.
      _duplicatedForm = null;
    } catch (e) {
      if (!mounted) return;
      setState(() => _duplicating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add form: $e',
              style: ffStyle(13, FontWeight.w500, Colors.white)),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _deleteDuplicate() async {
    final formId = _duplicatedForm?['id'] as String?;
    if (formId == null) return;
    try {
      await InspectionTemplatesTable().delete(
        matchingRows: (rows) => rows.eq('id', formId),
      );
    } catch (_) {}
    _duplicatedForm = null;
  }

  @override
  Widget build(BuildContext context) {
    final form = widget.form;
    final name = form['name'] as String? ?? 'Untitled';
    final category = form['category'] as String?;
    final createdAt = form['created_at'] as String?;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _deleteDuplicate();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            FormFlowStepBar(
              currentStepIndex: 2,
              onBack: () => Navigator.of(context).pop(),
              selectedForm: form,
              schemaStepCount: _steps.length,
              onClose: () async {
                if (_duplicatedForm != null) {
                  final confirmed = await ConfirmActionDialog.show(
                    context,
                    icon: Icons.close_rounded,
                    title: 'Exit form setup?',
                    message: 'Are you sure you want to exit? Any unsaved progress will be lost.',
                    confirmLabel: 'Exit',
                    themeColor: const Color(0xFFEF4444),
                  );
                  if (!confirmed || !mounted) return;
                  await _deleteDuplicate();
                }
                if (!mounted) return;
                Navigator.of(context).popUntil((route) => route.settings.name == HomePageWidget.routeName || route.isFirst);
              },
            ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Stack(
                children: [
                  Column(
                    children: [
                // ── Scrollable body ─────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Preview button
                        if (!_loading && _steps.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => FormPreviewScreen(
                                      templateItems: _steps,
                                      formName: name,
                                    ),
                                  ),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 9),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F3FF),
                                    border: Border.all(
                                        color: const Color(0xFFDDD6FE),
                                        width: 1.5),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                          Icons.play_circle_outline_rounded,
                                          color: Color(0xFF8B5CF6),
                                          size: 18),
                                      const SizedBox(width: 6),
                                      Text('Preview',
                                          style: ffStyle(14, FontWeight.w700,
                                              const Color(0xFF8B5CF6))),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        _buildHeaderCard(
                            name, category, createdAt, _steps.length),
                        const SizedBox(height: 20),

                        Row(
                          children: [
                            Text(
                              'INSPECTION STEPS',
                              style: ffStyle(11, FontWeight.w700, kFormSlate4)
                                  .copyWith(letterSpacing: 1.2),
                            ),
                            const Spacer(),
                            if (!_loading && _steps.isNotEmpty)
                              Text('Tap any step to expand',
                                  style: ffStyle(
                                      11, FontWeight.w500, kFormSlate4)),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (_loading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: CircularProgressIndicator(
                                  color: kFormBlue),
                            ),
                          )
                        else if (_error != null)
                          _buildError()
                        else if (_steps.isEmpty)
                          _buildNoSteps()
                        else
                          ..._steps.asMap().entries.map(
                                (e) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _StepRow(
                                    step: e.value,
                                    index: e.key,
                                    isOpen: _openIndex == e.key,
                                    onToggle: () => _toggleStep(e.key),
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ── Sticky CTA ───────────────────────────────────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0),
                      Colors.white,
                      Colors.white,
                    ],
                  ),
                ),
                child: GestureDetector(
                  onTap: _duplicating ? null : _confirmAndDuplicate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [kFormBlue, kFormBlueDk],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: kFormBlue.withValues(alpha: 0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Use This Form',
                            style:
                                ffStyle(15, FontWeight.w800, Colors.white)),
                        const SizedBox(width: 8),
                        const Icon(Icons.check_rounded,
                            color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ),
                ],
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(
      String name, String? category, String? createdAt, int stepCount) {
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
                                category.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F9FF),
                                  border: Border.all(
                                      color: const Color(0xFFBAE6FD)),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(category,
                                    style: ffStyle(
                                        10, FontWeight.w700, kFormBlue)),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(relativeTime(createdAt),
                                style: ffStyle(
                                    11, FontWeight.w400, kFormSlate4)),
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
                _StatChip(
                  label: 'Steps',
                  value: _loading ? '—' : '$stepCount',
                  color: kFormBlue,
                  bg: const Color(0xFFF0F9FF),
                ),
                const SizedBox(width: 10),
                _StatChip(
                  label: 'Est. Time',
                  value: _loading
                      ? '—'
                      : '~${(stepCount * 1.5).ceil()} min',
                  color: kFormGreen,
                  bg: const Color(0xFFF0FDF4),
                ),
                const SizedBox(width: 10),
                _StatChip(
                  label: 'Version',
                  value: 'v${widget.form['version'] ?? 1}',
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

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: kFormSlate4, size: 40),
            const SizedBox(height: 8),
            Text('Could not load steps',
                style: ffStyle(14, FontWeight.w600, kFormSlate7)),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSteps() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text('No steps defined for this form.',
            style: ffStyle(13, FontWeight.w400, kFormSlate4)),
      ),
    );
  }
}

// ─── Stat chip ────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color bg;

  const _StatChip({
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
            Text(label, style: ffStyle(10, FontWeight.w600, kFormSlate4)),
          ],
        ),
      ),
    );
  }
}

// ─── Step row (accordion) ─────────────────────────────────────────────────────
class _StepRow extends StatefulWidget {
  final Map<String, dynamic> step;
  final int index;
  final bool isOpen;
  final VoidCallback onToggle;

  const _StepRow({
    required this.step,
    required this.index,
    required this.isOpen,
    required this.onToggle,
  });

  @override
  State<_StepRow> createState() => _StepRowState();
}

class _StepRowState extends State<_StepRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: 50 + widget.index * 35), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.step['type'] as String?;
    final label = widget.step['label'] as String? ?? 'Step';
    final isOpen = widget.isOpen;

    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: isOpen ? kFormBlue : kFormBorder,
              width: isOpen ? 2 : 1.5,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: isOpen
                ? [
                    BoxShadow(
                      color: kFormBlue.withValues(alpha: 0.10),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ────────────────────────────────────────────────
              GestureDetector(
                onTap: widget.onToggle,
                behavior: HitTestBehavior.opaque,
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Vertical accent bar
                      Container(
                        width: 4,
                        margin: const EdgeInsets.fromLTRB(10, 10, 0, 10),
                        decoration: BoxDecoration(
                          color: isOpen ? kFormBlue : kFormBorder,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      // Content
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 12, 14, 12),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: isOpen
                                      ? kFormBlue.withValues(alpha: 0.08)
                                      : kFormSurface,
                                  border: Border.all(
                                      color: isOpen ? kFormBlue : kFormBorder),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Icon(
                                    itemTypeIcon(type),
                                    color: isOpen ? kFormBlue : kFormSlate5,
                                    size: 15,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(label,
                                    style: ffStyle(
                                        13, FontWeight.w600, kFormSlate7)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isOpen
                                      ? kFormBlue.withValues(alpha: 0.08)
                                      : kFormBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(itemTypeLabel(type),
                                    style: ffStyle(10, FontWeight.w700,
                                        isOpen ? kFormBlue : kFormSlate5)),
                              ),
                              const SizedBox(width: 8),
                              AnimatedRotation(
                                turns: isOpen ? 0.5 : 0,
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  Icons.expand_more_rounded,
                                  color: isOpen ? kFormBlue : kFormSlate4,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Expanded config panel ─────────────────────────────────────
              if (isOpen) ...[
                Divider(height: 1, color: kFormBlue.withValues(alpha: 0.15)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: _StepConfigPanel(step: widget.step),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Config panel ─────────────────────────────────────────────────────────────
class _StepConfigPanel extends StatelessWidget {
  final Map<String, dynamic> step;
  const _StepConfigPanel({required this.step});

  @override
  Widget build(BuildContext context) {
    final type = step['type'] as String? ?? '';
    final cfg = (step['config'] as Map<String, dynamic>?) ?? {};

    return switch (type) {
      'numeric' => _NumericPanel(cfg: cfg),
      'alphanumeric' => _AlphanumericPanel(cfg: cfg),
      'comment-box' => _CommentPanel(cfg: cfg),
      'multi-check' => _MultiCheckPanel(cfg: cfg),
      'single-check' => _SingleCheckPanel(cfg: cfg),
      'photo' => _PhotoPanel(cfg: cfg),
      'signature' => _SignaturePanel(cfg: cfg),
      'multiple-choice' => _MultipleChoicePanel(cfg: cfg),
      _ => _GenericPanel(cfg: cfg),
    };
  }
}

// ─── Shared config row ────────────────────────────────────────────────────────
class _ConfigRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ConfigRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: kFormSurface,
          border: Border.all(color: kFormBorder),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: kFormSlate4, size: 15),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: ffStyle(11, FontWeight.w500, kFormSlate5)),
            ),
            Text(value, style: ffStyle(11, FontWeight.w700, kFormSlate7)),
          ],
        ),
      ),
    );
  }
}

// ─── Numeric ──────────────────────────────────────────────────────────────────
class _NumericPanel extends StatelessWidget {
  final Map<String, dynamic> cfg;
  const _NumericPanel({required this.cfg});

  @override
  Widget build(BuildContext context) {
    final min = cfg['min']?.toString();
    final max = cfg['max']?.toString();
    final unit = cfg['unit']?.toString();
    final ocrEnabled = cfg['ocrEnabled'] == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Min / Max / Unit tiles
        if (min != null || max != null || unit != null) ...[
          Row(
            children: [
              if (min != null)
                Expanded(
                  child: _StatTile(
                    label: 'Min',
                    value: unit != null ? '$min $unit' : min,
                    color: kFormGreen,
                    bg: const Color(0xFFF0FDF4),
                    border: const Color(0xFFBBF7D0),
                  ),
                ),
              if (min != null && max != null) const SizedBox(width: 8),
              if (max != null)
                Expanded(
                  child: _StatTile(
                    label: 'Max',
                    value: unit != null ? '$max $unit' : max,
                    color: kFormGreen,
                    bg: const Color(0xFFF0FDF4),
                    border: const Color(0xFFBBF7D0),
                  ),
                ),
              if ((min != null || max != null) && unit != null)
                const SizedBox(width: 8),
              if (unit != null)
                Expanded(
                  child: _StatTile(
                    label: 'Unit',
                    value: unit,
                    color: kFormBlue,
                    bg: const Color(0xFFF0F9FF),
                    border: const Color(0xFFBAE6FD),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        _ConfigRow(
          icon: Icons.tag_rounded,
          label: 'Input type',
          value: 'Number only',
        ),
        if (ocrEnabled)
          _ConfigRow(
            icon: Icons.document_scanner_outlined,
            label: 'OCR scan',
            value: 'Enabled',
          ),
      ],
    );
  }
}

// ─── Alphanumeric ─────────────────────────────────────────────────────────────
class _AlphanumericPanel extends StatelessWidget {
  final Map<String, dynamic> cfg;
  const _AlphanumericPanel({required this.cfg});

  @override
  Widget build(BuildContext context) {
    final placeholder = cfg['placeholder']?.toString();
    final maxLength = cfg['maxLength']?.toString();
    final ocrEnabled = cfg['ocrEnabled'] == true;
    final formatPattern = cfg['formatPattern']?.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ConfigRow(
          icon: Icons.text_fields_rounded,
          label: 'Input type',
          value: 'Text & numbers',
        ),
        if (placeholder != null && placeholder.isNotEmpty)
          _ConfigRow(
            icon: Icons.info_outline_rounded,
            label: 'Hint text',
            value: placeholder,
          ),
        if (maxLength != null)
          _ConfigRow(
            icon: Icons.straighten_rounded,
            label: 'Max length',
            value: '$maxLength characters',
          ),
        if (formatPattern != null && formatPattern.isNotEmpty)
          _ConfigRow(
            icon: Icons.format_quote_rounded,
            label: 'Format pattern',
            value: formatPattern,
          ),
        if (ocrEnabled)
          _ConfigRow(
            icon: Icons.document_scanner_outlined,
            label: 'OCR scan',
            value: 'Enabled',
          ),
      ],
    );
  }
}

// ─── Comment box ──────────────────────────────────────────────────────────────
class _CommentPanel extends StatelessWidget {
  final Map<String, dynamic> cfg;
  const _CommentPanel({required this.cfg});

  @override
  Widget build(BuildContext context) {
    final maxLength = cfg['maxLength']?.toString();
    final ocrEnabled = cfg['ocrEnabled'] == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ConfigRow(
          icon: Icons.chat_bubble_outline_rounded,
          label: 'Input type',
          value: 'Free text',
        ),
        if (maxLength != null)
          _ConfigRow(
            icon: Icons.straighten_rounded,
            label: 'Max length',
            value: '$maxLength characters',
          ),
        _ConfigRow(
          icon: Icons.document_scanner_outlined,
          label: 'OCR scan',
          value: ocrEnabled ? 'Enabled' : 'Disabled',
        ),
      ],
    );
  }
}

// ─── Multi-check ──────────────────────────────────────────────────────────────
class _MultiCheckPanel extends StatelessWidget {
  final Map<String, dynamic> cfg;
  const _MultiCheckPanel({required this.cfg});

  @override
  Widget build(BuildContext context) {
    final rawChecks = cfg['checks'];
    // Preserve full check maps so we can read per-check photo config
    final checks = rawChecks is List
        ? rawChecks.whereType<Map>().toList()
        : <Map>[];

    // Global fallbacks (used when a check doesn't override)
    final globalPhotoRequired = cfg['photoRequired'] == true;
    final globalMaxPhotos =
        (cfg['maxPhotos'] as num?)?.toInt() ?? 5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ConfigRow(
          icon: Icons.checklist_rounded,
          label: 'Items',
          value:
              '${checks.length} checklist item${checks.length != 1 ? 's' : ''}',
        ),
        if (checks.isNotEmpty) ...[
          const SizedBox(height: 10),
          // Column header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'CHECKLIST ITEMS',
                    style: ffStyle(10, FontWeight.w700, kFormSlate4)
                        .copyWith(letterSpacing: 1.0),
                  ),
                ),
                Text(
                  'PHOTO · MAX',
                  style: ffStyle(10, FontWeight.w700, kFormSlate4)
                      .copyWith(letterSpacing: 1.0),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          ...checks.map((check) {
            final label = check['label']?.toString() ?? '';
            final photoReq = check.containsKey('photoRequired')
                ? check['photoRequired'] == true
                : globalPhotoRequired;
            final maxPh = check.containsKey('maxPhotos')
                ? (check['maxPhotos'] as num?)?.toInt() ?? globalMaxPhotos
                : globalMaxPhotos;

            return Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: kFormSurface,
                  border: Border.all(color: kFormBorder),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_box_outline_blank_rounded,
                        color: kFormSlate4, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(label,
                          style: ffStyle(12, FontWeight.w500, kFormSlate6)),
                    ),
                    const Icon(Icons.photo_camera_outlined,
                        color: kFormSlate4, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      '${photoReq ? 'Req' : 'Opt'} · $maxPh',
                      style: ffStyle(11, FontWeight.w700, kFormSlate4),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }
}

// ─── Single-check ─────────────────────────────────────────────────────────────
class _SingleCheckPanel extends StatelessWidget {
  final Map<String, dynamic> cfg;
  const _SingleCheckPanel({required this.cfg});

  @override
  Widget build(BuildContext context) {
    final photoRequired = cfg['photoRequired'] == true;
    final maxPhotos = cfg['maxPhotos']?.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ConfigRow(
          icon: Icons.check_circle_outline_rounded,
          label: 'Input type',
          value: 'Pass / Fail only',
        ),
        _ConfigRow(
          icon: Icons.photo_camera_outlined,
          label: 'Photo on fail',
          value: photoRequired ? 'Required' : 'Optional',
        ),
        _ConfigRow(
          icon: Icons.edit_note_rounded,
          label: 'Note on fail',
          value: 'Required',
        ),
        if (maxPhotos != null)
          _ConfigRow(
            icon: Icons.photo_library_outlined,
            label: 'Max photos',
            value: maxPhotos,
          ),
      ],
    );
  }
}

// ─── Photo ────────────────────────────────────────────────────────────────────
class _PhotoPanel extends StatelessWidget {
  final Map<String, dynamic> cfg;
  const _PhotoPanel({required this.cfg});

  @override
  Widget build(BuildContext context) {
    final minPhotos = cfg['minPhotos']?.toString();
    final maxPhotos = cfg['maxPhotos']?.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ConfigRow(
          icon: Icons.photo_camera_outlined,
          label: 'Source',
          value: 'Camera or gallery',
        ),
        if (minPhotos != null)
          _ConfigRow(
            icon: Icons.photo_outlined,
            label: 'Min photos',
            value: minPhotos,
          ),
        if (maxPhotos != null)
          _ConfigRow(
            icon: Icons.photo_library_outlined,
            label: 'Max photos',
            value: maxPhotos,
          ),
      ],
    );
  }
}

// ─── Signature ────────────────────────────────────────────────────────────────
class _SignaturePanel extends StatelessWidget {
  final Map<String, dynamic> cfg;
  const _SignaturePanel({required this.cfg});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ConfigRow(
          icon: Icons.draw_outlined,
          label: 'Type',
          value: 'Digital draw',
        ),
        _ConfigRow(
          icon: Icons.person_outline_rounded,
          label: 'Signee',
          value: 'Assigned inspector',
        ),
        _ConfigRow(
          icon: Icons.schedule_rounded,
          label: 'Timestamp',
          value: 'Auto-added',
        ),
      ],
    );
  }
}

// ─── Multiple-choice ──────────────────────────────────────────────────────────
class _MultipleChoicePanel extends StatelessWidget {
  final Map<String, dynamic> cfg;
  const _MultipleChoicePanel({required this.cfg});

  @override
  Widget build(BuildContext context) {
    final rawOptions = cfg['options'];
    final options = rawOptions is List
        ? rawOptions.map((o) {
            if (o is Map) return o['label']?.toString() ?? '';
            return o.toString();
          }).where((s) => s.isNotEmpty).toList()
        : <String>[];
    final allowMultiple = cfg['allowMultiple'] == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (options.isNotEmpty) ...[
          Text(
            'OPTIONS',
            style: ffStyle(10, FontWeight.w700, kFormSlate4)
                .copyWith(letterSpacing: 1.0),
          ),
          const SizedBox(height: 6),
          ...options.map(
            (opt) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                children: [
                  const Icon(Icons.radio_button_checked_rounded,
                      color: kFormSlate4, size: 15),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(opt,
                        style: ffStyle(12, FontWeight.w500, kFormSlate6)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        _ConfigRow(
          icon: Icons.radio_button_checked_rounded,
          label: 'Selection',
          value: allowMultiple ? 'Multiple allowed' : 'Single only',
        ),
        _ConfigRow(
          icon: Icons.format_list_bulleted_rounded,
          label: 'Options',
          value: '${options.length} choice${options.length != 1 ? 's' : ''}',
        ),
      ],
    );
  }
}

// ─── Generic fallback ─────────────────────────────────────────────────────────
class _GenericPanel extends StatelessWidget {
  final Map<String, dynamic> cfg;
  const _GenericPanel({required this.cfg});

  @override
  Widget build(BuildContext context) {
    if (cfg.isEmpty) {
      return Text('No configuration available.',
          style: ffStyle(12, FontWeight.w400, kFormSlate4));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: cfg.entries
          .where((e) => e.value != null)
          .map(
            (e) => _ConfigRow(
              icon: Icons.settings_outlined,
              label: e.key,
              value: e.value.toString(),
            ),
          )
          .toList(),
    );
  }
}

// ─── Stat tile (min/max/unit) ─────────────────────────────────────────────────
class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color bg;
  final Color border;

  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: ffStyle(9, FontWeight.w700, kFormSlate4)
                .copyWith(letterSpacing: 0.8),
          ),
          const SizedBox(height: 2),
          Text(value, style: ffStyle(13, FontWeight.w800, color)),
        ],
      ),
    );
  }
}

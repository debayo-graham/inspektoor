import 'package:flutter/material.dart';

import '/backend/supabase/supabase.dart';
import 'form_confirmed_page.dart';
import 'form_flow_tokens.dart';

// ─── Screen 3 — Form Preview ──────────────────────────────────────────────────
///
/// Shows the full details of a selected template before committing.
/// Fetches the template schema from Supabase to build the step list.
class FormPreviewPage extends StatefulWidget {
  /// The form row returned by [SearchInspectionFormTemplatesCall].
  final Map<String, dynamic> form;

  const FormPreviewPage({super.key, required this.form});

  @override
  State<FormPreviewPage> createState() => _FormPreviewPageState();
}

class _FormPreviewPageState extends State<FormPreviewPage> {
  List<Map<String, dynamic>> _steps = [];
  bool _loading = true;
  String? _error;

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

  @override
  Widget build(BuildContext context) {
    final form = widget.form;
    final name = form['name'] as String? ?? 'Untitled';
    final category = form['category'] as String?;
    final createdAt = form['created_at'] as String?;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // ── App bar ─────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      const FormFlowBackButton(),
                      Expanded(
                        child: Center(
                          child: Text('Form Preview',
                              style:
                                  ffStyle(17, FontWeight.w800, kFormSlate8)),
                        ),
                      ),
                      const SizedBox(width: 36),
                    ],
                  ),
                ),

                // ── Scrollable body ─────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Form header card
                        _buildHeaderCard(
                            name, category, createdAt, _steps.length),
                        const SizedBox(height: 20),

                        // Steps
                        Text(
                          'INSPECTION STEPS',
                          style: ffStyle(11, FontWeight.w700, kFormSlate4)
                              .copyWith(letterSpacing: 1.2),
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
                                      step: e.value, index: e.key),
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
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FormConfirmedPage(
                        form: form,
                        schemaItems: _steps,
                      ),
                    ),
                  ),
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
                    child: Icon(
                      categoryIcon(category),
                      color: kFormBlue,
                      size: 26,
                    ),
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
                            style: ffStyle(
                                16, FontWeight.w800, kFormSlate8)),
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
                            Text(
                              relativeTime(createdAt),
                              style: ffStyle(
                                  11, FontWeight.w400, kFormSlate4),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Stat chips
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
            Text(value,
                style: ffStyle(15, FontWeight.w800, color)),
            const SizedBox(height: 2),
            Text(label,
                style: ffStyle(10, FontWeight.w600, kFormSlate4)),
          ],
        ),
      ),
    );
  }
}

// ─── Step row ─────────────────────────────────────────────────────────────────
class _StepRow extends StatefulWidget {
  final Map<String, dynamic> step;
  final int index;
  const _StepRow({required this.step, required this.index});

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

    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: kFormSurface,
                  border: Border.all(color: kFormBorder),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    itemTypeIcon(type),
                    color: kFormSlate5,
                    size: 15,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label,
                    style: ffStyle(13, FontWeight.w600, kFormSlate7)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: kFormBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(itemTypeLabel(type),
                    style: ffStyle(10, FontWeight.w700, kFormSlate5)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

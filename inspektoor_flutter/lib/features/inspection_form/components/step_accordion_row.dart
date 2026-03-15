import 'package:flutter/material.dart';

import '../pages/form_flow_tokens.dart';

// ─── Step row (accordion) ─────────────────────────────────────────────────────
/// Reusable accordion row for displaying a template step with expand/collapse.
/// Used by the unified form flow shell in both mobile and tablet layouts.
class StepRow extends StatefulWidget {
  final Map<String, dynamic> step;
  final int index;
  final bool isOpen;
  final VoidCallback onToggle;

  const StepRow({
    super.key,
    required this.step,
    required this.index,
    required this.isOpen,
    required this.onToggle,
  });

  @override
  State<StepRow> createState() => _StepRowState();
}

class _StepRowState extends State<StepRow>
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
                                    style: ffStyle(13, FontWeight.w700,
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
                  child: StepConfigPanel(step: widget.step),
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
class StepConfigPanel extends StatelessWidget {
  final Map<String, dynamic> step;
  const StepConfigPanel({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    final type = step['type'] as String? ?? '';
    final cfg = (step['config'] as Map<String, dynamic>?) ?? {};
    final isRequired = step['required'] != false;

    final typePanel = switch (type) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConfigRow(
          icon: isRequired
              ? Icons.lock_outline_rounded
              : Icons.lock_open_rounded,
          label: 'Completion',
          value: isRequired ? 'Required' : 'Optional',
        ),
        const SizedBox(height: 6),
        typePanel,
      ],
    );
  }
}

// ─── Shared config row ────────────────────────────────────────────────────────
class ConfigRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const ConfigRow({
    super.key,
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
                  style: ffStyle(13, FontWeight.w500, kFormSlate5)),
            ),
            Text(value, style: ffStyle(13, FontWeight.w700, kFormSlate7)),
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
        if (min != null || max != null || unit != null) ...[
          Row(
            children: [
              if (min != null)
                Expanded(
                  child: StatTile(
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
                  child: StatTile(
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
                  child: StatTile(
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
        ConfigRow(
          icon: Icons.tag_rounded,
          label: 'Input type',
          value: 'Number only',
        ),
        if (ocrEnabled)
          ConfigRow(
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
        ConfigRow(
          icon: Icons.text_fields_rounded,
          label: 'Input type',
          value: 'Text & numbers',
        ),
        if (placeholder != null && placeholder.isNotEmpty)
          ConfigRow(
            icon: Icons.info_outline_rounded,
            label: 'Hint text',
            value: placeholder,
          ),
        if (maxLength != null)
          ConfigRow(
            icon: Icons.straighten_rounded,
            label: 'Max length',
            value: '$maxLength characters',
          ),
        if (formatPattern != null && formatPattern.isNotEmpty)
          ConfigRow(
            icon: Icons.format_quote_rounded,
            label: 'Format pattern',
            value: formatPattern,
          ),
        if (ocrEnabled)
          ConfigRow(
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
        ConfigRow(
          icon: Icons.chat_bubble_outline_rounded,
          label: 'Input type',
          value: 'Free text',
        ),
        if (maxLength != null)
          ConfigRow(
            icon: Icons.straighten_rounded,
            label: 'Max length',
            value: '$maxLength characters',
          ),
        ConfigRow(
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
    final checks = rawChecks is List
        ? rawChecks.whereType<Map>().toList()
        : <Map>[];

    final globalPhotoRequired = cfg['photoRequired'] == true;
    final globalMaxPhotos =
        (cfg['maxPhotos'] as num?)?.toInt() ?? 5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConfigRow(
          icon: Icons.checklist_rounded,
          label: 'Items',
          value:
              '${checks.length} checklist item${checks.length != 1 ? 's' : ''}',
        ),
        if (checks.isNotEmpty) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'CHECKLIST ITEMS',
                    style: ffStyle(13, FontWeight.w700, kFormSlate4)
                        .copyWith(letterSpacing: 1.0),
                  ),
                ),
                Text(
                  'PHOTO · MAX',
                  style: ffStyle(13, FontWeight.w700, kFormSlate4)
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
                          style: ffStyle(13, FontWeight.w500, kFormSlate6)),
                    ),
                    const Icon(Icons.photo_camera_outlined,
                        color: kFormSlate4, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      '${photoReq ? 'Req' : 'Opt'} · $maxPh',
                      style: ffStyle(13, FontWeight.w700, kFormSlate4),
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
        ConfigRow(
          icon: Icons.check_circle_outline_rounded,
          label: 'Input type',
          value: 'Pass / Fail only',
        ),
        ConfigRow(
          icon: Icons.photo_camera_outlined,
          label: 'Photo on fail',
          value: photoRequired ? 'Required' : 'Optional',
        ),
        ConfigRow(
          icon: Icons.edit_note_rounded,
          label: 'Note on fail',
          value: 'Required',
        ),
        if (maxPhotos != null)
          ConfigRow(
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
        ConfigRow(
          icon: Icons.photo_camera_outlined,
          label: 'Source',
          value: 'Camera or gallery',
        ),
        if (minPhotos != null)
          ConfigRow(
            icon: Icons.photo_outlined,
            label: 'Min photos',
            value: minPhotos,
          ),
        if (maxPhotos != null)
          ConfigRow(
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
        ConfigRow(
          icon: Icons.draw_outlined,
          label: 'Type',
          value: 'Digital draw',
        ),
        ConfigRow(
          icon: Icons.person_outline_rounded,
          label: 'Signee',
          value: 'Assigned inspector',
        ),
        ConfigRow(
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
            style: ffStyle(13, FontWeight.w700, kFormSlate4)
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
                        style: ffStyle(13, FontWeight.w500, kFormSlate6)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        ConfigRow(
          icon: Icons.radio_button_checked_rounded,
          label: 'Selection',
          value: allowMultiple ? 'Multiple allowed' : 'Single only',
        ),
        ConfigRow(
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
          style: ffStyle(13, FontWeight.w400, kFormSlate4));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: cfg.entries
          .where((e) => e.value != null)
          .map(
            (e) => ConfigRow(
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
class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color bg;
  final Color border;

  const StatTile({
    super.key,
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
            style: ffStyle(13, FontWeight.w700, kFormSlate4)
                .copyWith(letterSpacing: 0.8),
          ),
          const SizedBox(height: 2),
          Text(value, style: ffStyle(13, FontWeight.w800, color)),
        ],
      ),
    );
  }
}

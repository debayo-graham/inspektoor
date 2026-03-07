import 'dart:typed_data';

import 'package:flutter/material.dart';

import '/flutter_flow/upload_data.dart';
import '../../../../common/components/photo_capture_box.dart';
import '../../inspection_tokens.dart';

// ─── InspectionMultiCheckList ──────────────────────────────────────────────────

class InspectionMultiCheckList extends StatelessWidget {
  final List<Map<String, dynamic>> checks;
  final Map<String, String> values;
  final Map<String, String> failureNotes;
  final Map<String, List<Uint8List>> failurePhotos;
  final void Function(String id, String value) onToggle;
  final void Function(String id, String note) onNoteChanged;
  final void Function(String id, List<Uint8List>) onPhotosChanged;
  final Future<void> Function() onPassAll;
  final bool submitting;
  final bool photoRequired;
  final int maxPhotos;

  const InspectionMultiCheckList({
    super.key,
    required this.checks,
    required this.values,
    required this.failureNotes,
    required this.failurePhotos,
    required this.onToggle,
    required this.onNoteChanged,
    required this.onPhotosChanged,
    required this.onPassAll,
    required this.submitting,
    this.photoRequired = false,
    this.maxPhotos = 5,
  });

  bool get _allAnswered => checks.isNotEmpty &&
      checks.every((c) => (values[c['id'] as String? ?? ''] ?? '').isNotEmpty);
  bool get _allPassed => _allAnswered &&
      checks.every((c) => values[c['id'] as String? ?? ''] == 'pass');
  bool get _anyFailed =>
      checks.any((c) => values[c['id'] as String? ?? ''] == 'fail');
  int get _failCount =>
      checks.where((c) => values[c['id'] as String? ?? ''] == 'fail').length;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Status banners ────────────────────────────────────────────────────
        if (_allPassed) ...[
          _AllPassedBanner(),
          const SizedBox(height: 12),
        ],
        if (_anyFailed && _allAnswered) ...[
          _IssuesBanner(count: _failCount),
          const SizedBox(height: 12),
        ],

        // ── Pass All button (hidden when all already passed) ───────────────
        if (!_allPassed) ...[
          _PassAllButton(onTap: submitting ? null : onPassAll),
          const SizedBox(height: 12),
        ],

        // ── Item cards ────────────────────────────────────────────────────
        ...checks.map((check) {
          final id = check['id'] as String? ?? '';
          final label = check['label'] as String? ?? '';
          final value = values[id] ?? '';
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _MultiCheckCard(
              id: id,
              label: label,
              value: value,
              note: failureNotes[id] ?? '',
              photos: failurePhotos[id] ?? [],
              disabled: submitting,
              onToggle: (v) => onToggle(id, v),
              onNoteChanged: (n) => onNoteChanged(id, n),
              onPhotosChanged: (list) => onPhotosChanged(id, list),
              photoRequired: photoRequired,
              maxPhotos: maxPhotos,
            ),
          );
        }),
      ],
    );
  }
}

// ─── _AllPassedBanner ─────────────────────────────────────────────────────────

class _AllPassedBanner extends StatelessWidget {
  const _AllPassedBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kInspPassBorder, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: kInspPassFill.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Section Complete — All Passed',
                  style: inspInterStyle(13, FontWeight.w800, Color(0xFF065F46)),
                ),
                const SizedBox(height: 2),
                Text(
                  'All items are verified and up to date.',
                  style: inspInterStyle(12, FontWeight.w400, Color(0xFF059669)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── _IssuesBanner ────────────────────────────────────────────────────────────

class _IssuesBanner extends StatelessWidget {
  final int count;
  const _IssuesBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kInspWarningBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kInspWarningBorder, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: kInspWarning,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Issues Found',
                  style: inspInterStyle(13, FontWeight.w800, Color(0xFF92400E)),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count item${count == 1 ? '' : 's'} failed. Notes required before proceeding.',
                  style: inspInterStyle(12, FontWeight.w400, Color(0xFFB45309)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── _PassAllButton ───────────────────────────────────────────────────────────

class _PassAllButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _PassAllButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kInspPassBorder, width: 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: kInspPassBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: kInspPassFill, width: 1.5),
                  ),
                  child: Icon(Icons.check_rounded,
                      color: kInspPassFill, size: 13),
                ),
                const SizedBox(width: 8),
                Text(
                  'Pass All Items',
                  style: inspInterStyle(14, FontWeight.w700, kInspPassFill),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── _MultiCheckCard ──────────────────────────────────────────────────────────

class _MultiCheckCard extends StatelessWidget {
  final String id;
  final String label;
  final String value;
  final String note;
  final List<Uint8List> photos;
  final bool disabled;
  final void Function(String value) onToggle;
  final void Function(String note) onNoteChanged;
  final void Function(List<Uint8List>) onPhotosChanged;
  final bool photoRequired;
  final int maxPhotos;

  const _MultiCheckCard({
    required this.id,
    required this.label,
    required this.value,
    required this.note,
    required this.photos,
    required this.disabled,
    required this.onToggle,
    required this.onNoteChanged,
    required this.onPhotosChanged,
    this.photoRequired = false,
    this.maxPhotos = 5,
  });

  Color get _bg =>
      value == 'pass' ? kInspPassBg : value == 'fail' ? kInspFailBg : kInspSlate;
  Color get _border =>
      value == 'pass' ? kInspPassBorder : value == 'fail' ? kInspFailBorder : kInspBorder;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Main row ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _StatusDot(value: value),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: inspInterStyle(
                            14, FontWeight.w600, kInspPrimaryText),
                      ),
                      if (value.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          value == 'pass'
                              ? '✓ Passed'
                              : '✗ Failed — note required',
                          style: inspInterStyle(
                            11,
                            FontWeight.w600,
                            value == 'pass' ? kInspPassFill : kInspFailFill,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _FilledSegmentedControl(
                  value: value,
                  disabled: disabled,
                  onToggle: onToggle,
                ),
              ],
            ),
          ),

          // ── Failure note panel ────────────────────────────────────────────
          if (value == 'fail') ...[
            Divider(height: 1, thickness: 1, color: kInspFailBorder),
            _FailureNotePanel(
              note: note,
              onChanged: onNoteChanged,
              photos: photos,
              onPhotosChanged: onPhotosChanged,
              photoRequired: photoRequired,
              maxPhotos: maxPhotos,
            ),
          ],
        ],
      ),
    );
  }
}

// ─── _StatusDot ───────────────────────────────────────────────────────────────

class _StatusDot extends StatelessWidget {
  final String value;
  const _StatusDot({required this.value});

  @override
  Widget build(BuildContext context) {
    final color = value == 'pass'
        ? kInspPassFill
        : value == 'fail'
            ? kInspFailFill
            : const Color(0xFFCBD5E1); // slate-300
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// ─── _FilledSegmentedControl ──────────────────────────────────────────────────

class _FilledSegmentedControl extends StatelessWidget {
  final String value;
  final bool disabled;
  final void Function(String) onToggle;

  const _FilledSegmentedControl({
    required this.value,
    required this.disabled,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9), // slate-100
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kInspBorder, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Chip(
            label: 'Pass',
            active: value == 'pass',
            activeColor: kInspPassFill,
            side: _ChipSide.left,
            disabled: disabled,
            onTap: () => onToggle('pass'),
          ),
          _Chip(
            label: 'Fail',
            active: value == 'fail',
            activeColor: kInspFailFill,
            side: _ChipSide.right,
            disabled: disabled,
            onTap: () => onToggle('fail'),
          ),
        ],
      ),
    );
  }
}

enum _ChipSide { left, right }

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  final Color activeColor;
  final _ChipSide side;
  final bool disabled;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.active,
    required this.activeColor,
    required this.side,
    required this.disabled,
    required this.onTap,
  });

  BorderRadius get _radius => side == _ChipSide.left
      ? const BorderRadius.horizontal(left: Radius.circular(10))
      : const BorderRadius.horizontal(right: Radius.circular(10));

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? activeColor : Colors.transparent,
          borderRadius: _radius,
        ),
        child: Text(
          label,
          style: inspInterStyle(
            11,
            FontWeight.w700,
            active ? Colors.white : const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }
}

// ─── _FailureNotePanel ────────────────────────────────────────────────────────

class _FailureNotePanel extends StatefulWidget {
  final String note;
  final void Function(String) onChanged;
  final List<Uint8List> photos;
  final void Function(List<Uint8List>) onPhotosChanged;
  final bool photoRequired;
  final int maxPhotos;

  const _FailureNotePanel({
    required this.note,
    required this.onChanged,
    required this.photos,
    required this.onPhotosChanged,
    this.photoRequired = false,
    this.maxPhotos = 5,
  });

  @override
  State<_FailureNotePanel> createState() => _FailureNotePanelState();
}

class _FailureNotePanelState extends State<_FailureNotePanel> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.note);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FAILURE EVIDENCE',
            style: inspInterStyle(10, FontWeight.w700, kInspFailFill)
                .copyWith(letterSpacing: 1.2),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _ctrl,
            onChanged: widget.onChanged,
            maxLines: 3,
            style: inspInterStyle(13, FontWeight.w400, kInspPrimaryText),
            decoration: InputDecoration(
              hintText: 'Describe the issue…',
              hintStyle: inspInterStyle(13, FontWeight.w400, kInspSecText),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: kInspFailBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: kInspFailBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: kInspFailFill, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // ── Photo capture box ─────────────────────────────────────────────
          PhotoCaptureBox(
            photos: widget.photos,
            maxPhotos: widget.maxPhotos,
            borderColor: kInspFailBorder,
            accentColor: kInspFailFill,
            accentBgColor: const Color(0xFFFEE2E2),
            onPhotosChanged: widget.onPhotosChanged,
            onCapturePhoto: () async {
              final selected =
                  await selectMedia(mediaSource: MediaSource.camera);
              if (selected != null && selected.isNotEmpty) {
                return selected.first.bytes;
              }
              return null;
            },
            emptyLabel: 'Tap to take photo',
            emptySubtitle: 'Evidence of the issue',
          ),
          if (widget.photoRequired && widget.photos.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Photo evidence required',
                style: inspInterStyle(11, FontWeight.w600, kInspFailFill),
              ),
            ),
        ],
      ),
    );
  }
}

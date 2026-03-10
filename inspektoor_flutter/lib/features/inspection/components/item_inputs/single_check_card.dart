import 'dart:typed_data';

import 'package:flutter/material.dart';

import '/flutter_flow/upload_data.dart';
import '../../../../common/components/photo_capture_box.dart';
import '../../inspection_tokens.dart';

// ─── InspectionSingleCheckCard ───────────────────────────────────────────────
//
// Stacked Pass / Fail card buttons with an "or" divider.
// When "Fail" is selected, a failure evidence panel slides in (note + photos).
// Matches the mockup: gradient active states, radio dot, opacity dimming.

class InspectionSingleCheckCard extends StatelessWidget {
  final String value; // 'pass', 'fail', or '' (unset)
  final String note;
  final List<Uint8List> photos;
  final bool disabled;
  final void Function(String value) onToggle;
  final void Function(String note) onNoteChanged;
  final void Function(List<Uint8List>) onPhotosChanged;
  final bool photoRequired;
  final int maxPhotos;
  final bool isTablet;

  const InspectionSingleCheckCard({
    super.key,
    required this.value,
    this.note = '',
    this.photos = const [],
    this.disabled = false,
    required this.onToggle,
    required this.onNoteChanged,
    required this.onPhotosChanged,
    this.photoRequired = false,
    this.maxPhotos = 5,
    this.isTablet = false,
  });

  Widget _passButton() => _ChoiceButton(
        label: 'Pass',
        subtitle: value == 'pass'
            ? '✓ Marked as passed'
            : 'Item is in acceptable condition',
        icon: Icons.check_rounded,
        selected: value == 'pass',
        dimmed: value == 'fail',
        activeGradient: const [Color(0xFF10B981), Color(0xFF059669)],
        inactiveBorderColor: const Color(0xFFBBF7D0),
        inactiveIconBg: const Color(0xFFDCFCE7),
        inactiveIconColor: const Color(0xFF10B981),
        disabled: disabled,
        onTap: () => onToggle(value == 'pass' ? '' : 'pass'),
        vertical: isTablet,
      );

  Widget _failButton() => _ChoiceButton(
        label: 'Fail',
        subtitle: value == 'fail'
            ? (photoRequired
                ? '⚠ Photo required'
                : '⚠ Note or photo required')
            : 'Item has a defect or issue',
        icon: Icons.close_rounded,
        selected: value == 'fail',
        dimmed: value == 'pass',
        activeGradient: const [Color(0xFFEF4444), Color(0xFFDC2626)],
        inactiveBorderColor: const Color(0xFFFECACA),
        inactiveIconBg: const Color(0xFFFEE2E2),
        inactiveIconColor: const Color(0xFFEF4444),
        disabled: disabled,
        onTap: () => onToggle(value == 'fail' ? '' : 'fail'),
        vertical: isTablet,
      );

  Widget _failurePanel() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Text(
            photoRequired
                ? '⚠ Photo required'
                : '⚠ Note or photo required',
            style: inspInterStyle(11, FontWeight.w600, kInspFailText),
          ),
          const SizedBox(height: 12),
          _FailureEvidencePanel(
            note: note,
            photos: photos,
            onNoteChanged: onNoteChanged,
            onPhotosChanged: onPhotosChanged,
            photoRequired: photoRequired,
            maxPhotos: maxPhotos,
            isTablet: isTablet,
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    if (isTablet) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Side-by-side Pass / Fail on tablet ────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _passButton()),
              const SizedBox(width: 16),
              Expanded(child: _failButton()),
            ],
          ),
          if (value == 'fail') _failurePanel(),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _passButton(),

        // ── "or" divider ─────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              const Expanded(child: Divider(color: Color(0xFFF1F5F9), thickness: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'OR',
                  style: inspInterStyle(11, FontWeight.w700, const Color(0xFFCBD5E1))
                      .copyWith(letterSpacing: 1.5),
                ),
              ),
              const Expanded(child: Divider(color: Color(0xFFF1F5F9), thickness: 1)),
            ],
          ),
        ),

        _failButton(),

        if (value == 'fail') _failurePanel(),
      ],
    );
  }
}

// ─── _ChoiceButton ──────────────────────────────────────────────────────────

class _ChoiceButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final bool dimmed;
  final List<Color> activeGradient;
  final Color inactiveBorderColor;
  final Color inactiveIconBg;
  final Color inactiveIconColor;
  final bool disabled;
  final VoidCallback onTap;
  final bool vertical;

  const _ChoiceButton({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.dimmed,
    required this.activeGradient,
    required this.inactiveBorderColor,
    required this.inactiveIconBg,
    required this.inactiveIconColor,
    required this.disabled,
    required this.onTap,
    this.vertical = false,
  });

  Widget _radioDot() => Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? Colors.white.withValues(alpha: 0.5)
                : inactiveBorderColor,
            width: 2,
          ),
          color: selected
              ? Colors.white.withValues(alpha: 0.25)
              : Colors.transparent,
        ),
        child: selected
            ? Center(
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              )
            : null,
      );

  Widget _iconBox(double size, double iconSize) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withValues(alpha: 0.2)
              : inactiveIconBg,
          borderRadius: BorderRadius.circular(size > 50 ? 20 : 14),
        ),
        child: Icon(
          icon,
          size: iconSize,
          color: selected ? Colors.white : inactiveIconColor,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      gradient: selected
          ? LinearGradient(
              colors: activeGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : null,
      color: selected ? null : Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: selected
            ? Colors.transparent
            : (dimmed ? kInspBorder : inactiveBorderColor),
        width: 2,
      ),
      boxShadow: selected
          ? [
              BoxShadow(
                color: activeGradient.first.withValues(alpha: 0.3),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ]
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
    );

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: dimmed ? 0.45 : 1.0,
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: vertical
              ? const EdgeInsets.symmetric(horizontal: 24, vertical: 40)
              : const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: decoration,
          child: vertical ? _verticalContent() : _horizontalContent(),
        ),
      ),
    );
  }

  Widget _horizontalContent() => Row(
        children: [
          _iconBox(44, 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: inspInterStyle(
                    16,
                    FontWeight.w800,
                    selected ? Colors.white : kInspPrimaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: inspInterStyle(
                    12,
                    FontWeight.w400,
                    selected
                        ? Colors.white.withValues(alpha: 0.65)
                        : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _radioDot(),
        ],
      );

  Widget _verticalContent() => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _iconBox(64, 28),
          const SizedBox(height: 16),
          Text(
            label,
            style: inspInterStyle(
              20,
              FontWeight.w800,
              selected ? Colors.white : kInspPrimaryText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: inspInterStyle(
              13,
              FontWeight.w400,
              selected
                  ? Colors.white.withValues(alpha: 0.65)
                  : const Color(0xFF94A3B8),
            ),
          ),
        ],
      );
}

// ─── _FailureEvidencePanel ──────────────────────────────────────────────────

class _FailureEvidencePanel extends StatefulWidget {
  final String note;
  final List<Uint8List> photos;
  final void Function(String) onNoteChanged;
  final void Function(List<Uint8List>) onPhotosChanged;
  final bool photoRequired;
  final int maxPhotos;
  final bool isTablet;

  const _FailureEvidencePanel({
    required this.note,
    required this.onNoteChanged,
    required this.photos,
    required this.onPhotosChanged,
    this.photoRequired = false,
    this.maxPhotos = 5,
    this.isTablet = false,
  });

  @override
  State<_FailureEvidencePanel> createState() => _FailureEvidencePanelState();
}

class _FailureEvidencePanelState extends State<_FailureEvidencePanel> {
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

  Widget _noteField() {
    final field = TextField(
      controller: _ctrl,
      onChanged: widget.onNoteChanged,
      maxLines: widget.isTablet ? null : 3,
      expands: widget.isTablet,
      textAlignVertical: TextAlignVertical.top,
      style: inspInterStyle(13, FontWeight.w400, kInspPrimaryText),
      decoration: InputDecoration(
        hintText: 'Describe the issue…',
        hintStyle: inspInterStyle(13, FontWeight.w400, kInspSecText),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kInspBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kInspBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kInspPrimary, width: 1.5),
        ),
      ),
    );
    return widget.isTablet ? field : field;
  }

  Widget _photoBox() => PhotoCaptureBox(
        photos: widget.photos,
        maxPhotos: widget.maxPhotos,
        borderColor: kInspBorder,
        accentColor: const Color(0xFF0284C7),
        accentBgColor: const Color(0xFFE0F2FE),
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
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ISSUE DETAILS',
          style: inspInterStyle(10, FontWeight.w700, const Color(0xFF64748B))
              .copyWith(letterSpacing: 1.2),
        ),
        const SizedBox(height: 8),
        if (widget.isTablet)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _noteField()),
                const SizedBox(width: 16),
                Expanded(child: _photoBox()),
              ],
            ),
          )
        else ...[
          _noteField(),
          const SizedBox(height: 10),
          _photoBox(),
        ],
      ],
    );
  }
}

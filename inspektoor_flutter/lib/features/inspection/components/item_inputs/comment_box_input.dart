import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../common/components/ocr_camera_screen.dart';
import '../../inspection_tokens.dart';

// ─── InspectionCommentBoxInput ───────────────────────────────────────────────
//
// Rich comment entry with:
//   • Styled textarea with character count ring
//   • Quick-fill chip row (hardcoded presets; will pull from history later)
//   • "Comment" badge + optional OCR badge
//   • Optional OCR camera with source pill preview
//   • Full-width section layout (no InspectionInputCard wrapper)

class InspectionCommentBoxInput extends StatefulWidget {
  final TextEditingController controller;
  final String placeholder;
  final int? maxLength;
  final bool disabled;
  final bool ocrEnabled;
  final Uint8List? ocrImageBytes;
  final ValueChanged<Uint8List?>? onOcrImageChanged;
  final List<String> quickFills;
  final bool isTablet;

  const InspectionCommentBoxInput({
    super.key,
    required this.controller,
    this.placeholder = 'Add your comments here…',
    this.maxLength,
    this.disabled = false,
    this.ocrEnabled = false,
    this.ocrImageBytes,
    this.onOcrImageChanged,
    this.quickFills = const [
      'No issues noted',
      'Minor wear observed',
      'Requires follow-up',
      'Refer to workshop',
    ],
    this.isTablet = false,
  });

  @override
  State<InspectionCommentBoxInput> createState() =>
      _InspectionCommentBoxInputState();
}

class _InspectionCommentBoxInputState extends State<InspectionCommentBoxInput> {
  bool _showOcrPreview = false;

  bool get _hasValue => widget.controller.text.trim().isNotEmpty;

  int get _charCount => widget.controller.text.length;
  int get _maxChars => widget.maxLength ?? 300;
  double get _pct => _maxChars > 0 ? (_charCount / _maxChars).clamp(0.0, 1.0) : 0.0;

  Color get _ringColor => _pct > 0.9 ? kInspWarning : const Color(0xFF0EA5E9);
  Color get _countColor => _pct > 0.9 ? kInspWarning : const Color(0xFF94A3B8);

  // ── OCR via custom camera screen ──────────────────────────────────────────

  Future<void> _runOcr() async {
    final result = await Navigator.of(context).push<OcrCaptureResult>(
      MaterialPageRoute(
        builder: (_) => const OcrCameraScreen(
          extractionMode: OcrExtractionMode.freeText,
          instruction: 'Place the text inside the box above',
          largeViewfinder: true,
        ),
      ),
    );
    if (result == null || !mounted) return;

    if (result.extractedText != null) {
      final text = result.extractedText!.trim();
      final limited = widget.maxLength != null
          ? text.substring(0, text.length.clamp(0, widget.maxLength!))
          : text;
      widget.controller.text = limited;
      widget.controller.selection = TextSelection.fromPosition(
        TextPosition(offset: limited.length),
      );
    }

    widget.onOcrImageChanged?.call(result.imageBytes);
  }

  void _clearOcrImage() {
    widget.onOcrImageChanged?.call(null);
    widget.controller.clear();
    _showOcrPreview = false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── OCR badge ────────────────────────────────────────────────────
        if (widget.ocrEnabled) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.camera_alt_outlined,
                      size: 10, color: Color(0xFF16A34A)),
                  const SizedBox(width: 4),
                  Text(
                    'OCR enabled',
                    style: inspInterStyle(
                        12, FontWeight.w800, const Color(0xFF16A34A)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // ── OCR source pill ────────────────────────────────────────────
        if (widget.ocrEnabled && widget.ocrImageBytes != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _showOcrPreview = !_showOcrPreview),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      widget.ocrImageBytes!,
                      width: 36,
                      height: 26,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.camera_alt_outlined,
                    size: 9, color: Color(0xFF94A3B8)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Scanned from image',
                    style: inspInterStyle(
                        12, FontWeight.w600, const Color(0xFF94A3B8)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: widget.disabled ? null : _runOcr,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.camera_alt_outlined,
                            size: 9, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Text(
                          'Rescan',
                          style: inspInterStyle(
                              12, FontWeight.w700, const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: _clearOcrImage,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Icon(Icons.close,
                        size: 10, color: Color(0xFF94A3B8)),
                  ),
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _showOcrPreview
                ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        widget.ocrImageBytes!,
                        width: double.infinity,
                        height: 160,
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 12),
        ],

        // ── Textarea with camera icon inside ─────────────────────────
        Stack(
          children: [
            TextField(
              controller: widget.controller,
              enabled: !widget.disabled,
              maxLines: widget.isTablet ? 10 : 6,
              maxLength: widget.maxLength,
              style: inspInterStyle(13, FontWeight.w400, const Color(0xFF334155))
                  .copyWith(height: 1.6),
              decoration: InputDecoration(
                hintText: widget.placeholder,
                hintStyle:
                    inspInterStyle(13, FontWeight.w400, const Color(0xFFCBD5E1))
                        .copyWith(height: 1.6),
                counterText: '',
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.fromLTRB(
                  14, 14, widget.ocrEnabled ? 48 : 14, 44),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(
                    color: _hasValue ? const Color(0xFFBAE6FD) : kInspBorder,
                    width: 1.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(
                    color: _hasValue ? const Color(0xFFBAE6FD) : kInspBorder,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide:
                      const BorderSide(color: kInspPrimary, width: 1.5),
                ),
              ),
            ),
            // Camera icon — top-right corner of textarea
            if (widget.ocrEnabled)
              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  onTap: widget.disabled ? null : _runOcr,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: widget.ocrImageBytes != null
                          ? const Color(0xFFF1F5F9)
                          : const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: widget.ocrImageBytes != null
                            ? const Color(0xFFE2E8F0)
                            : const Color(0xFF7DD3FC),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.camera_alt_outlined,
                        size: 15,
                        color: widget.ocrImageBytes != null
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF0EA5E9),
                      ),
                    ),
                  ),
                ),
              ),
            // Char count + ring indicator
            Positioned(
              bottom: 10,
              right: 12,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$_charCount/$_maxChars',
                    style: inspInterStyle(12, FontWeight.w600, _countColor),
                  ),
                  const SizedBox(width: 4),
                  CustomPaint(
                    size: const Size(16, 16),
                    painter: _CharRingPainter(
                      progress: _pct,
                      color: _ringColor,
                      bgColor: const Color(0xFFE2E8F0),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // ── OCR hint text ──────────────────────────────────────────────
        if (widget.ocrEnabled) ...[
          const SizedBox(height: 6),
          Text(
            'Tap camera to scan and auto-fill value',
            textAlign: TextAlign.center,
            style: inspInterStyle(12, FontWeight.w400, const Color(0xFF94A3B8)),
          ),
        ],
        const SizedBox(height: 16),

        // ── Quick fill chips ───────────────────────────────────────────
        if (widget.quickFills.isNotEmpty) ...[
          Text(
            'QUICK FILL',
            style: inspInterStyle(12, FontWeight.w700, const Color(0xFF94A3B8))
                .copyWith(letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: widget.quickFills.map((chip) {
              final selected = widget.controller.text.trim() == chip;
              return GestureDetector(
                onTap: widget.disabled
                    ? null
                    : () {
                        widget.controller.text = chip;
                        widget.controller.selection =
                            TextSelection.fromPosition(
                          TextPosition(offset: chip.length),
                        );
                      },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFFEFF6FF)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFFBAE6FD)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Text(
                    chip,
                    style: inspInterStyle(
                      12,
                      FontWeight.w600,
                      selected
                          ? const Color(0xFF0EA5E9)
                          : const Color(0xFF475569),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

// ─── Character count ring painter ────────────────────────────────────────────

class _CharRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color bgColor;

  _CharRingPainter({
    required this.progress,
    required this.color,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 1;
    const strokeWidth = 2.0;

    // Background ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = bgColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Progress arc
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_CharRingPainter oldDelegate) =>
      progress != oldDelegate.progress || color != oldDelegate.color;
}

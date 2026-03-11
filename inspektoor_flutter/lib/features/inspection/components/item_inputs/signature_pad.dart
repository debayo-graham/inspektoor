import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

import '../../../../common/components/dashed_border_painter.dart';
import '../../inspection_tokens.dart';

// ─── InspectionSignaturePad ───────────────────────────────────────────────────
//
// Three-state signature widget:
//   1. **Empty** — dashed border, pen icon, "Tap to draw signature".
//   2. **Drawing** — live canvas with baseline guide, Clear + Save buttons.
//   3. **Saved** — rendered PNG image, green "Signature captured" bar,
//      Re-sign link to discard and re-draw.
//
// When navigating back, `initialBytes` restores the saved state so the
// user sees their actual signature instead of a blank canvas.
// No FlutterFlow imports.

class InspectionSignaturePad extends StatefulWidget {
  final bool submitting;
  final Uint8List? initialBytes;
  final void Function(Uint8List? bytes) onCapture;
  final bool isTablet;
  final String inspectorName;

  const InspectionSignaturePad({
    super.key,
    required this.submitting,
    this.initialBytes,
    required this.onCapture,
    this.isTablet = false,
    this.inspectorName = '',
  });

  @override
  State<InspectionSignaturePad> createState() => _InspectionSignaturePadState();
}

enum _SigState { empty, drawing, saved }

class _InspectionSignaturePadState extends State<InspectionSignaturePad> {
  SignatureController? _ctrl;
  bool _hasStrokes = false;
  Timer? _debounce;

  late _SigState _state;
  Uint8List? _savedBytes;

  @override
  void initState() {
    super.initState();
    if (widget.initialBytes != null) {
      _state = _SigState.saved;
      _savedBytes = widget.initialBytes;
    } else {
      _state = _SigState.empty;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl?.removeListener(_onDraw);
    _ctrl?.dispose();
    super.dispose();
  }

  // ── Controller lifecycle ──────────────────────────────────────────────────

  void _ensureController() {
    if (_ctrl != null) return;
    _ctrl = SignatureController(
      penStrokeWidth: 2.5,
      penColor: kInspPrimaryText,
      exportBackgroundColor: Colors.white,
    );
    _ctrl!.addListener(_onDraw);
  }

  void _onDraw() {
    final hasStrokes = _ctrl?.isNotEmpty ?? false;
    if (hasStrokes != _hasStrokes) setState(() => _hasStrokes = hasStrokes);

    _debounce?.cancel();
    if (hasStrokes) {
      _debounce = Timer(const Duration(milliseconds: 600), _autoCapture);
    }
  }

  Future<void> _autoCapture() async {
    if (_ctrl == null || _ctrl!.isEmpty) return;
    final bytes = await _ctrl!.toPngBytes();
    if (bytes != null && mounted) {
      _savedBytes = bytes;
      widget.onCapture(bytes);
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  void _startDrawing() {
    _ensureController();
    _ctrl!.clear();
    setState(() {
      _state = _SigState.drawing;
      _hasStrokes = false;
    });
  }

  Future<void> _saveSignature() async {
    if (_ctrl == null || _ctrl!.isEmpty) return;
    final bytes = await _ctrl!.toPngBytes();
    if (bytes != null && mounted) {
      _savedBytes = bytes;
      widget.onCapture(bytes);
      setState(() => _state = _SigState.saved);
    }
  }

  void _clearCanvas() {
    _debounce?.cancel();
    _ctrl?.clear();
    setState(() => _hasStrokes = false);
  }

  void _resign() {
    _savedBytes = null;
    widget.onCapture(null);
    _startDrawing();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  Widget _infoPanel() {
    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kInspBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('INSPECTOR',
              style: inspInterStyle(
                      10, FontWeight.w700, const Color(0xFF94A3B8))
                  .copyWith(letterSpacing: 1.0)),
          const SizedBox(height: 4),
          Text(
            widget.inspectorName.isNotEmpty
                ? widget.inspectorName
                : 'Not specified',
            style: inspInterStyle(14, FontWeight.w600, kInspPrimaryText),
          ),
          const SizedBox(height: 16),
          Text('DATE',
              style: inspInterStyle(
                      10, FontWeight.w700, const Color(0xFF94A3B8))
                  .copyWith(letterSpacing: 1.0)),
          const SizedBox(height: 4),
          Text(dateStr,
              style: inspInterStyle(14, FontWeight.w600, kInspPrimaryText)),
          const SizedBox(height: 16),
          Text(
            'By signing, you confirm that the inspection has been completed accurately.',
            style: inspInterStyle(11, FontWeight.w400, const Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sigWidget = switch (_state) {
      _SigState.empty => _buildEmpty(),
      _SigState.drawing => _buildDrawing(),
      _SigState.saved => _buildSaved(),
    };

    if (!widget.isTablet) return sigWidget;

    // Tablet: 2/3 canvas + 1/3 info panel
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: sigWidget),
        const SizedBox(width: 24),
        Expanded(flex: 1, child: _infoPanel()),
      ],
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────

  Widget _buildEmpty() {
    return GestureDetector(
      onTap: _startDrawing,
      child: CustomPaint(
        foregroundPainter: DashedBorderPainter(color: kInspBorder),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 180,
            width: double.infinity,
            color: kInspSlate,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.edit_outlined,
                    color: kInspSecText.withValues(alpha: 0.4), size: 28),
                const SizedBox(height: 10),
                Text(
                  'Tap to draw signature',
                  style: inspInterStyle(
                      13, FontWeight.w600, kInspSecText.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Drawing state ─────────────────────────────────────────────────────────

  Widget _buildDrawing() {
    _ensureController();
    final borderColor = _hasStrokes
        ? const Color(0xFFBAE6FD) // sky-200
        : kInspBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 220,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: _hasStrokes
                ? [
                    BoxShadow(
                      color: const Color(0xFF0EA5E9).withValues(alpha: 0.08),
                      blurRadius: 0,
                      spreadRadius: 3,
                    )
                  ]
                : null,
          ),
          clipBehavior: Clip.hardEdge,
          child: Stack(
            children: [
              // Baseline guide
              Positioned(
                left: 20,
                right: 20,
                bottom: 32,
                child: CustomPaint(
                  size: const Size(double.infinity, 1),
                  painter: _BaselineGuidePainter(),
                ),
              ),
              // "Sign here" label
              Positioned(
                left: 20,
                bottom: 10,
                child: Text(
                  'Sign here',
                  style: inspInterStyle(
                      10, FontWeight.w500, kInspSecText.withValues(alpha: 0.35)),
                ),
              ),
              // Placeholder hint (before first stroke)
              if (!_hasStrokes)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_outlined,
                          color: kInspSecText.withValues(alpha: 0.25), size: 28),
                      const SizedBox(height: 6),
                      Text(
                        'Draw your signature',
                        style: inspInterStyle(13, FontWeight.w600,
                            kInspSecText.withValues(alpha: 0.3)),
                      ),
                    ],
                  ),
                ),
              // Canvas
              Signature(
                controller: _ctrl!,
                backgroundColor: Colors.transparent,
              ),
            ],
          ),
        ),

        // ── Clear / Save row ──────────────────────────────────────────────────
        const SizedBox(height: 10),
        Row(
          children: [
            // Clear button
            GestureDetector(
              onTap: _clearCanvas,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: kInspSlate,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kInspBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded,
                        color: kInspSecText, size: 13),
                    const SizedBox(width: 5),
                    Text('Clear',
                        style:
                            inspInterStyle(12, FontWeight.w600, kInspSecText)),
                  ],
                ),
              ),
            ),
            const Spacer(),
            // Save button
            GestureDetector(
              onTap: _hasStrokes && !widget.submitting
                  ? _saveSignature
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: _hasStrokes
                      ? const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: _hasStrokes ? null : kInspBorder,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _hasStrokes
                      ? [
                          BoxShadow(
                            color: const Color(0xFF10B981)
                                .withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_rounded,
                        color: _hasStrokes ? Colors.white : kInspSecText,
                        size: 14),
                    const SizedBox(width: 5),
                    Text(
                      'Save signature',
                      style: inspInterStyle(
                        12,
                        FontWeight.w700,
                        _hasStrokes ? Colors.white : kInspSecText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Saved state ───────────────────────────────────────────────────────────

  Widget _buildSaved() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Signature image card ────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kInspPassBorder, width: 2),
            boxShadow: [
              BoxShadow(
                color: kInspPassFill.withValues(alpha: 0.08),
                blurRadius: 0,
                spreadRadius: 3,
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            children: [
              // Signature image
              Container(
                height: 160,
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: _savedBytes != null
                    ? Image.memory(
                        _savedBytes!,
                        fit: BoxFit.contain,
                      )
                    : const SizedBox.shrink(),
              ),
              // Green confirmation bar
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFFF0FDF4), // green-50
                  border: Border(
                    top: BorderSide(color: Color(0xFFDCFCE7), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded,
                          color: Colors.white, size: 11),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Signature captured',
                      style: inspInterStyle(
                          12, FontWeight.w700, const Color(0xFF047857)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Re-sign link ────────────────────────────────────────────────────
        const SizedBox(height: 10),
        GestureDetector(
          onTap: widget.submitting ? null : _resign,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.refresh_rounded,
                  color: kInspSecText.withValues(alpha: 0.6), size: 13),
              const SizedBox(width: 5),
              Text(
                'Re-sign',
                style: inspInterStyle(
                    12, FontWeight.w600, kInspSecText.withValues(alpha: 0.6)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── _BaselineGuidePainter ────────────────────────────────────────────────────

class _BaselineGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const double dashWidth = 6.0;
    const double dashGap = 4.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

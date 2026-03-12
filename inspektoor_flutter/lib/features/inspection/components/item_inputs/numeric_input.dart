import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../common/components/ocr_camera_screen.dart';
import '../../inspection_tokens.dart';

// ─── InspectionNumericInput ──────────────────────────────────────────────────
//
// Rich numeric entry with:
//   • Big value display card (colour-coded by range)
//   • Range hint bar (when min/max are configured)
//   • Neutral text input with unit suffix
//   • Tap display → focus input
//   • Optional OCR camera with viewfinder overlay

class InspectionNumericInput extends StatefulWidget {
  final TextEditingController controller;
  final String placeholder;
  final String? unit;
  final num? min;
  final num? max;
  final bool disabled;
  final bool ocrEnabled;
  final Uint8List? ocrImageBytes;
  final ValueChanged<Uint8List?>? onOcrImageChanged;
  final bool isTablet;

  const InspectionNumericInput({
    super.key,
    required this.controller,
    this.placeholder = 'Enter value',
    this.unit,
    this.min,
    this.max,
    this.disabled = false,
    this.ocrEnabled = false,
    this.ocrImageBytes,
    this.onOcrImageChanged,
    this.isTablet = false,
  });

  @override
  State<InspectionNumericInput> createState() => _InspectionNumericInputState();
}

class _InspectionNumericInputState extends State<InspectionNumericInput> {
  final FocusNode _focusNode = FocusNode();
  bool _showOcrPreview = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  bool get _hasRange => widget.min != null || widget.max != null;

  num? get _parsed => num.tryParse(widget.controller.text.trim());

  bool get _hasValue => _parsed != null;

  bool get _inRange {
    final v = _parsed;
    if (v == null) return false;
    if (widget.min != null && v < widget.min!) return false;
    if (widget.max != null && v > widget.max!) return false;
    return true;
  }

  String get _rangeLabel {
    if (widget.min != null && widget.max != null) {
      return '${_fmt(widget.min!)} – ${_fmt(widget.max!)}';
    }
    if (widget.min != null) return '≥ ${_fmt(widget.min!)}';
    return '≤ ${_fmt(widget.max!)}';
  }

  String _fmt(num n) {
    if (n == n.toInt()) return n.toInt().toString();
    return n.toString();
  }

  // Colours for the value display only.
  // When no range is configured, use a dark card style (like alphanumeric).
  Color get _displayBg {
    if (!_hasRange) {
      return _hasValue ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    }
    if (!_hasValue) return const Color(0xFFF1F5F9);
    return _inRange ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2);
  }

  Color get _displayBorder {
    if (!_hasRange) {
      return _hasValue ? const Color(0xFF0EA5E9) : const Color(0xFFE2E8F0);
    }
    if (!_hasValue) return const Color(0xFFE2E8F0);
    return _inRange ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5);
  }

  Color get _valueColor {
    if (!_hasRange) {
      return _hasValue ? Colors.white : const Color(0xFFCBD5E1);
    }
    if (!_hasValue) return const Color(0xFFCBD5E1);
    return _inRange ? kInspSuccess : kInspError;
  }

  Color get _unitColor {
    if (!_hasRange) {
      return _hasValue
          ? Colors.white.withValues(alpha: 0.6)
          : const Color(0xFF94A3B8);
    }
    if (!_hasValue) return const Color(0xFF94A3B8);
    return _inRange ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5);
  }

  // ── OCR via custom camera screen ──────────────────────────────────────────

  Future<void> _runOcr() async {
    final result = await Navigator.of(context).push<OcrCaptureResult>(
      MaterialPageRoute(builder: (_) => const OcrCameraScreen()),
    );
    if (result == null || !mounted) return;

    // Auto-populate the extracted value.
    if (result.extractedText != null) {
      widget.controller.text = result.extractedText!;
      widget.controller.selection = TextSelection.fromPosition(
        TextPosition(offset: result.extractedText!.length),
      );
    }

    // Store the cropped image for preview.
    widget.onOcrImageChanged?.call(result.imageBytes);
  }

  void _clearOcrImage() {
    widget.onOcrImageChanged?.call(null);
    widget.controller.clear();
  }

  // ── Badges (OCR + range) ──────────────────────────────────────────────────

  Widget _ocrBadge() => Align(
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
                    9, FontWeight.w800, const Color(0xFF16A34A)),
              ),
            ],
          ),
        ),
      );

  Widget _rangeBadge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F9FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFBAE6FD)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline_rounded,
                size: 14, color: Color(0xFF0EA5E9)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Acceptable range: $_rangeLabel${widget.unit != null ? ' ${widget.unit}' : ''}',
                style: inspInterStyle(
                    11, FontWeight.w600, const Color(0xFF0284C7)),
              ),
            ),
          ],
        ),
      );

  // ── Big value display card ────────────────────────────────────────────────

  Widget _displayCard() => GestureDetector(
        onTap: () => _focusNode.requestFocus(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: _displayBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _displayBorder, width: 2),
            boxShadow: !_hasRange && _hasValue
                ? [
                    BoxShadow(
                      color: const Color(0xFF0EA5E9).withValues(alpha: 0.2),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (context, constraints) => FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth * 2,
                    ),
                    child: Text.rich(
                      TextSpan(children: [
                        TextSpan(
                          // Zero-width spaces let Flutter break between any two digits.
                          text: (_hasValue
                                  ? widget.controller.text.trim()
                                  : '0')
                              .split('')
                              .join('\u200B'),
                          style: inspInterStyle(48, FontWeight.w800, _valueColor),
                        ),
                        if (widget.unit != null)
                          TextSpan(
                            text: ' ${widget.unit!}',
                            style: inspInterStyle(18, FontWeight.w700, _unitColor),
                          ),
                      ]),
                      textAlign: TextAlign.center,
                      softWrap: true,
                    ),
                  ),
                ),
              ),
              if (_hasRange && _hasValue) ...[
                const SizedBox(height: 4),
                _inRange
                    ? Text(
                        '✓ Within range',
                        textAlign: TextAlign.center,
                        style: inspInterStyle(11, FontWeight.w700, kInspSuccess),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              size: 12, color: Color(0xFFFCA5A5)),
                          const SizedBox(width: 4),
                          Text(
                            'Out of acceptable range',
                            style: inspInterStyle(
                                11, FontWeight.w700, const Color(0xFFFCA5A5)),
                          ),
                        ],
                      ),
              ],
            ],
          ),
        ),
      );

  // ── Text input with OCR button ────────────────────────────────────────────

  Widget _textInput() => Stack(
        alignment: Alignment.centerRight,
        children: [
          TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            enabled: !widget.disabled,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.\-]')),
            ],
            textAlign: TextAlign.center,
            style: inspInterStyle(20, FontWeight.w700, kInspPrimaryText),
            decoration: InputDecoration(
              hintText: widget.placeholder,
              hintStyle: inspInterStyle(
                  16, FontWeight.w400, const Color(0xFF94A3B8)),
              suffixText: widget.unit,
              suffixStyle: inspInterStyle(
                  14, FontWeight.w500, const Color(0xFF94A3B8)),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.fromLTRB(
                16,
                14,
                widget.ocrEnabled ? 52 : 16,
                14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: kInspBorder, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: kInspBorder, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: kInspPrimary, width: 2),
              ),
            ),
          ),
          if (widget.ocrEnabled)
            Positioned(
              right: 10,
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
        ],
      );

  @override
  Widget build(BuildContext context) {
    if (widget.isTablet) return _buildTabletLayout();
    return _buildMobileLayout();
  }

  Widget _buildTabletLayout() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Badges row
            if (widget.ocrEnabled || _hasRange)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    if (widget.ocrEnabled) ...[_ocrBadge(), const SizedBox(width: 8)],
                    if (_hasRange) Flexible(child: _rangeBadge()),
                  ],
                ),
              ),
            _displayCard(),
            const SizedBox(height: 20),
            if (widget.ocrEnabled && widget.ocrImageBytes != null) ...[
              _ocrSourcePill(),
              const SizedBox(height: 8),
            ],
            _textInput(),
            if (widget.ocrEnabled) ...[
              const SizedBox(height: 6),
              Text(
                'Tap camera to scan and auto-fill value',
                textAlign: TextAlign.center,
                style: inspInterStyle(
                    10, FontWeight.w400, const Color(0xFF94A3B8)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _ocrSourcePill() => Container(
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
                    10, FontWeight.w600, const Color(0xFF94A3B8)),
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
                          10, FontWeight.w700, const Color(0xFF64748B)),
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
      );

  Widget _buildMobileLayout() {
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
                        9, FontWeight.w800, const Color(0xFF16A34A)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // ── Range badge ────────────────────────────────────────────────────
        if (_hasRange) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBAE6FD)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 14, color: Color(0xFF0EA5E9)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Acceptable range: $_rangeLabel${widget.unit != null ? ' ${widget.unit}' : ''}',
                    style: inspInterStyle(
                        11, FontWeight.w600, const Color(0xFF0284C7)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ── Big value display (tap to focus input) ────────────────────────
        GestureDetector(
          onTap: () => _focusNode.requestFocus(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: _displayBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _displayBorder, width: 2),
              boxShadow: !_hasRange && _hasValue
                  ? [
                      BoxShadow(
                        color: const Color(0xFF0EA5E9).withValues(alpha: 0.2),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) => FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth * 2,
                      ),
                      child: Text.rich(
                        TextSpan(children: [
                          TextSpan(
                            text: (_hasValue
                                    ? widget.controller.text.trim()
                                    : '0')
                                .split('')
                                .join('\u200B'),
                            style: inspInterStyle(48, FontWeight.w800, _valueColor),
                          ),
                          if (widget.unit != null)
                            TextSpan(
                              text: ' ${widget.unit!}',
                              style: inspInterStyle(18, FontWeight.w700, _unitColor),
                            ),
                        ]),
                        textAlign: TextAlign.center,
                        softWrap: true,
                      ),
                    ),
                  ),
                ),
                if (_hasRange && _hasValue) ...[
                  const SizedBox(height: 4),
                  _inRange
                      ? Text(
                          '✓ Within range',
                          textAlign: TextAlign.center,
                          style: inspInterStyle(11, FontWeight.w700, kInspSuccess),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                size: 12, color: Color(0xFFFCA5A5)),
                            const SizedBox(width: 4),
                            Text(
                              'Out of acceptable range',
                              style: inspInterStyle(
                                  11, FontWeight.w700, const Color(0xFFFCA5A5)),
                            ),
                          ],
                        ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── OCR source pill (compact scanned-image indicator) ────────────
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
                // Mini thumbnail (tap to expand/collapse preview)
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
                        10, FontWeight.w600, const Color(0xFF94A3B8)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Rescan button
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
                              10, FontWeight.w700, const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Clear button
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
          // ── Expandable image preview ──────────────────────────────────
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
          const SizedBox(height: 8),
        ],

        // ── Text input with optional OCR button ───────────────────────────
        Stack(
          alignment: Alignment.centerRight,
          children: [
            TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              enabled: !widget.disabled,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.\-]')),
              ],
              textAlign: TextAlign.center,
              style: inspInterStyle(20, FontWeight.w700, kInspPrimaryText),
              decoration: InputDecoration(
                hintText: widget.placeholder,
                hintStyle: inspInterStyle(
                    16, FontWeight.w400, const Color(0xFF94A3B8)),
                suffixText: widget.unit,
                suffixStyle: inspInterStyle(
                    14, FontWeight.w500, const Color(0xFF94A3B8)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.fromLTRB(
                  16,
                  14,
                  widget.ocrEnabled ? 52 : 16,
                  14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: kInspBorder, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: kInspBorder, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      const BorderSide(color: kInspPrimary, width: 2),
                ),
              ),
            ),
            if (widget.ocrEnabled)
              Positioned(
                right: 10,
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
          ],
        ),

        // ── OCR hint text ─────────────────────────────────────────────────
        if (widget.ocrEnabled) ...[
          const SizedBox(height: 6),
          Text(
            'Tap camera to scan and auto-fill value',
            textAlign: TextAlign.center,
            style: inspInterStyle(10, FontWeight.w400, const Color(0xFF94A3B8)),
          ),
        ],
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../common/components/ocr_camera_screen.dart';
import '../../inspection_tokens.dart';

// ─── InspectionAlphanumericInput ─────────────────────────────────────────────
//
// Rich alphanumeric entry with:
//   • Dark display card showing uppercase formatted value
//   • Text input with auto-uppercase + alphanumeric-only filter
//   • Optional format pattern mask (e.g. "ABC 1234", "123-456-789")
//   • Optional OCR camera with viewfinder overlay
//   • Badges row (Alphanumeric tag + OCR enabled)

class InspectionAlphanumericInput extends StatefulWidget {
  final TextEditingController controller;
  final String placeholder;
  final int? maxLength;
  final String? formatPattern;
  final bool disabled;
  final bool ocrEnabled;
  final Uint8List? ocrImageBytes;
  final ValueChanged<Uint8List?>? onOcrImageChanged;
  final bool isTablet;

  const InspectionAlphanumericInput({
    super.key,
    required this.controller,
    this.placeholder = 'Enter value',
    this.maxLength,
    this.formatPattern,
    this.disabled = false,
    this.ocrEnabled = false,
    this.ocrImageBytes,
    this.onOcrImageChanged,
    this.isTablet = false,
  });

  @override
  State<InspectionAlphanumericInput> createState() =>
      _InspectionAlphanumericInputState();
}

class _InspectionAlphanumericInputState
    extends State<InspectionAlphanumericInput> {
  final FocusNode _focusNode = FocusNode();
  bool _showOcrPreview = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  bool get _hasPattern =>
      widget.formatPattern != null && widget.formatPattern!.isNotEmpty;

  List<_SlotType> get _slots =>
      _hasPattern ? _parsePattern(widget.formatPattern!) : const [];

  int get _effectiveMaxLength {
    if (_hasPattern) return _slots.length;
    return widget.maxLength ?? 0; // 0 = unlimited
  }

  /// The display value. With a pattern, includes separators; without, strips
  /// non-alphanumeric and uppercases.
  String get _displayValue {
    final text = widget.controller.text;
    if (!_hasPattern) {
      return text.replaceAll(RegExp(r'[^a-zA-Z0-9 \-/.]'), '').trim().toUpperCase();
    }
    return text.toUpperCase();
  }

  bool get _hasValue => _displayValue.isNotEmpty;

  bool get _isComplete {
    if (!_hasPattern) return _hasValue;
    return widget.controller.text.length == _slots.length;
  }

  // ── OCR via custom camera screen ──────────────────────────────────────────

  Future<void> _runOcr() async {
    final result = await Navigator.of(context).push<OcrCaptureResult>(
      MaterialPageRoute(
        builder: (_) => const OcrCameraScreen(
          extractionMode: OcrExtractionMode.alphanumeric,
          instruction: 'Place the text inside the box above',
        ),
      ),
    );
    if (result == null || !mounted) return;

    if (result.extractedText != null) {
      String formatted;
      if (_hasPattern) {
        formatted = _applyPattern(result.extractedText!, _slots);
      } else {
        final clean = result.extractedText!
            .replaceAll(RegExp(r'[^a-zA-Z0-9 \-/.]'), '')
            .trim()
            .toUpperCase();
        formatted = widget.maxLength != null
            ? clean.substring(0, clean.length.clamp(0, widget.maxLength!))
            : clean;
      }
      widget.controller.text = formatted;
      widget.controller.selection = TextSelection.fromPosition(
        TextPosition(offset: formatted.length),
      );
    }

    widget.onOcrImageChanged?.call(result.imageBytes);
  }

  void _clearOcrImage() {
    widget.onOcrImageChanged?.call(null);
    widget.controller.clear();
  }

  // ── Display colours ───────────────────────────────────────────────────────

  Color get _displayBg =>
      _hasValue ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);

  Color get _displayBorder =>
      _hasValue ? const Color(0xFF0EA5E9) : const Color(0xFFE2E8F0);

  Color get _valueColor =>
      _hasValue ? Colors.white : const Color(0xFFCBD5E1);

  // ── Display card ──────────────────────────────────────────────────────────

  Widget _displayCard() {
    final patternDisplay =
        _hasPattern ? widget.formatPattern!.toUpperCase() : 'ABC 1234';
    return GestureDetector(
      onTap: () => _focusNode.requestFocus(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: _displayBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _displayBorder, width: 2),
          boxShadow: _hasValue
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
          children: [
            if (!_hasValue)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  widget.placeholder.toUpperCase(),
                  style: inspInterStyle(
                          10, FontWeight.w700, const Color(0xFFCBD5E1))
                      .copyWith(letterSpacing: 1.5),
                ),
              ),
            Text(
              _hasValue ? _displayValue : patternDisplay,
              textAlign: TextAlign.center,
              style: inspInterStyle(
                _hasValue ? 30 : 20,
                FontWeight.w800,
                _valueColor,
              ).copyWith(letterSpacing: _hasValue ? 4.0 : 2.0),
            ),
            if (_hasValue) ...[
              const SizedBox(height: 4),
              if (_isComplete)
                Text(
                  '✓ Valid format',
                  style: inspInterStyle(10, FontWeight.w700,
                      Colors.white.withValues(alpha: 0.4)),
                )
              else if (_hasPattern)
                Text(
                  '${_displayValue.length} / ${_slots.length} characters',
                  style: inspInterStyle(10, FontWeight.w700,
                      Colors.white.withValues(alpha: 0.4)),
                ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Text input ──────────────────────────────────────────────────────────

  Widget _inputField() => Stack(
        alignment: Alignment.centerRight,
        children: [
          TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            enabled: !widget.disabled,
            textCapitalization: TextCapitalization.characters,
            maxLength: _effectiveMaxLength > 0 ? _effectiveMaxLength : null,
            inputFormatters: _hasPattern
                ? [_FormatPatternFormatter(_slots)]
                : [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'[a-zA-Z0-9 \-/.]')),
                    _UpperCaseFormatter(),
                  ],
            textAlign: TextAlign.center,
            style: inspInterStyle(22, FontWeight.w800, kInspPrimaryText)
                .copyWith(letterSpacing: 2.0),
            decoration: InputDecoration(
              hintText: _hasPattern
                  ? widget.formatPattern!.toUpperCase()
                  : widget.placeholder,
              hintStyle: inspInterStyle(
                  16, FontWeight.w400, const Color(0xFF94A3B8)),
              counterText: '',
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
                borderSide: BorderSide(
                  color: _hasValue ? const Color(0xFFBAE6FD) : kInspBorder,
                  width: 2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: _hasValue ? const Color(0xFFBAE6FD) : kInspBorder,
                  width: 2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: kInspPrimary, width: 2),
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

  // ── Badges row ──────────────────────────────────────────────────────────

  Widget _badgesRow() => Row(
        children: [
          if (widget.ocrEnabled) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            const SizedBox(width: 6),
          ],
          if (_hasPattern)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.grid_view_rounded,
                      size: 10, color: Color(0xFF0284C7)),
                  const SizedBox(width: 4),
                  Text(
                    'Format: ${widget.formatPattern!.toUpperCase()}',
                    style: inspInterStyle(
                        9, FontWeight.w800, const Color(0xFF0284C7)),
                  ),
                ],
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
            if (widget.ocrEnabled || _hasPattern) ...[
              _badgesRow(),
              const SizedBox(height: 12),
            ],
            _displayCard(),
            const SizedBox(height: 20),
            // ── OCR source pill ──────────────────────────────────────────
            if (widget.ocrEnabled && widget.ocrImageBytes != null) ...[
              _ocrSourcePill(),
              const SizedBox(height: 8),
            ],
            _inputField(),
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

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.ocrEnabled || _hasPattern) ...[
          _badgesRow(),
          const SizedBox(height: 12),
        ],
        _displayCard(),
        const SizedBox(height: 16),
        // ── OCR source pill ────────────────────────────────────────────────
        if (widget.ocrEnabled && widget.ocrImageBytes != null) ...[
          _ocrSourcePill(),
          const SizedBox(height: 8),
        ],
        _inputField(),
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
              onTap: () =>
                  setState(() => _showOcrPreview = !_showOcrPreview),
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
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
}

// ─── Slot types for format pattern ──────────────────────────────────────────

enum _SlotKind { letter, digit, separator }

class _SlotType {
  final _SlotKind kind;
  final String char; // only meaningful for separator
  const _SlotType.letter() : kind = _SlotKind.letter, char = '';
  const _SlotType.digit() : kind = _SlotKind.digit, char = '';
  const _SlotType.separator(this.char) : kind = _SlotKind.separator;
}

/// Parses a format pattern string into a list of slot types.
/// Letters (A-Z) → letter slot, Digits (0-9) → digit slot,
/// everything else (space, dash, slash, dot) → separator.
List<_SlotType> _parsePattern(String pattern) {
  final slots = <_SlotType>[];
  for (final c in pattern.toUpperCase().split('')) {
    if (RegExp(r'[A-Z]').hasMatch(c)) {
      slots.add(const _SlotType.letter());
    } else if (RegExp(r'[0-9]').hasMatch(c)) {
      slots.add(const _SlotType.digit());
    } else {
      slots.add(_SlotType.separator(c));
    }
  }
  return slots;
}

/// Takes raw OCR/pasted text and reformats it to match the pattern slots.
/// Extracts only letters and digits from input, then maps them into the
/// pattern, inserting separators automatically.
String _applyPattern(String raw, List<_SlotType> slots) {
  // Extract only letters and digits from raw input
  final chars = raw.toUpperCase().split('').where(
      (c) => RegExp(r'[A-Z0-9]').hasMatch(c)).toList();
  final buf = StringBuffer();
  int ci = 0; // index into chars
  for (final slot in slots) {
    if (ci >= chars.length) break;
    if (slot.kind == _SlotKind.separator) {
      buf.write(slot.char);
      continue; // separator doesn't consume a user char
    }
    final c = chars[ci];
    if (slot.kind == _SlotKind.letter && RegExp(r'[A-Z]').hasMatch(c)) {
      buf.write(c);
      ci++;
    } else if (slot.kind == _SlotKind.digit && RegExp(r'[0-9]').hasMatch(c)) {
      buf.write(c);
      ci++;
    } else {
      // Mismatch — skip this input char and try the next
      ci++;
      // Re-try the same slot with the next char by not advancing the slot
      // But since we're iterating slots, we need a different approach.
      // For simplicity, just stop here.
      break;
    }
  }
  return buf.toString();
}

// ─── Format pattern input formatter ─────────────────────────────────────────

class _FormatPatternFormatter extends TextInputFormatter {
  final List<_SlotType> slots;
  _FormatPatternFormatter(this.slots);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Extract raw user characters (letters + digits only) from new text
    final rawChars = newValue.text
        .toUpperCase()
        .split('')
        .where((c) => RegExp(r'[A-Z0-9]').hasMatch(c))
        .toList();

    final buf = StringBuffer();
    int ci = 0; // index into rawChars

    for (int si = 0; si < slots.length && ci < rawChars.length; si++) {
      final slot = slots[si];
      if (slot.kind == _SlotKind.separator) {
        buf.write(slot.char);
        continue; // separator doesn't consume a user char
      }
      final c = rawChars[ci];
      if (slot.kind == _SlotKind.letter && RegExp(r'[A-Z]').hasMatch(c)) {
        buf.write(c);
        ci++;
      } else if (slot.kind == _SlotKind.digit &&
          RegExp(r'[0-9]').hasMatch(c)) {
        buf.write(c);
        ci++;
      } else {
        // Character doesn't match slot type — stop accepting input here
        break;
      }
    }

    final formatted = buf.toString();
    // Clamp cursor to end of formatted text
    final cursorPos = formatted.length;
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorPos),
    );
  }
}

// ─── UpperCase formatter ─────────────────────────────────────────────────────

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

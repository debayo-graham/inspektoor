import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

import '../../inspection_tokens.dart';

// ─── InspectionSignaturePad ───────────────────────────────────────────────────
//
// Drawing canvas for signature capture inside an inspection step.
// Exports a PNG Uint8List via [onCapture] when the inspector taps "Done".
// No FlutterFlow imports.

class InspectionSignaturePad extends StatefulWidget {
  final bool submitting;
  final void Function(Uint8List bytes) onCapture;

  const InspectionSignaturePad({
    super.key,
    required this.submitting,
    required this.onCapture,
  });

  @override
  State<InspectionSignaturePad> createState() => _InspectionSignaturePadState();
}

class _InspectionSignaturePadState extends State<InspectionSignaturePad> {
  late final SignatureController _ctrl;
  bool _hasStrokes = false;

  @override
  void initState() {
    super.initState();
    _ctrl = SignatureController(
      penStrokeWidth: 2.5,
      penColor: kInspPrimaryText,
      exportBackgroundColor: Colors.white,
    );
    _ctrl.addListener(_onDraw);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onDraw);
    _ctrl.dispose();
    super.dispose();
  }

  void _onDraw() {
    final hasStrokes = _ctrl.isNotEmpty;
    if (hasStrokes != _hasStrokes) setState(() => _hasStrokes = hasStrokes);
  }

  void _clear() {
    _ctrl.clear();
    setState(() => _hasStrokes = false);
  }

  Future<void> _done() async {
    if (_ctrl.isEmpty) return;
    final bytes = await _ctrl.toPngBytes();
    if (bytes != null) widget.onCapture(bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Canvas ─────────────────────────────────────────────────────────
        Container(
          height: 220,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kInspBorder, width: 1.5),
          ),
          clipBehavior: Clip.hardEdge,
          child: Signature(
            controller: _ctrl,
            backgroundColor: Colors.white,
          ),
        ),

        // ── Hint text ──────────────────────────────────────────────────────
        const SizedBox(height: 8),
        Text(
          'Sign in the box above',
          textAlign: TextAlign.center,
          style: inspInterStyle(13, FontWeight.w400, kInspSecText),
        ),

        // ── Action buttons ─────────────────────────────────────────────────
        const SizedBox(height: 16),
        Row(
          children: [
            // Clear
            Expanded(
              child: OutlinedButton(
                onPressed: widget.submitting ? null : _clear,
                style: OutlinedButton.styleFrom(
                  foregroundColor: kInspPrimaryText,
                  side: const BorderSide(color: kInspBorder, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: inspInterStyle(15, FontWeight.w600, kInspPrimaryText),
                ),
                child: const Text('Clear'),
              ),
            ),
            const SizedBox(width: 12),
            // Done
            Expanded(
              child: ElevatedButton(
                onPressed:
                    (widget.submitting || !_hasStrokes) ? null : _done,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kInspPrimary,
                  disabledBackgroundColor: kInspPrimary.withValues(alpha: 0.35),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: inspInterStyle(15, FontWeight.w600, Colors.white),
                ),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Design tokens (from 03_ui_system.md – LightModeTheme) ──────────────────
const Color _kPrimaryText = Color(0xFF1D354F);
const Color _kSecText     = Color(0xFF57636C);
const Color _kBorder      = Color(0xFFE0E3E7);
const Color _kFormField   = Color(0xFFEFF3FA);
const Color _kPrimary     = Color(0xFF27AAE2);
const Color _kError       = Color(0xFFFF3333);

TextStyle _inter(double size, FontWeight weight, Color color) =>
    GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: 0.0,
    );

// ─── ConfirmQuitInspectionDialog ─────────────────────────────────────────────
//
// Reusable confirmation dialog shown when a user attempts to exit an
// in-progress inspection. Requires the user to type "confirm" (case-insensitive)
// before the Quit action becomes available.
//
// Accepts a [themeColor] and [icon] so the same component can be reused for
// other destructive confirmations with a different colour scheme.
//
// Usage — static helper (recommended):
//   final quit = await ConfirmQuitInspectionDialog.show(context);
//   if (quit) { /* handle exit */ }
//
// Usage — manual showDialog:
//   showDialog(
//     context: context,
//     barrierDismissible: false,
//     builder: (_) => ConfirmQuitInspectionDialog(
//       onCancel:  () => Navigator.of(context).pop(),
//       onConfirm: () { Navigator.of(context).pop(); /* cleanup */ },
//     ),
//   );

class ConfirmQuitInspectionDialog extends StatefulWidget {
  /// Accent colour applied to the icon, Cancel button border/text, and
  /// the active Quit button background. Defaults to error red.
  final Color themeColor;

  /// Icon displayed at the top of the dialog. Defaults to a warning icon.
  final IconData icon;

  /// Called when the user taps Cancel. The caller dismisses the dialog.
  final VoidCallback onCancel;

  /// Called when the user has typed "Confirm" and taps Quit. The caller
  /// dismisses the dialog and handles cleanup.
  final VoidCallback onConfirm;

  const ConfirmQuitInspectionDialog({
    super.key,
    this.themeColor = _kError,
    this.icon = Icons.warning_amber_rounded,
    required this.onCancel,
    required this.onConfirm,
  });

  /// Convenience helper — shows the dialog and returns [true] if the user
  /// confirmed the quit, or [false] if they cancelled or dismissed.
  static Future<bool> show(
    BuildContext context, {
    Color themeColor = _kError,
    IconData icon = Icons.warning_amber_rounded,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => ConfirmQuitInspectionDialog(
        themeColor: themeColor,
        icon: icon,
        onCancel:  () => Navigator.of(dialogCtx).pop(false),
        onConfirm: () => Navigator.of(dialogCtx).pop(true),
      ),
    );
    return result ?? false;
  }

  @override
  State<ConfirmQuitInspectionDialog> createState() =>
      _ConfirmQuitInspectionDialogState();
}

class _ConfirmQuitInspectionDialogState
    extends State<ConfirmQuitInspectionDialog> {
  final TextEditingController _ctrl = TextEditingController();
  bool _canQuit = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onTextChanged);
    _ctrl.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    // Case-insensitive: "confirm", "Confirm", "CONFIRM" all accepted.
    final valid = _ctrl.text.trim().toLowerCase() == 'confirm';
    if (valid != _canQuit) setState(() => _canQuit = valid);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.themeColor;

    // Card matches the existing dialog pattern: white, radius 16, padding 20.
    // Same dimensions as CustomConfirmDialogWidget and CustomMessageDialogWidget.
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: Container(
        width: 285,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Icon ──────────────────────────────────────────────────────
            Icon(widget.icon, color: color, size: 64),

            // ── Title ─────────────────────────────────────────────────────
            const SizedBox(height: 20),
            Text(
              'Are you sure you want to quit inspection?',
              textAlign: TextAlign.center,
              style: _inter(18, FontWeight.w700, _kPrimaryText),
            ),

            // ── Message ───────────────────────────────────────────────────
            const SizedBox(height: 12),
            Text(
              'You will lose all your inspection progress.\nType "Confirm" to proceed.',
              textAlign: TextAlign.center,
              style: _inter(15, FontWeight.w400, _kSecText),
            ),

            // ── Confirmation input ─────────────────────────────────────────
            const SizedBox(height: 16),
            TextField(
              controller: _ctrl,
              textCapitalization: TextCapitalization.sentences,
              autofocus: true,
              style: _inter(14, FontWeight.w400, _kPrimaryText),
              decoration: InputDecoration(
                hintText: 'Type "Confirm"',
                hintStyle: _inter(14, FontWeight.w400, _kSecText),
                filled: true,
                fillColor: _kFormField,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _kBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _kBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _kPrimary, width: 1.5),
                ),
              ),
            ),

            // ── Buttons ───────────────────────────────────────────────────
            const SizedBox(height: 20),
            Row(
              children: [
                // Cancel — outlined in theme color, always enabled
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: widget.onCancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: color,
                        side: BorderSide(color: color, width: 1.5),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: _inter(15, FontWeight.w600, color),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Quit — filled in theme color, enabled only after valid input
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _canQuit ? widget.onConfirm : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        disabledBackgroundColor:
                            color.withValues(alpha: 0.35),
                        foregroundColor: Colors.white,
                        disabledForegroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle:
                            _inter(15, FontWeight.w600, Colors.white),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text('Quit'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

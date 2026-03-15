import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Design tokens (matches ConfirmQuitInspectionDialog) ─────────────────────
const Color _kPrimaryText = Color(0xFF1D354F);
const Color _kSecText     = Color(0xFF57636C);
const Color _kPrimary     = Color(0xFF27AAE2);

TextStyle _inter(double size, FontWeight weight, Color color) =>
    GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: 0.0,
    );

// ─── ConfirmActionDialog ─────────────────────────────────────────────────────
//
// A lightweight confirmation dialog with the same visual style as
// ConfirmQuitInspectionDialog but without the "type confirm" text field.
// Cancel + Confirm buttons are always enabled.
//
// Usage:
//   final confirmed = await ConfirmActionDialog.show(
//     context,
//     icon: Icons.file_copy_outlined,
//     title: 'Use this form?',
//     message: 'This will add a copy to your organization.',
//     confirmLabel: 'Use Form',
//   );
//   if (confirmed) { /* proceed */ }

class ConfirmActionDialog extends StatelessWidget {
  final Color themeColor;
  final IconData icon;
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const ConfirmActionDialog({
    super.key,
    this.themeColor = _kPrimary,
    required this.icon,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    required this.onCancel,
    required this.onConfirm,
  });

  /// Shows the dialog and returns `true` if confirmed, `false` otherwise.
  static Future<bool> show(
    BuildContext context, {
    Color themeColor = _kPrimary,
    IconData icon = Icons.info_outline_rounded,
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => ConfirmActionDialog(
        themeColor: themeColor,
        icon: icon,
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        onCancel: () => Navigator.of(dialogCtx).pop(false),
        onConfirm: () => Navigator.of(dialogCtx).pop(true),
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
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
            Icon(icon, color: themeColor, size: 64),

            // ── Title ─────────────────────────────────────────────────────
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: _inter(18, FontWeight.w700, _kPrimaryText),
            ),

            // ── Message ───────────────────────────────────────────────────
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: _inter(15, FontWeight.w400, _kSecText),
            ),

            // ── Buttons ───────────────────────────────────────────────────
            const SizedBox(height: 20),
            Row(
              children: [
                // Cancel — outlined
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: onCancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: themeColor,
                        side: BorderSide(color: themeColor, width: 1.5),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle:
                            _inter(15, FontWeight.w600, themeColor),
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(cancelLabel),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Confirm — filled
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle:
                            _inter(15, FontWeight.w600, Colors.white),
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(confirmLabel),
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

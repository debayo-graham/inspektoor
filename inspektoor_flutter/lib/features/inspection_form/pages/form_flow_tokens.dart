import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const Color kFormBlue    = Color(0xFF0EA5E9); // sky-500
const Color kFormBlueDk  = Color(0xFF0284C7); // sky-600
const Color kFormGreen   = Color(0xFF10B981); // emerald-500
const Color kFormGreenDk = Color(0xFF059669); // emerald-600
const Color kFormAmber   = Color(0xFFF59E0B); // amber-500
const Color kFormSlate8  = Color(0xFF1E293B); // slate-800
const Color kFormSlate7  = Color(0xFF334155); // slate-700
const Color kFormSlate6  = Color(0xFF475569); // slate-600
const Color kFormSlate5  = Color(0xFF64748B); // slate-500
const Color kFormSlate4  = Color(0xFF94A3B8); // slate-400
const Color kFormBorder  = Color(0xFFE2E8F0); // slate-200
const Color kFormBg      = Color(0xFFF1F5F9); // slate-100
const Color kFormSurface = Color(0xFFF8FAFC); // slate-50

// ── Typography ────────────────────────────────────────────────────────────────
TextStyle ffStyle(double size, FontWeight weight, Color color) =>
    GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: 0.0,
    );

// ── Shared back button ────────────────────────────────────────────────────────
class FormFlowBackButton extends StatelessWidget {
  final VoidCallback? onTap;
  const FormFlowBackButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => Navigator.of(context).pop(),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: kFormBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.chevron_left_rounded,
          color: kFormSlate6,
          size: 24,
        ),
      ),
    );
  }
}

// ── Category icon helper ──────────────────────────────────────────────────────
IconData categoryIcon(String? category) {
  switch ((category ?? '').toLowerCase()) {
    case 'vehicles':
    case 'semi truck':
    case 'truck':
      return Icons.local_shipping_outlined;
    case 'warehouse':
    case 'forklift':
      return Icons.warehouse_outlined;
    case 'safety':
      return Icons.health_and_safety_outlined;
    case 'facility':
    case 'hvac':
      return Icons.apartment_outlined;
    case 'electrical':
    case 'generator':
      return Icons.bolt_outlined;
    case 'construction':
      return Icons.construction_outlined;
    default:
      return Icons.assignment_outlined;
  }
}

// ── Relative time helper ──────────────────────────────────────────────────────
String relativeTime(String? isoDate) {
  if (isoDate == null) return '';
  try {
    final dt = DateTime.parse(isoDate).toLocal();
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 30) {
      final months = (diff.inDays / 30).floor();
      return '$months month${months == 1 ? '' : 's'} ago';
    }
    if (diff.inDays >= 7) {
      final weeks = (diff.inDays / 7).floor();
      return '$weeks week${weeks == 1 ? '' : 's'} ago';
    }
    if (diff.inDays >= 1) {
      return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    }
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    return 'Just now';
  } catch (_) {
    return '';
  }
}

// ── Item type helpers ─────────────────────────────────────────────────────────
IconData itemTypeIcon(String? type) {
  switch (type) {
    case 'numeric':
      return Icons.tag_rounded;
    case 'alphanumeric':
      return Icons.text_fields_rounded;
    case 'comment-box':
      return Icons.chat_bubble_outline_rounded;
    case 'multi-check':
      return Icons.checklist_rounded;
    case 'single-check':
      return Icons.check_circle_outline_rounded;
    case 'photo':
      return Icons.photo_camera_outlined;
    case 'signature':
      return Icons.draw_outlined;
    case 'multiple-choice':
      return Icons.radio_button_checked_rounded;
    default:
      return Icons.edit_note_rounded;
  }
}

String itemTypeLabel(String? type) {
  switch (type) {
    case 'numeric':
      return 'Numeric';
    case 'alphanumeric':
      return 'Alphanum.';
    case 'comment-box':
      return 'Comment';
    case 'multi-check':
      return 'Multi-check';
    case 'single-check':
      return 'Single Check';
    case 'photo':
      return 'Photo';
    case 'signature':
      return 'Signature';
    case 'multiple-choice':
      return 'Multi-choice';
    default:
      return type ?? '';
  }
}

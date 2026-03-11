import 'package:flutter/material.dart';

// ─── StatusBanner ─────────────────────────────────────────────────────────────
//
// Reusable status banner with an icon circle on the left and title + subtitle
// on the right. Two named constructors cover the most common variants:
//
//   StatusBanner.success(title: ..., subtitle: ...)
//   StatusBanner.warning(title: ..., subtitle: ...)
//
// For full customisation, use the default constructor.

class StatusBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  /// Background decoration for the outer container.
  final BoxDecoration decoration;

  /// Decoration for the leading icon circle.
  final BoxDecoration iconDecoration;

  /// Text style for the title.
  final TextStyle titleStyle;

  /// Text style for the subtitle.
  final TextStyle subtitleStyle;

  /// Icon size inside the circle. Defaults to 20.
  final double iconSize;

  /// Icon circle diameter. Defaults to 40.
  final double iconCircleSize;

  const StatusBanner({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.decoration,
    required this.iconDecoration,
    required this.titleStyle,
    required this.subtitleStyle,
    this.iconSize = 20,
    this.iconCircleSize = 40,
  });

  /// Green success banner (gradient background, green icon circle).
  factory StatusBanner.success({
    Key? key,
    required String title,
    required String subtitle,
    required TextStyle Function(double size, FontWeight weight, Color color)
        textStyleBuilder,
  }) {
    const passFill = Color(0xFF16A34A);
    const passBorder = Color(0xFFBBF7D0);
    return StatusBanner(
      key: key,
      icon: Icons.check_rounded,
      title: title,
      subtitle: subtitle,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: passBorder, width: 1.5),
      ),
      iconDecoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: passFill.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      titleStyle: textStyleBuilder(13, FontWeight.w800, const Color(0xFF065F46)),
      subtitleStyle:
          textStyleBuilder(12, FontWeight.w400, const Color(0xFF059669)),
    );
  }

  /// Amber warning banner (solid background, amber icon circle).
  factory StatusBanner.warning({
    Key? key,
    required String title,
    required String subtitle,
    required TextStyle Function(double size, FontWeight weight, Color color)
        textStyleBuilder,
  }) {
    const warning = Color(0xFFF59E0B);
    const warningBg = Color(0xFFFFFBEB);
    const warningBorder = Color(0xFFFDE68A);
    return StatusBanner(
      key: key,
      icon: Icons.warning_amber_rounded,
      title: title,
      subtitle: subtitle,
      decoration: BoxDecoration(
        color: warningBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: warningBorder, width: 1.5),
      ),
      iconDecoration: const BoxDecoration(
        color: warning,
        shape: BoxShape.circle,
      ),
      titleStyle:
          textStyleBuilder(13, FontWeight.w800, const Color(0xFF92400E)),
      subtitleStyle:
          textStyleBuilder(12, FontWeight.w400, const Color(0xFFB45309)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: decoration,
      child: Row(
        children: [
          Container(
            width: iconCircleSize,
            height: iconCircleSize,
            decoration: iconDecoration,
            child: Icon(icon, color: Colors.white, size: iconSize),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: titleStyle),
                const SizedBox(height: 2),
                Text(subtitle, style: subtitleStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

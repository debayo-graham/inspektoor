import 'package:flutter/material.dart';

import '../inspection_tokens.dart';

class InspectionPillButton extends StatelessWidget {
  final String label;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final VoidCallback? onTap;
  final bool outlined;

  const InspectionPillButton({
    super.key,
    required this.label,
    this.leadingIcon,
    this.trailingIcon,
    required this.onTap,
    required this.outlined,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );

    final children = <Widget>[
      if (leadingIcon != null) ...[
        Icon(leadingIcon, size: 16),
        const SizedBox(width: 6),
      ],
      Text(label),
      if (trailingIcon != null) ...[
        const SizedBox(width: 6),
        Icon(trailingIcon, size: 16),
      ],
    ];

    if (outlined) {
      return OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: kInspPrimaryText,
          side: const BorderSide(color: kInspBorder, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: shape,
          textStyle: inspInterStyle(14, FontWeight.w600, kInspPrimaryText),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: children,
        ),
      );
    }

    return Container(
      decoration: onTap != null
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: kInspPrimary.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            )
          : null,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: kInspPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: shape,
          textStyle: inspInterStyle(14, FontWeight.w600, Colors.white),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: children,
        ),
      ),
    );
  }
}

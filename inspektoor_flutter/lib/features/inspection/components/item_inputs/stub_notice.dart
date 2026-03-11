import 'package:flutter/material.dart';

import '../../inspection_tokens.dart';

class InspectionStubNotice extends StatelessWidget {
  final IconData icon;
  final String message;

  const InspectionStubNotice({
    super.key,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kInspFormField,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kInspBorder),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: kInspSecText.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: inspInterStyle(13, FontWeight.w400, kInspSecText),
          ),
        ],
      ),
    );
  }
}

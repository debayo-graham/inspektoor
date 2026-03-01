import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../inspection_tokens.dart';

class InspectionTextEntry extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final String? suffix;
  final int maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? formatters;

  const InspectionTextEntry({
    super.key,
    required this.controller,
    required this.placeholder,
    this.suffix,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
    this.formatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      style: inspInterStyle(15, FontWeight.w400, kInspPrimaryText),
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: inspInterStyle(15, FontWeight.w400, kInspSecText),
        suffixText: suffix,
        suffixStyle: inspInterStyle(14, FontWeight.w500, kInspSecText),
        filled: true,
        fillColor: kInspFormField,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kInspBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kInspBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kInspPrimary, width: 1.5),
        ),
      ),
    );
  }
}

// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

class DynamicText extends StatefulWidget {
  const DynamicText({
    super.key,
    this.width,
    this.height,
    required this.text,
    required this.condition,
    this.trueWeight = 700,
    this.falseWeight = 400,
    this.fontSize = 16,
    this.color,
    this.textAlign = 'start',
    this.maxLines,
  });

  final double? width;
  final double? height;
  final String text;
  final bool condition;
  final int? trueWeight;
  final int? falseWeight;
  final double? fontSize;
  final Color? color;
  final String? textAlign; // 'start' | 'center' | 'end' | 'justify'
  final int? maxLines;

  FontWeight _mapToFontWeight(int? w) {
    if (w == null) return FontWeight.w400; // fallback if null

    if (w <= 100) return FontWeight.w100;
    if (w <= 200) return FontWeight.w200;
    if (w <= 300) return FontWeight.w300;
    if (w <= 400) return FontWeight.w400;
    if (w <= 500) return FontWeight.w500;
    if (w <= 600) return FontWeight.w600;
    if (w <= 700) return FontWeight.w700;
    if (w <= 800) return FontWeight.w800;
    return FontWeight.w900;
  }

  TextAlign _mapToAlign(String s) {
    switch (s) {
      case 'center':
        return TextAlign.center;
      case 'end':
        return TextAlign.end;
      case 'justify':
        return TextAlign.justify;
      case 'start':
      default:
        return TextAlign.start;
    }
  }

  @override
  State<DynamicText> createState() => _DynamicTextState();
}

class _DynamicTextState extends State<DynamicText> {
  @override
  Widget build(BuildContext context) {
    final weight = widget._mapToFontWeight(
      widget.condition ? widget.trueWeight : widget.falseWeight,
    );

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Text(
        widget.text,
        maxLines: widget.maxLines,
        overflow: widget.maxLines == null
            ? TextOverflow.visible
            : TextOverflow.ellipsis,
        textAlign: widget._mapToAlign(widget.textAlign ?? 'start'),
        style: TextStyle(
          fontSize: widget.fontSize,
          fontWeight: weight,
          color: widget.color ?? FlutterFlowTheme.of(context).primaryText,
        ),
      ),
    );
  }
}

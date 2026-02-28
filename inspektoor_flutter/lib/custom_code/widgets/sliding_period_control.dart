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

import 'package:flutter/cupertino.dart';

import 'package:flutter/cupertino.dart';

class SlidingPeriodControl extends StatefulWidget {
  const SlidingPeriodControl({
    super.key,
    this.width,
    this.height,
    this.trackColor,
    this.thumbColor,
    this.textColor,
    this.selectedTextColor,
    this.labels, // optional: 4 labels
    this.onChanged, // no-arg Action; read AppState in your flow
  });

  final double? width;
  final double? height;
  final Color? trackColor;
  final Color? thumbColor;
  final Color? textColor;
  final Color? selectedTextColor;
  final List<String>? labels;
  final Future<dynamic> Function()? onChanged;

  @override
  State<SlidingPeriodControl> createState() => _SlidingPeriodControlState();
}

class _SlidingPeriodControlState extends State<SlidingPeriodControl> {
  static const List<String> _defaultLabels = [
    'Today',
    'Week',
    'Month',
    'Custom'
  ];
  late int _groupValue;

  @override
  void initState() {
    super.initState();
    _groupValue = FFAppState().periodIndex;
  }

  // Turn a label into a stable key like "today", "last_7_days", etc.
  String _keyFromLabel(String label) {
    final lower = label.trim().toLowerCase();
    final spacesToUnderscore = lower.replaceAll(RegExp(r'\s+'), '_');
    final alnumOnly = spacesToUnderscore.replaceAll(RegExp(r'[^a-z0-9_]+'), '');
    return alnumOnly;
  }

  @override
  Widget build(BuildContext context) {
    final labels = (widget.labels != null && widget.labels!.length == 4)
        ? widget.labels!
        : _defaultLabels;

    final track = widget.trackColor ?? const Color(0xFFE6F4FF);
    final thumb = widget.thumbColor ?? const Color(0xFF1FA7FF);
    final text = widget.textColor ?? const Color(0xFF0B6AA8);
    final textSel = widget.selectedTextColor ?? Colors.white;

    final h =
        (widget.height == null || widget.height == 0) ? 44.0 : widget.height!;

    return SizedBox(
      width: widget.width,
      height: h,
      child: CupertinoSlidingSegmentedControl<int>(
        groupValue: _groupValue,
        backgroundColor: track,
        thumbColor: thumb,
        padding: const EdgeInsets.all(4),
        children: {
          for (var i = 0; i < 4; i++)
            i: Center(
              child: DefaultTextStyle(
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontWeight: FontWeight.w600,
                      color: (_groupValue == i) ? textSel : text,
                    ),
                child: Text(labels[i]),
              ),
            ),
        },
        onValueChanged: (int? newValue) async {
          if (newValue == null) return;
          setState(() {
            _groupValue = newValue;
            FFAppState().periodIndex = newValue;
            FFAppState().periodKey = _keyFromLabel(labels[newValue]);
          });

          print("SlidingPeriodControl -> index: $newValue");
          print("SlidingPeriodControl -> text: ${labels[newValue]}");
          print("SlidingPeriodControl -> periodKey: ${FFAppState().periodKey}");

          // Fire your fetch flow
          if (widget.onChanged != null) {
            await widget.onChanged!();
          }
        },
      ),
    );
  }
}

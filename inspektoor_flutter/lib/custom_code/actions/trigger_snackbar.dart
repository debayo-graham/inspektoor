// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

Future triggerSnackbar(
  String message,
  int? durationMs,
  Color? background,
  Color? textColor,
) async {
  FFAppState().update(() {
    FFAppState().snackbarMessage = message;
    FFAppState().snackbarDurationMs = durationMs ?? 2500;
    FFAppState().snackbarBg = background ?? Colors.black87;
    FFAppState().snackbarText = textColor ?? Colors.white;

    // Trigger must be updated inside update()
    FFAppState().snackbarTrigger++;
  });
}

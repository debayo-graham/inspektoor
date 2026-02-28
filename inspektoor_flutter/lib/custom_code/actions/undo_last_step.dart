// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:convert';

Future<void> undoLastStep() async {
  try {
    if (FFAppState().inspectionDraftJson.isEmpty) return;

    final draft = json.decode(FFAppState().inspectionDraftJson);

    if (draft['items'] is List && draft['items'].isNotEmpty) {
      draft['items'].removeLast();
    }

    FFAppState().inspectionDraftJson = json.encode(draft);
  } catch (e, st) {
    debugPrint("ERROR in undoLastStep: $e");
    debugPrint("$st");
    // We do not rethrow here—undo should fail silently
  }
}

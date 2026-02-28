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

Future<void> updateInspectionDraftGPS(
  double lat,
  double lng,
) async {
  try {
    // Ensure draft exists
    if (FFAppState().inspectionDraftJson.isEmpty) {
      throw Exception(
          "Inspection draft does not exist. You must call initInspectionDraft() first.");
    }

    // Decode existing draft JSON
    final draft = json.decode(FFAppState().inspectionDraftJson);

    // Add or update GPS
    draft["gps"] = {
      "lat": lat,
      "lng": lng,
    };

    // Save back to AppState
    FFAppState().inspectionDraftJson = json.encode(draft);
  } catch (e, st) {
    debugPrint("ERROR in updateInspectionDraftGPS: $e");
    debugPrint("$st");
    rethrow;
  }
}

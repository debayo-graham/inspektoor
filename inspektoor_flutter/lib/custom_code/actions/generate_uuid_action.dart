// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:uuid/uuid.dart';

Future<String> generateUuidAction() async {
  try {
    final uuid = const Uuid().v4();
    return uuid;
  } catch (e) {
    // Fallback if uuid package is unavailable for any reason
    return 'id_${DateTime.now().microsecondsSinceEpoch}';
  }
}

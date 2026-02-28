// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

/// our code works with a list so unwrap it
Future<List<dynamic>> unwrapSchema(dynamic schema) async {
  if (schema.containsKey('items') && schema['items'] is List) {
    return List<dynamic>.from(schema['items']);
  }
  return [];
}

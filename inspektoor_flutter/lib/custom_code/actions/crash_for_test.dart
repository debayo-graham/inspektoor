// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!

Future<void> crashForTest(
  String? message,
  String? tag,
) async {
  // Keep it simple: throw an exception so global handlers catch it
  final msg =
      message?.trim().isNotEmpty == true ? message!.trim() : 'Test edge log';
  final suffix = (tag?.trim().isNotEmpty == true) ? ' [$tag]' : '';
  throw Exception('$msg$suffix');
}

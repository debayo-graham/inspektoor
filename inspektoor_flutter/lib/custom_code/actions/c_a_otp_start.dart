// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

Future<dynamic> cAOtpStart() async {
  final supa = SupaFlow.client;

  // No payload needed
  final resp = await supa.functions.invoke('otp-start');

  // Build a Map safely from whatever the function returned
  Map<String, dynamic> toMap(dynamic d) {
    if (d is Map) return Map<String, dynamic>.from(d);
    if (d == null) return <String, dynamic>{};
    return <String, dynamic>{'raw': d.toString()};
  }

  final body = toMap(resp.data);
  final ok = resp.status >= 200 && resp.status < 300;

  if (!ok) {
    final msg =
        (body['error'] ?? body['message'] ?? 'Unknown error').toString();
    // Always return a Map (no throws / no null) so FF can read it
    return {
      'ok': false,
      'status': resp.status,
      'message': msg,
      ...body,
    };
  }

  // Success shape: { challenge_id, expires_at }
  return {
    'ok': true,
    ...body, // includes challenge_id, expires_at
  };
}

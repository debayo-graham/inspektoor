// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

Future<bool> cAOtpVerify(String challengeId, String code) async {
  try {
    final supa = SupaFlow.client;
    final resp = await supa.functions.invoke(
      'otp-verify',
      body: {'challenge_id': challengeId, 'code': code},
    );
    // 2xx => true, everything else => false
    return resp.status >= 200 && resp.status < 300;
  } catch (e) {
    return false;
  }
}
